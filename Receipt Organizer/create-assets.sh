#!/bin/bash

echo "Creating placeholder assets for Receipt Organizer..."

ASSETS_DIR="/Users/nicolaigosselin/Documents/Github/Persoonlijk/IOS/Receipt Organizer/assets/images"

# Create placeholder files (these will need to be replaced with real assets)
touch "$ASSETS_DIR/icon.png"
touch "$ASSETS_DIR/adaptive-icon.png"
touch "$ASSETS_DIR/splash-icon.png"
touch "$ASSETS_DIR/favicon.png"

echo "✅ Placeholder assets created"
echo "⚠️  Note: Replace these placeholder files with actual 1024x1024 PNG images"
echo ""
echo "Required asset dimensions:"
echo "• icon.png: 1024x1024 (app icon)"
echo "• adaptive-icon.png: 1024x1024 (Android adaptive icon)"
echo "• splash-icon.png: 1024x1024 (splash screen icon)"
echo "• favicon.png: 48x48 (web favicon)"
