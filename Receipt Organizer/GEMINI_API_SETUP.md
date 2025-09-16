## Gemini API Configuration Guide

### Current Issue: Quota Exceeded (Rate Limit: 0 requests/minute)

Your Google Cloud project (939128185854) has exceeded the quota for Gemini API requests. The quota limit is currently set to **0 requests per minute** in the europe-west1 region.

**Error Details:**
- HTTP Status: 429 (Too Many Requests)
- Error Code: RATE_LIMIT_EXCEEDED
- Quota Metric: `Generate Content API requests per minute`
- Quota Limit: `GenerateContentRequestsPerMinutePerProjectPerRegion`
- Current Limit: **0 requests/minute**
- Region: `europe-west1`

### Solutions (in order of recommendation):

#### 1. 🆕 Create New API Key (Recommended)
- Visit [Google AI Studio](https://aistudio.google.com/)
- Create a new project or use a different Google account
- Generate a new API key
- Replace the current key in `GeminiService.swift`

#### 2. 💳 Enable Billing (If using Google Cloud Console)
- Go to [Google Cloud Console](https://console.cloud.google.com/)
- Select project 939128185854
- Navigate to **Billing** → **Account Management**
- Enable billing and add a payment method
- Go to **APIs & Services** → **Quotas**
- Search for "Gemini" or "GenerateContent"
- Request quota increase

#### 3. 📈 Request Quota Increase
- Visit [Quota Increase Request](https://cloud.google.com/docs/quotas/help/request_increase)
- Request increase for:
  - Service: `generativelanguage.googleapis.com`
  - Quota: `GenerateContent request limit per minute`
  - Region: `europe-west1` (or global)

#### 4. ⏰ Wait and Retry
- Rate limits may reset after some time
- Monitor your usage in the Google Cloud Console

### API Key Security Best Practices:

**⚠️ SECURITY WARNING**: Your API key is currently hardcoded in the source code. Consider:

1. **Environment Variables**: Store the key in environment variables
2. **Configuration File**: Use a local config file (add to .gitignore)
3. **iOS Keychain**: Store sensitive data in iOS Keychain
4. **Server-side Proxy**: Implement a backend service to handle API calls

### Testing Your Configuration:

Run the diagnostics in your app to verify the fix:
```swift
let service = GeminiService()
await service.runDiagnostics()
```

### Error Handling:

The app now includes better error handling for:
- ✅ Quota exceeded errors (429)
- ✅ Invalid API key errors (401)
- ✅ Access denied errors (403)
- ✅ Network connectivity issues

### New Security Implementation:

I've updated your project with better API key management:

1. **APIConfiguration.swift**: Centralized API configuration
2. **APIKeys.plist**: Template for secure key storage (add your key here)
3. **.gitignore**: Updated to exclude sensitive files
4. **Enhanced Error Handling**: Better quota error detection and user guidance

### Setup Instructions:

1. **Update APIKeys.plist**:
   - Open `Receipt Organizer/APIKeys.plist`
   - Replace `YOUR_API_KEY_HERE` with your new API key
   - This file is now excluded from git commits

2. **Get New API Key**:
   - Visit [Google AI Studio](https://aistudio.google.com/)
   - Create a new project or use different account
   - Generate API key and add to APIKeys.plist

3. **Test Configuration**:
   ```swift
   let service = GeminiService()
   await service.runDiagnostics()
   ```

### Monitoring Usage:

- Monitor your API usage at [Google AI Studio](https://aistudio.google.com/) or [Google Cloud Console](https://console.cloud.google.com/)
- Set up billing alerts to avoid unexpected charges
- Implement rate limiting in your app for production use
- The app now includes automatic retry logic for temporary quota issues

### Files Modified:

- ✅ `GeminiService.swift` - Enhanced error handling
- ✅ `APIConfiguration.swift` - New configuration management
- ✅ `APIKeys.plist` - Secure key storage template
- ✅ `.gitignore` - Excludes sensitive files
- ✅ `GEMINI_API_SETUP.md` - This guide