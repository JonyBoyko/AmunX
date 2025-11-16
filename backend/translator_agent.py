#!/usr/bin/env python3
"""
LiveKit Translator Agent for AmunX
Real-time ASR → MT → TTS pipeline with <2-3s e2e latency
"""

import os
import asyncio
import json
from typing import Dict, List
import httpx

from livekit import agents, rtc
from livekit.agents import AutoSubscribe, JobContext, WorkerOptions, cli
from livekit.agents.stt import STT, SpeechEvent, SpeechEventType
from livekit.agents.tts import TTS

# Configuration from ENV
ASR_PROVIDER = os.getenv("ASR_PROVIDER", "azure")  # azure|google|deepgram
MT_PROVIDER = os.getenv("MT_PROVIDER", "azure")    # azure|gcp|openai
TTS_PROVIDER = os.getenv("TTS_PROVIDER", "azure")  # azure|elevenlabs
API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8080")
SOURCE_LANG = os.getenv("SOURCE_LANG", "uk-UA")
TARGET_LANGS = os.getenv("TARGET_LANGS", "en,pl").split(",")
TRANSLATE_MIN_LISTENERS = int(os.getenv("TRANSLATE_MIN_LISTENERS", "1"))
BUDGET_MAX_COST_PER_HOUR_USD = float(os.getenv("BUDGET_MAX_COST_PER_HOUR_USD", "5.0"))

# Voice mapping for TTS
VOICE_MAP = {
    "en": "en-US-JennyNeural",
    "pl": "pl-PL-ZofiaNeural",
    "uk": "uk-UA-PolinaNeural",
}

class TranslatorAgent:
    def __init__(self, ctx: JobContext):
        self.ctx = ctx
        self.room: rtc.Room = None
        self.stt: STT = None
        self.tts_engines: Dict[str, TTS] = {}
        self.dub_tracks: Dict[str, rtc.AudioSource] = {}
        self.session_id: str = None
        self.translation_enabled = False
        self.target_langs: List[str] = []
        self.cost_usd = 0.0

    async def setup_providers(self):
        """Initialize ASR, MT, TTS providers"""
        if ASR_PROVIDER == "azure":
            from livekit.plugins.azure import STT as AzureSTT
            self.stt = AzureSTT(
                language=SOURCE_LANG,
                speech_key=os.getenv("AZURE_STT_KEY"),
                speech_region=os.getenv("AZURE_REGION"),
            )
        elif ASR_PROVIDER == "deepgram":
            from livekit.plugins.deepgram import STT as DeepgramSTT
            self.stt = DeepgramSTT(
                language=SOURCE_LANG[:2],  # "uk"
                api_key=os.getenv("DEEPGRAM_API_KEY"),
            )

        if TTS_PROVIDER == "azure":
            from livekit.plugins.azure import TTS as AzureTTS
            for lang in TARGET_LANGS:
                self.tts_engines[lang] = AzureTTS(
                    voice=VOICE_MAP.get(lang, "en-US-JennyNeural"),
                    speech_key=os.getenv("AZURE_TTS_KEY"),
                    speech_region=os.getenv("AZURE_REGION"),
                )
        elif TTS_PROVIDER == "elevenlabs":
            from livekit.plugins.elevenlabs import TTS as ElevenLabsTTS
            for lang in TARGET_LANGS:
                self.tts_engines[lang] = ElevenLabsTTS(
                    voice_id="21m00Tcm4TlvDq8ikWAM",  # Rachel
                    api_key=os.getenv("ELEVENLABS_API_KEY"),
                )

    async def check_translation_config(self):
        """Poll API for translation config"""
        if not self.session_id:
            return

        try:
            async with httpx.AsyncClient() as client:
                resp = await client.get(
                    f"{API_BASE_URL}/v1/live/sessions/{self.session_id}/translate/status",
                    timeout=5.0,
                )
                if resp.status_code == 200:
                    data = resp.json()
                    self.translation_enabled = data.get("enabled", False)
                    self.target_langs = data.get("target_langs", TARGET_LANGS)
                    print(f"Translation config: enabled={self.translation_enabled}, langs={self.target_langs}")
        except Exception as e:
            print(f"Failed to fetch translation config: {e}")

    async def translate_text(self, text: str, target_lang: str) -> str:
        """Translate text using configured MT provider"""
        if MT_PROVIDER == "azure":
            return await self.translate_azure(text, target_lang)
        elif MT_PROVIDER == "openai":
            return await self.translate_openai(text, target_lang)
        return text  # Fallback: no translation

    async def translate_azure(self, text: str, target_lang: str) -> str:
        """Azure Cognitive Services Translator"""
        try:
            async with httpx.AsyncClient() as client:
                endpoint = "https://api.cognitive.microsofttranslator.com/translate"
                params = {
                    "api-version": "3.0",
                    "from": SOURCE_LANG[:2],  # "uk"
                    "to": target_lang,
                }
                headers = {
                    "Ocp-Apim-Subscription-Key": os.getenv("AZURE_TRANSLATOR_KEY"),
                    "Ocp-Apim-Subscription-Region": os.getenv("AZURE_REGION"),
                    "Content-Type": "application/json",
                }
                body = [{"text": text}]
                resp = await client.post(endpoint, params=params, headers=headers, json=body, timeout=2.0)
                if resp.status_code == 200:
                    result = resp.json()
                    return result[0]["translations"][0]["text"]
        except Exception as e:
            print(f"Translation error: {e}")
        return text

    async def translate_openai(self, text: str, target_lang: str) -> str:
        """OpenAI GPT-4 for translation"""
        try:
            async with httpx.AsyncClient() as client:
                resp = await client.post(
                    "https://api.openai.com/v1/chat/completions",
                    headers={"Authorization": f"Bearer {os.getenv('OPENAI_API_KEY')}"},
                    json={
                        "model": "gpt-4o-mini",
                        "messages": [
                            {"role": "system", "content": f"Translate to {target_lang}. Output only translation."},
                            {"role": "user", "content": text},
                        ],
                        "max_tokens": 200,
                        "temperature": 0.3,
                    },
                    timeout=3.0,
                )
                if resp.status_code == 200:
                    return resp.json()["choices"][0]["message"]["content"]
        except Exception as e:
            print(f"OpenAI translation error: {e}")
        return text

    async def send_captions(self, text: str, lang: str, is_final: bool):
        """Send captions as data packets (low latency)"""
        if not self.room:
            return

        caption_type = "captions.final" if is_final else "captions.partial"
        payload = json.dumps({
            "type": caption_type,
            "lang": lang,
            "text": text,
        }).encode("utf-8")

        await self.room.local_participant.publish_data(
            payload,
            reliable=False,  # UDP for low latency
            destination_identities=None,  # Broadcast to all
        )

    async def publish_dub_audio(self, audio_data: bytes, lang: str):
        """Publish TTS audio as separate track (dub-{lang})"""
        if lang not in self.dub_tracks:
            # Create audio source and track
            source = rtc.AudioSource(24000, 1)  # 24kHz mono
            track = rtc.LocalAudioTrack.create_audio_track(f"dub-{lang}", source)
            options = rtc.TrackPublishOptions(source=rtc.TrackSource.SOURCE_MICROPHONE)
            await self.room.local_participant.publish_track(track, options)
            self.dub_tracks[lang] = source

        # Push audio frames
        source = self.dub_tracks[lang]
        await source.capture_frame(
            rtc.AudioFrame(audio_data, 24000, 1, len(audio_data) // 2)
        )

    async def process_host_track(self, track: rtc.RemoteAudioTrack):
        """Main processing loop: ASR → MT → Captions + TTS"""
        print(f"Processing host audio track: {track.sid}")

        # Stream ASR
        stream = self.stt.stream()
        audio_stream = rtc.AudioStream(track)

        async for event in stream:
            if event.type == SpeechEventType.INTERIM_TRANSCRIPT:
                text = event.alternatives[0].text
                # Send partial captions (original language)
                await self.send_captions(text, SOURCE_LANG[:2], is_final=False)

                # Translate and send partial captions for target langs (if enabled)
                if self.translation_enabled:
                    for lang in self.target_langs:
                        translated = await self.translate_text(text, lang)
                        await self.send_captions(translated, lang, is_final=False)

            elif event.type == SpeechEventType.FINAL_TRANSCRIPT:
                text = event.alternatives[0].text
                print(f"Final transcript: {text}")

                # Send final captions (original)
                await self.send_captions(text, SOURCE_LANG[:2], is_final=True)

                # Translate and synthesize dub tracks
                if self.translation_enabled:
                    for lang in self.target_langs:
                        translated = await self.translate_text(text, lang)
                        await self.send_captions(translated, lang, is_final=True)

                        # TTS for dub track
                        try:
                            tts = self.tts_engines.get(lang)
                            if tts:
                                async for audio_chunk in tts.synthesize(translated):
                                    await self.publish_dub_audio(audio_chunk.data, lang)
                                    self.cost_usd += 0.002  # Approx $2/1M chars
                        except Exception as e:
                            print(f"TTS error for {lang}: {e}")

                # Budget guard
                if self.cost_usd > BUDGET_MAX_COST_PER_HOUR_USD:
                    print(f"⚠️ Budget exceeded: ${self.cost_usd:.2f}")
                    self.translation_enabled = False
                    await self.room.local_participant.publish_data(
                        json.dumps({"type": "translate.guard", "reason": "budget"}).encode("utf-8"),
                        reliable=True,
                    )

async def entrypoint(ctx: JobContext):
    """Main agent entrypoint"""
    print(f"Agent starting for room: {ctx.room.name}")

    agent = TranslatorAgent(ctx)
    agent.session_id = ctx.room.name.replace("amunx_", "")

    # Connect to room
    agent.room = await ctx.connect(auto_subscribe=AutoSubscribe.SUBSCRIBE_ALL)
    print(f"Connected to room: {agent.room.name}")

    # Setup ASR/TTS providers
    await agent.setup_providers()

    # Check translation config from API
    await agent.check_translation_config()

    # Poll config every 10s
    async def poll_config():
        while True:
            await asyncio.sleep(10)
            await agent.check_translation_config()

    asyncio.create_task(poll_config())

    # Find host track
    @agent.room.on("track_subscribed")
    def on_track_subscribed(track: rtc.Track, publication: rtc.TrackPublication, participant: rtc.RemoteParticipant):
        if isinstance(track, rtc.RemoteAudioTrack) and publication.source == rtc.TrackSource.SOURCE_MICROPHONE:
            if participant.identity.startswith("host_"):
                print(f"Host track found: {track.sid}")
                asyncio.create_task(agent.process_host_track(track))

    # Wait indefinitely
    await asyncio.Future()

if __name__ == "__main__":
    cli.run_app(WorkerOptions(entrypoint_fnc=entrypoint))








