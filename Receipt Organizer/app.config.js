export default {
  expo: {
    name: 'Receipt Organizer Pro',
    slug: 'receipt-organizer-pro',
    version: '1.0.0',
    orientation: 'portrait',
    icon: './assets/images/icon.png',
    scheme: 'receipt-organizer',
    userInterfaceStyle: 'automatic',
    newArchEnabled: true,
    splash: {
      image: './assets/images/splash-icon.png',
      resizeMode: 'contain',
      backgroundColor: '#ffffff',
    },
    extra: {
      geminiApiKey: process.env.EXPO_PUBLIC_GEMINI_API_KEY,
    },
    ios: {
      supportsTablet: true,
      bundleIdentifier: 'com.receiptorganizer.app',
      buildNumber: '1',
      infoPlist: {
        NSCameraUsageDescription: 'This app uses the camera to scan receipts for automated data extraction.',
        NSMicrophoneUsageDescription: 'This app may use the microphone during receipt capture.',
        NSPhotoLibraryUsageDescription: 'This app accesses your photo library to select receipt images for analysis.',
      },
    },
    android: {
      adaptiveIcon: {
        foregroundImage: './assets/images/adaptive-icon.png',
        backgroundColor: '#ffffff',
      },
      package: 'com.receiptorganizer.app',
      versionCode: 1,
      permissions: [
        'READ_EXTERNAL_STORAGE',
        'WRITE_EXTERNAL_STORAGE',
        'INTERNET',
        'CAMERA',
        'RECORD_AUDIO',
        'android.permission.VIBRATE',
      ],
    },
    web: {
      favicon: './assets/images/favicon.png',
    },
    plugins: [
      [
        'expo-router',
        {
          origin: 'https://receiptorganizer.app/',
        },
      ],
      [
        'expo-camera',
        {
          cameraPermission: 'This app uses the camera to scan receipts for automated data extraction.',
          microphonePermission: 'This app may use the microphone during receipt capture.',
          recordAudioAndroid: true,
        },
      ],
      [
        'expo-image-picker',
        {
          photosPermission: 'This app accesses your photo library to select receipt images for analysis.',
        },
      ],
    ],
    experiments: {
      typedRoutes: true,
    },
  },
};
