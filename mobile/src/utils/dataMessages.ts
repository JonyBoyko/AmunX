export function encodeMessage(text: string): Uint8Array {
  const encoded = encodeURIComponent(text);
  const bytes: number[] = [];
  for (let i = 0; i < encoded.length; i++) {
    const char = encoded[i];
    if (char === '%') {
      bytes.push(parseInt(encoded.slice(i + 1, i + 3), 16));
      i += 2;
    } else {
      bytes.push(char.charCodeAt(0));
    }
  }
  return Uint8Array.from(bytes);
}

export function decodeMessage(payload: Uint8Array): string {
  if (!payload || payload.length === 0) {
    return '';
  }
  const hex = Array.from(payload)
    .map((b) => `%${b.toString(16).padStart(2, '0')}`)
    .join('');
  try {
    return decodeURIComponent(hex);
  } catch {
    return '';
  }
}
