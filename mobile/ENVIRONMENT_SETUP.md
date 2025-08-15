# 🌍 Environment Configuration Guide

## 🚀 Quick Setup

**To change your API environment, edit this file:**
```dart
// mobile/lib/config/app_config.dart
static const String _currentEnvironment = 'local'; // ← Change this line
```

## 📱 Available Environments

| Environment | API URL | Use Case |
|-------------|---------|----------|
| `'local'` | `http://localhost:8000` | **Your local development** |
| `'dev'` | `http://dev-api.yourcompany.com` | Development server |
| `'staging'` | `http://staging-api.yourcompany.com` | Staging/testing |
| `'prod'` | `https://api.yourcompany.com` | Production |

## 🔄 How to Switch

### Option 1: Quick Change (Recommended)
1. Open `mobile/lib/config/app_config.dart`
2. Change line 4: `_currentEnvironment = 'local'` → `_currentEnvironment = 'dev'`
3. Save the file
4. Hot reload your Flutter app

### Option 2: Add Custom URLs
1. Open `mobile/lib/config/app_config.dart`
2. Add your custom URL to the `_apiUrls` map:
```dart
static const Map<String, String> _apiUrls = {
  'local': 'http://localhost:8000',
  'custom': 'http://192.168.1.100:8000', // ← Add your custom URL
  'dev': 'http://dev-api.yourcompany.com',
  // ... other environments
};
```
3. Set `_currentEnvironment = 'custom'`

## 🎯 Current Configuration

Your app will automatically use the configured API URL. No need to change multiple files!

## 🔍 Debug Information

To see your current configuration, add this to your app:
```dart
print(AppConfig.configInfo);
```

## 📝 Example Usage

```dart
// This will automatically use the correct API URL
final response = await http.get(Uri.parse('${AppConstants.authEndpoint}/login'));

// Check current environment
if (AppConfig.isLocal) {
  print('Running on local environment');
}
```

## 🚨 Important Notes

- **No restart required** - Just hot reload after changing the config
- **Automatic fallback** - If your custom URL fails, it falls back to local
- **Platform aware** - Works on Web, Android, and iOS
- **Easy to maintain** - All configuration in one place
