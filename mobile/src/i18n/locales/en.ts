export default {
  translation: {
    // Common
    common: {
      ok: 'OK',
      cancel: 'Cancel',
      retry: 'Retry',
      close: 'Close',
      save: 'Save',
      delete: 'Delete',
      loading: 'Loading...',
      error: 'Error',
      success: 'Success',
    },

    // Feed Screen
    feed: {
      title: 'Feed',
      empty: {
        message: 'No episodes yet. Be the first to record a 1-minute voice note!',
        action: 'Record 1-min episode',
      },
      error: {
        message: 'Something went wrong. Please try again.',
      },
      loading: 'Loading feed...',
      loadingMore: 'Loading more...',
      endReached: 'You have reached the end!',
    },

    // Episode Card
    episode: {
      liveReplay: 'Live replay',
      published: 'Published',
      pending: 'Pending',
      mask: 'Mask',
      quality: 'Quality',
      duration: 'Duration',
      keywords: 'Keywords',
      like: 'Like',
      unlike: 'Unlike',
      open: 'Open',
      comments: 'Comments',
      reactions: 'Reactions',
    },

    // Mini Player
    player: {
      play: 'Play',
      pause: 'Pause',
      stop: 'Stop',
      unknown: 'Unknown Episode',
    },

    // Recorder Screen
    recorder: {
      title: 'Record',
      recording: 'Recording',
      maxDuration: '{{current}}s / {{max}}s',
      privacy: 'Privacy',
      public: 'Public',
      anonymous: 'Anonymous',
      mask: 'Voice Mask',
      maskNone: 'None',
      maskLight: 'Light',
      maskHeavy: 'Heavy',
      quality: 'Quality',
      qualityRaw: 'Raw',
      qualityClean: 'Clean',
      qualityStudio: 'Studio',
      instructions: {
        idle: 'Tap the microphone to start recording (max. 60 sec)',
        recording: 'Tap to stop recording',
      },
      uploading: 'Uploading...',
      uploadSuccess: 'Episode uploaded successfully!',
      uploadError: 'Failed to upload episode',
      permission: {
        title: 'Permission required',
        message: 'Microphone access is needed to record.',
      },
      undo: {
        title: 'Publishing...',
        message: 'Episode will go live in {{seconds}} s',
        action: 'Cancel',
      },
      published: {
        title: 'Published!',
        message: 'Your episode is now live.',
      },
      cancelled: {
        title: 'Cancelled',
        message: 'Episode deleted successfully.',
      },
    },

    // Paywall Screen
    paywall: {
      close: 'Close',
      title: 'Unlock Full Potential',
      subtitle: 'Get AI transcription, voice masking, and studio quality',
      features: {
        transcription: {
          title: 'Full Transcription',
          description: 'Faster-Whisper AI for 99% text accuracy',
        },
        summary: {
          title: 'AI TL;DR + Mood',
          description: 'Automatic summary and emotion detection',
        },
        maskPro: {
          title: 'Voice Mask Pro',
          description: 'Anonymity protection with heavy masking',
        },
        studio: {
          title: 'Studio Quality',
          description: 'Professional audio processing',
        },
        analytics: {
          title: 'Analytics',
          description: 'Detailed stats and insights',
        },
        priority: {
          title: 'Priority Processing',
          description: 'Faster episode publishing',
        },
      },
      pricing: {
        title: 'Choose Your Plan',
        monthly: {
          name: 'Monthly',
          price: '$4.99 / month',
        },
        yearly: {
          name: 'Year (Save 40%)',
          price: '$2.99 / month',
          subtitle: '$35.88 per year',
          badge: 'Best Value',
        },
      },
      cta: 'Subscribe Now',
      processing: 'Processing...',
      restore: 'Restore Purchases',
      finePrint: 'Subscription auto-renews. Cancel anytime.',
      legal: {
        terms: 'Terms',
        privacy: 'Privacy',
      },
      thankYou: {
        title: 'Thank You!',
        message: 'Subscription activated. Welcome to PRO! 🎉',
      },
      restoring: {
        title: 'Restoring Purchases',
        message: 'Checking your subscriptions...',
      },
    },

    // Settings Screen
    settings: {
      title: 'Settings',
      profile: {
        guest: 'Guest',
        upgrade: 'Upgrade',
      },
      account: {
        title: 'Account',
        profile: 'Profile',
        changeEmail: 'Change Email',
        manageSubscription: 'Manage Subscription',
        comingSoon: 'Coming soon!',
      },
      preferences: {
        title: 'Preferences',
        notifications: 'Notifications',
        autoplay: 'Autoplay',
        analytics: 'Analytics',
        language: 'Language',
      },
      support: {
        title: 'Support',
        help: 'Help',
        terms: 'Terms of Service',
        privacy: 'Privacy Policy',
      },
      dangerZone: {
        title: 'Danger Zone',
        logout: 'Logout',
        deleteAccount: 'Delete Account',
        logoutConfirm: {
          title: 'Logout',
          message: 'Are you sure you want to logout?',
        },
        deleteConfirm: {
          title: 'Delete Account?',
          message: 'This is irreversible. All your episodes will be deleted.',
        },
        deleted: {
          title: 'Account Deleted',
          message: 'Goodbye! 👋',
        },
      },
      appInfo: {
        version: 'AmunX v1.0.0 (Beta)',
        copyright: '© 2025 AmunX. All rights reserved.',
      },
      languages: {
        en: 'English',
        uk: 'Українська',
      },
    },

    // Auth Screen
    auth: {
      title: 'Welcome to AmunX',
      subtitle: 'Voice Journal & Live Audio',
      signIn: 'Sign In with Email',
      emailPlaceholder: 'Enter your email',
      sendMagicLink: 'Send Magic Link',
      checkEmail: 'Check your email for the magic link!',
      invalidEmail: 'Invalid email address',
      error: 'Failed to send magic link',
    },

    // Live
    live: {
      host: {
        title: 'Host Live',
        start: 'Start Live',
        end: 'End Live',
        viewers: {
          zero: 'No viewers',
          one: '{{count}} viewer',
          other: '{{count}} viewers',
        },
      },
      listener: {
        title: 'Join Live',
        join: 'Join',
        leave: 'Leave',
        noSessions: 'No live sessions available',
      },
    },

    // Badges
    badges: {
      public: 'PUBLIC',
      anon: 'ANONYMOUS',
      mask: 'MASK',
      pro: 'PRO',
      raw: 'RAW',
      clean: 'CLEAN',
      studio: 'STUDIO',
      live: 'LIVE',
    },

    // Error Messages
    errors: {
      network: 'Network error. Please check your connection.',
      unauthorized: 'Please sign in to continue.',
      notFound: 'Resource not found.',
      serverError: 'Server error. Please try again later.',
      unknown: 'An unknown error occurred.',
    },
  },
};

