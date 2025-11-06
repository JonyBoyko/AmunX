import { Linking } from 'react-native';
import { recordFeedEvent } from '../api/events';

// Deep link scheme: amunx://
// Universal links: https://amunx.app/

interface DeepLinkParams {
  type: 'audio' | 'circle';
  id: string;
  utm?: {
    source?: string;
    medium?: string;
    campaign?: string;
    content?: string;
  };
}

export const deepLinkScheme = 'amunx';
export const universalLinkDomain = 'https://amunx.app';

/**
 * Parse deep link URL
 */
export function parseDeepLink(url: string): DeepLinkParams | null {
  try {
    // Handle amunx:// scheme
    if (url.startsWith(`${deepLinkScheme}://`)) {
      const path = url.replace(`${deepLinkScheme}://`, '');
      const [type, id] = path.split('/');
      
      if ((type === 'audio' || type === 'circle') && id) {
        return { type, id };
      }
    }

    // Handle https://amunx.app/ universal links
    if (url.startsWith(universalLinkDomain)) {
      const urlObj = new URL(url);
      const path = urlObj.pathname;
      
      // /a/:slug for audio
      if (path.startsWith('/a/')) {
        const id = path.replace('/a/', '');
        const utm = {
          source: urlObj.searchParams.get('utm_source') || undefined,
          medium: urlObj.searchParams.get('utm_medium') || undefined,
          campaign: urlObj.searchParams.get('utm_campaign') || undefined,
          content: urlObj.searchParams.get('utm_content') || undefined,
        };
        
        return { type: 'audio', id, utm };
      }
      
      // /c/:slug for circle
      if (path.startsWith('/c/')) {
        const id = path.replace('/c/', '');
        const utm = {
          source: urlObj.searchParams.get('utm_source') || undefined,
          medium: urlObj.searchParams.get('utm_medium') || undefined,
          campaign: urlObj.searchParams.get('utm_campaign') || undefined,
          content: urlObj.searchParams.get('utm_content') || undefined,
        };
        
        return { type: 'circle', id, utm };
      }
    }

    return null;
  } catch (error) {
    console.error('Failed to parse deep link:', error);
    return null;
  }
}

/**
 * Handle deep link navigation
 */
export async function handleDeepLink(
  url: string,
  navigation: any
): Promise<void> {
  const params = parseDeepLink(url);
  
  if (!params) {
    console.warn('Invalid deep link:', url);
    return;
  }

  // Record deep link event
  if (params.utm) {
    // Store UTM for first-time attribution
    await storeUTM(params.utm);
  }

  // TODO: Record deeplink_open event
  // await recordFeedEvent({
  //   audio_id: params.type === 'audio' ? params.id : undefined,
  //   event: 'deeplink_open',
  //   meta: {
  //     type: params.type,
  //     id: params.id,
  //     ...params.utm,
  //   },
  // });

  // Navigate
  if (params.type === 'audio') {
    navigation.navigate('Player', {
      audioId: params.id,
    });
  } else if (params.type === 'circle') {
    navigation.navigate('CircleFeed', {
      circleId: params.id,
    });
  }
}

/**
 * Store UTM parameters for attribution
 */
async function storeUTM(utm: DeepLinkParams['utm']): Promise<void> {
  try {
    const existingUTM = await getStoredUTM();
    
    // Only store first UTM (first-touch attribution)
    if (!existingUTM && utm) {
      // TODO: Save to AsyncStorage or send to backend
      console.log('Storing UTM:', utm);
    }
  } catch (error) {
    console.error('Failed to store UTM:', error);
  }
}

/**
 * Get stored UTM parameters
 */
async function getStoredUTM(): Promise<DeepLinkParams['utm'] | null> {
  // TODO: Retrieve from AsyncStorage
  return null;
}

/**
 * Generate linkback URL with UTM
 */
export function generateLinkback(
  type: 'audio' | 'circle',
  id: string,
  platform: string = 'share',
  contentId?: string
): string {
  const baseUrl = `${universalLinkDomain}/${type === 'audio' ? 'a' : 'c'}/${id}`;
  const params = new URLSearchParams({
    utm_source: platform,
    utm_medium: 'short',
    utm_campaign: 'audiogram',
  });
  
  if (contentId) {
    params.append('utm_content', contentId);
  }
  
  return `${baseUrl}?${params.toString()}`;
}

/**
 * Initialize deep link listener
 */
export function initDeepLinks(navigation: any): () => void {
  // Handle initial URL (app opened from link)
  Linking.getInitialURL().then(url => {
    if (url) {
      handleDeepLink(url, navigation);
    }
  });

  // Handle incoming URLs (app is already open)
  const subscription = Linking.addEventListener('url', ({ url }) => {
    handleDeepLink(url, navigation);
  });

  // Return cleanup function
  return () => {
    subscription.remove();
  };
}

