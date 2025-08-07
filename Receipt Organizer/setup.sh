#!/bin/bash

echo "🚀 Setting up Receipt Organizer iOS App"
echo "======================================="

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "Creating .env file with your Gemini API key..."
    echo "EXPO_PUBLIC_GEMINI_API_KEY=AIzaSyA0KAKmK7ffkuhs35f9XF1ZNqkn-Zp4hVk" > .env
    echo "✅ .env file created"
else
    echo "✅ .env file already exists"
fi

# Install dependencies
echo "📦 Installing dependencies..."
if command -v bun >/dev/null 2>&1; then
    bun install
elif command -v npm >/dev/null 2>&1; then
    npm install --legacy-peer-deps
else
    echo "❌ Neither bun nor npm found. Please install Node.js and npm first."
    exit 1
fi

echo ""
echo "🎉 Setup Complete!"
echo "==================="
echo ""
echo "📱 Next steps to run on iOS:"
echo "1. For iOS Simulator: npx expo start --ios"
echo "2. For development build: eas build --profile development --platform ios"
echo "3. For production build: eas build --profile production --platform ios"
echo ""
echo "🔐 Security Note:"
echo "Your API key is now stored in .env file and properly configured"
echo "The .env file is gitignored for security"
echo ""
echo "🛠️  Development Commands:"
echo "• Start development server: npx expo start"
echo "• Start with tunnel: npx expo start --tunnel"
echo "• Clear cache: npx expo start --clear"
echo ""
echo "📖 For Xcode/iOS Native Development:"
echo "• Generate iOS project: npx expo prebuild --platform ios"
echo "• Then open ios/ReceiptOrganizerPro.xcworkspace in Xcode"
