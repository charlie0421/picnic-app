# WeChat Login Integration Guide

## 📋 Overview

This document provides comprehensive guidance for the WeChat login integration in the Picnic app. WeChat login enables Chinese users to authenticate using their WeChat accounts, providing a seamless social login experience.

## 🏗️ Architecture Overview

### Components Structure
```
picnic_app/
├── config/
│   ├── dev.json          # WeChat configuration (dev)
│   ├── local.json        # WeChat configuration (local)
│   └── prod.json         # WeChat configuration (prod)
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml  # WeChat permissions & activities
└── ios/
    └── Runner/
        └── Info.plist    # WeChat URL schemes

picnic_lib/
├── lib/core/
│   ├── config/
│   │   └── environment.dart      # WeChat config getters
│   ├── services/
│   │   ├── auth/
│   │   │   ├── auth_service.dart # Main auth service
│   │   │   └── social_login/
│   │   │       └── wechat_login.dart # WeChat login implementation
│   │   └── wechat_token_storage_service.dart # Secure token storage
│   └── utils/
│       └── china_network_simulator.dart # China environment testing
├── data/models/
│   └── wechat_token_info.dart    # WeChat token model
└── test/
    └── wechat_china_test.dart     # China environment tests
```

## 🔧 Installation & Configuration

### 1. Dependencies

**picnic_app/pubspec.yaml:**
```yaml
dependencies:
  fluwx: ^3.13.1  # WeChat SDK for Flutter
```

**picnic_lib/pubspec.yaml:**
```yaml
dependencies:
  fluwx: ^3.13.1
  flutter_secure_storage: ^9.2.2
  freezed_annotation: ^2.4.4
```

### 2. WeChat App Configuration

#### Android Setup

**android/app/src/main/AndroidManifest.xml:**
```xml
<!-- WeChat app query permission -->
<queries>
    <package android:name="com.tencent.mm" />
</queries>

<!-- WeChat callback activity -->
<activity
    android:name=".wxapi.WXEntryActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@android:style/Theme.Translucent.NoTitleBar" />
```

#### iOS Setup

**ios/Runner/Info.plist:**
```xml
<!-- WeChat URL schemes -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>weixin</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>weixin</string>
            <string>weixinULAPI</string>
            <string>wxa5eea7ab9b3894a8</string> <!-- Your WeChat App ID -->
        </array>
    </dict>
</array>

<!-- WeChat app query -->
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>weixin</string>
    <string>weixinULAPI</string>
</array>
```

### 3. Environment Configuration

**config/dev.json:**
```json
{
  "wechat": {
    "app_id": "wxa5eea7ab9b3894a8",
    "app_secret": "your_app_secret_here",
    "universal_link": "https://applink.picnic.fan/wechat/"
  }
}
```

**picnic_lib/lib/core/config/environment.dart:**
```dart
class Environment {
  // WeChat configuration getters
  static String get wechatAppId => _config['wechat']['app_id'];
  static String get wechatAppSecret => _config['wechat']['app_secret'];
  static String get wechatUniversalLink => _config['wechat']['universal_link'];
}
```

## 🔐 Security Implementation

### Token Storage

WeChat tokens are securely stored using `FlutterSecureStorage`:

```dart
class WeChatTokenStorageService {
  final FlutterSecureStorage _storage;
  
  // Encrypted storage of WeChat tokens
  Future<void> saveWeChatToken(WeChatTokenInfo tokenInfo) async {
    final tokenJson = tokenInfo.toJson();
    await _storage.write(
      key: _wechatTokenKey,
      value: jsonEncode(tokenJson),
    );
  }
}
```

### Security Features

- ✅ **Encrypted Storage**: All tokens stored using FlutterSecureStorage
- ✅ **Token Expiration**: Automatic token expiry checking and cleanup
- ✅ **Server-Side Exchange**: App secret kept on server, not in client
- ✅ **Error Cleanup**: Automatic token deletion on errors
- ✅ **Secure Transmission**: HTTPS for all API communications

## 🚀 Usage Guide

### Basic WeChat Login

```dart
// Initialize WeChat login service
final wechatLogin = WeChatLogin();

// Perform login
try {
  final result = await wechatLogin.login();
  
  if (result.isSuccess) {
    // Login successful
    final user = result.user;
    print('WeChat login successful: ${user.nickname}');
  } else {
    // Handle login failure
    print('WeChat login failed: ${result.error}');
  }
} catch (e) {
  // Handle exceptions
  print('WeChat login error: $e');
}
```

### Integration with AuthService

```dart
// WeChat login through main auth service
final authService = AuthService();

try {
  final user = await authService.signInWithWeChat();
  print('User authenticated: ${user.id}');
} catch (e) {
  print('Authentication failed: $e');
}
```

### Token Management

```dart
// Check if user has valid WeChat token
final hasValidToken = await authService.hasValidWeChatToken();

// Get WeChat user info
final userInfo = await authService.getWeChatUserInfo();

// Refresh WeChat token
await authService.refreshWeChatToken();

// Logout and clear tokens
await authService.signOutWeChat();
```

## 🧪 Testing

### Unit Tests

Run WeChat-specific tests:
```bash
cd picnic_lib
flutter test test/wechat_china_test.dart
```

### China Environment Testing

Enable China network simulation for testing:

```dart
// Enable China network simulation
ChinaNetworkSimulator.enable(simulateGfw: true);

// Test WeChat connectivity
final isConnected = await ChinaNetworkSimulator.testWeChatConnectivity();

// Generate test report
final report = ChinaNetworkSimulator.generateTestReport();
```

### Test Coverage

- ✅ Network simulation (delays, packet loss, GFW blocking)
- ✅ Chinese device characteristics simulation
- ✅ WeChat connectivity testing
- ✅ Token storage with Chinese characters
- ✅ Performance under China network conditions
- ✅ Error handling and recovery

## 🌏 China-Specific Considerations

### Network Conditions

The implementation includes China network simulation for testing:

- **Network Latency**: 200ms - 2000ms typical delays
- **Packet Loss**: 5% average packet loss simulation
- **Connection Failures**: 10% connection failure rate
- **GFW Simulation**: Blocks Google, Facebook, Twitter (allows WeChat)

### Device Support

Tested device characteristics:
- **Huawei**: P50 Pro (HarmonyOS, no Google services)
- **Xiaomi**: Mi 13 (MIUI 14, with Google services)
- **Oppo**: Find X6 (ColorOS 13, with Google services)
- **Vivo**: X90 Pro (OriginOS 3, with Google services)
- **Apple**: iPhone 14 Pro (iOS 16, Apple services)

### Chinese Character Support

Full support for Chinese characters in:
- User nicknames (测试用户, 张三, 李四, etc.)
- Location information (Beijing, Shanghai, etc.)
- Error messages and UI text

## 🔧 Troubleshooting

### Common Issues

#### 1. WeChat App Not Installed
```dart
// Check if WeChat is installed
final isInstalled = await isWeChatInstalled;
if (!isInstalled) {
  // Show error message or redirect to WeChat download
  throw PicnicAuthExceptions.wechatNotInstalled();
}
```

#### 2. Network Connectivity Issues
```dart
// Test WeChat connectivity before login
if (ChinaNetworkSimulator.isEnabled) {
  final isConnected = await ChinaNetworkSimulator.testWeChatConnectivity();
  if (!isConnected) {
    throw PicnicAuthExceptions.networkError();
  }
}
```

#### 3. Token Expiration
```dart
// Check token validity
final tokenInfo = await _tokenStorage.getWeChatToken();
if (tokenInfo?.isExpired == true) {
  // Refresh token or re-authenticate
  await _tokenStorage.clearWeChatToken();
  return await login(); // Re-login
}
```

#### 4. Configuration Issues
```dart
// Validate WeChat configuration
if (Environment.wechatAppId.isEmpty) {
  throw PicnicAuthExceptions.configurationError('WeChat App ID not configured');
}
```

### Debug Logging

Enable debug logging for WeChat operations:

```dart
// Enable debug logging
logger.d('WeChat login initiated');
logger.d('WeChat App ID: ${Environment.wechatAppId}');
logger.d('WeChat Universal Link: ${Environment.wechatUniversalLink}');
```

### Error Codes

| Error Code | Description | Solution |
|------------|-------------|----------|
| `WECHAT_NOT_INSTALLED` | WeChat app not found | Install WeChat app |
| `WECHAT_AUTH_CANCELLED` | User cancelled login | Retry or show message |
| `WECHAT_AUTH_DENIED` | User denied permission | Show permission explanation |
| `WECHAT_NETWORK_ERROR` | Network connectivity issue | Check internet connection |
| `WECHAT_TOKEN_EXPIRED` | Access token expired | Refresh token or re-login |
| `WECHAT_CONFIG_ERROR` | Configuration missing | Check app ID and secret |

## 📊 Performance Metrics

### Expected Performance

- **Login Time**: 2-5 seconds (normal network)
- **China Network**: 3-8 seconds (with simulation)
- **Token Storage**: <100ms (local storage)
- **Token Validation**: <200ms (local check)

### Monitoring

Monitor these metrics in production:

```dart
// Performance tracking
final stopwatch = Stopwatch()..start();
final result = await wechatLogin.login();
stopwatch.stop();

logger.i('WeChat login took: ${stopwatch.elapsedMilliseconds}ms');

// Report to analytics
Analytics.track('wechat_login_performance', {
  'duration_ms': stopwatch.elapsedMilliseconds,
  'success': result.isSuccess,
  'network_type': await getNetworkType(),
});
```

## 🔄 Server Integration

### Token Exchange Endpoint

Implement server-side token exchange for security:

```dart
// Client sends auth code to server
final response = await http.post(
  Uri.parse('${Environment.apiBaseUrl}/auth/wechat/exchange'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'code': authCode,
    'state': state,
  }),
);

// Server exchanges code for access token using app secret
// Server returns Supabase session token
```

### API Endpoints

Required server endpoints:

- `POST /auth/wechat/exchange` - Exchange auth code for tokens
- `POST /auth/wechat/refresh` - Refresh access token
- `GET /auth/wechat/userinfo` - Get user information
- `POST /auth/wechat/logout` - Logout and invalidate tokens

## 📚 Additional Resources

### WeChat Developer Documentation
- [WeChat Open Platform](https://developers.weixin.qq.com/doc/)
- [WeChat Login Guide](https://developers.weixin.qq.com/doc/oplatform/Mobile_App/WeChat_Login/Development_Guide.html)

### Flutter WeChat SDK
- [fluwx Package](https://pub.dev/packages/fluwx)
- [fluwx GitHub](https://github.com/OpenFlutter/fluwx)

### Testing Resources
- [China Network Testing Guide](./china_network_testing.md)
- [WeChat API Testing](./wechat_api_testing.md)

## 🔄 Maintenance

### Regular Tasks

1. **Token Cleanup**: Regularly clean expired tokens
2. **Performance Monitoring**: Track login success rates and timing
3. **Error Monitoring**: Monitor and alert on authentication failures
4. **Configuration Updates**: Keep WeChat app credentials updated
5. **SDK Updates**: Keep fluwx package updated

### Version Compatibility

| fluwx Version | WeChat SDK | Supported Features |
|---------------|------------|-------------------|
| 3.13.1 | 1.9.6 | Login, User Info, Sharing |
| 5.5.x | 2.0.x | Enhanced APIs, Better Error Handling |

## 📞 Support

For WeChat integration issues:

1. Check this documentation first
2. Review error logs and debug output
3. Test with China network simulation
4. Verify WeChat app configuration
5. Contact development team with specific error details

---

**Last Updated**: 2025-05-28  
**Version**: 1.0.0  
**Maintainer**: Development Team 