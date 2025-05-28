# WeChat Login Configuration Guide

## Overview

This guide provides comprehensive instructions for configuring WeChat login in your Flutter application using the `fluwx` package. WeChat login is essential for Chinese users and requires specific setup procedures for both iOS and Android platforms.

**Note:** The region-based login control specifically targets mainland China (CN) only. Hong Kong, Macau, and Taiwan are treated as "other" regions and will display all login options.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [WeChat Developer Account Setup](#wechat-developer-account-setup)
3. [Required Configuration Parameters](#required-configuration-parameters)
4. [iOS Configuration](#ios-configuration)
5. [Android Configuration](#android-configuration)
6. [Flutter Integration](#flutter-integration)
7. [Environment Configuration](#environment-configuration)
8. [Testing and Validation](#testing-and-validation)
9. [Troubleshooting](#troubleshooting)
10. [Security Best Practices](#security-best-practices)
11. [Configuration Checklist](#configuration-checklist)

## Prerequisites

Before starting the WeChat login configuration, ensure you have:

- [ ] A WeChat Developer Account (requires Chinese business registration)
- [ ] Access to WeChat Open Platform (open.weixin.qq.com)
- [ ] iOS Developer Account (for iOS app configuration)
- [ ] Android app signing certificate
- [ ] Flutter development environment set up
- [ ] `fluwx` package version 3.13.1 or later

## WeChat Developer Account Setup

### 1. Register WeChat Developer Account

1. Visit [WeChat Open Platform](https://open.weixin.qq.com/)
2. Click "注册" (Register) to create a new account
3. Complete the registration process with:
   - Valid Chinese business license
   - Company verification documents
   - Contact information
4. Wait for account verification (typically 1-3 business days)

### 2. Create Mobile Application

1. Log in to WeChat Open Platform
2. Navigate to "管理中心" (Management Center)
3. Click "创建移动应用" (Create Mobile Application)
4. Fill in application details:
   - App Name (Chinese and English)
   - App Description
   - App Category
   - App Icon (512x512 pixels)
   - Screenshots
5. Submit for review (approval takes 1-7 days)

## Required Configuration Parameters

### Core Parameters

| Parameter | Description | Example | Required |
|-----------|-------------|---------|----------|
| App ID | WeChat application identifier | `wxa5eea7ab9b3894a8` | ✅ |
| App Secret | WeChat application secret key | `your_app_secret_here` | ✅ |
| Universal Link | iOS deep linking URL | `https://applink.picnic.fan/wechat/` | ✅ (iOS) |
| Package Name | Android package identifier | `com.example.picnic` | ✅ (Android) |
| App Signature | Android app signing signature | `SHA1 fingerprint` | ✅ (Android) |

### Platform-Specific Parameters

#### iOS
- Bundle Identifier: Must match your iOS app bundle ID
- Universal Link: Must be configured in Apple Developer Console
- URL Schemes: `weixin{AppID}` and `weixinULAPI`

#### Android
- Package Name: Must match your Android app package name
- App Signature: SHA1 fingerprint of your signing certificate
- Activity Name: Main activity class name

## iOS Configuration

### 1. Configure Universal Links

1. **Apple Developer Console Setup:**
   ```
   1. Log in to Apple Developer Console
   2. Go to Certificates, Identifiers & Profiles
   3. Select your App ID
   4. Enable "Associated Domains" capability
   5. Add domain: applinks:applink.picnic.fan
   ```

2. **Server Configuration:**
   Create `apple-app-site-association` file on your server:
   ```json
   {
     "applinks": {
       "apps": [],
       "details": [
         {
           "appID": "TEAM_ID.com.example.picnic",
           "paths": ["/wechat/*"]
         }
       ]
     }
   }
   ```

### 2. Xcode Configuration

1. **Info.plist Configuration:**
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLName</key>
       <string>weixin</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>wxa5eea7ab9b3894a8</string>
       </array>
     </dict>
     <dict>
       <key>CFBundleURLName</key>
       <string>weixinULAPI</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>weixinULAPI</string>
       </array>
     </dict>
   </array>
   
   <key>LSApplicationQueriesSchemes</key>
   <array>
     <string>weixin</string>
     <string>weixinULAPI</string>
   </array>
   ```

2. **Associated Domains:**
   Add to your app's entitlements:
   ```
   applinks:applink.picnic.fan
   ```

### 3. WeChat Developer Console iOS Settings

1. Navigate to your app in WeChat Open Platform
2. Go to "开发信息" (Development Information)
3. Configure iOS settings:
   - Bundle ID: `com.example.picnic`
   - Universal Link: `https://applink.picnic.fan/wechat/`

## Android Configuration

### 1. Get App Signature

Generate SHA1 fingerprint of your signing certificate:

```bash
# For debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release keystore
keytool -list -v -keystore /path/to/your/keystore.jks -alias your_alias_name
```

### 2. AndroidManifest.xml Configuration

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
  <!-- WeChat Login Activity -->
  <activity
    android:name=".wxapi.WXEntryActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@android:style/Theme.Translucent.NoTitleBar" />
    
  <!-- WeChat App Query Permission -->
  <queries>
    <package android:name="com.tencent.mm" />
  </queries>
</application>
```

### 3. Create WXEntryActivity

Create `android/app/src/main/java/com/example/picnic/wxapi/WXEntryActivity.java`:

```java
package com.example.picnic.wxapi;

import com.jarvan.fluwx.wxapi.FluwxWXEntryActivity;

public class WXEntryActivity extends FluwxWXEntryActivity {
}
```

### 4. WeChat Developer Console Android Settings

1. Navigate to your app in WeChat Open Platform
2. Go to "开发信息" (Development Information)
3. Configure Android settings:
   - Package Name: `com.example.picnic`
   - App Signature: Your SHA1 fingerprint

## Flutter Integration

### 1. Add Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  fluwx: ^3.13.1
```

### 2. Initialize WeChat SDK

```dart
import 'package:fluwx/fluwx.dart';

class WeChatLogin {
  static const String appId = 'wxa5eea7ab9b3894a8';
  static const String universalLink = 'https://applink.picnic.fan/wechat/';

  Future<void> initialize() async {
    await registerWxApi(
      appId: appId,
      doOnAndroid: true,
      doOnIOS: true,
      universalLink: universalLink,
    );
  }

  Future<User?> login() async {
    try {
      // Check if WeChat is installed
      final isInstalled = await isWeChatInstalled;
      if (!isInstalled) {
        throw PicnicAuthException(
          code: 'wechat_not_installed',
          message: 'WeChat is not installed on this device',
        );
      }

      // Send authentication request
      await sendWeChatAuth(
        scope: 'snsapi_userinfo',
        state: 'wechat_login',
      );

      // Listen for response
      final response = await weChatResponseEventHandler.stream
          .where((response) => response is WeChatAuthResponse)
          .cast<WeChatAuthResponse>()
          .timeout(const Duration(seconds: 30))
          .first;

      if (response.isSuccessful) {
        // Exchange code for access token (server-side)
        return await _exchangeCodeForUser(response.code!);
      } else {
        throw PicnicAuthException(
          code: response.errorCode.toString(),
          message: 'WeChat login failed: ${response.errorCode}',
        );
      }
    } catch (e) {
      logger.e('WeChat login error: $e');
      rethrow;
    }
  }

  Future<User?> _exchangeCodeForUser(String code) async {
    // Implement server-side token exchange
    // This should call your backend API to exchange the code for user info
    // and create/authenticate the user in your system
    throw UnimplementedError('Server-side token exchange not implemented');
  }
}
```

## Environment Configuration

### 1. Configuration Files

Create environment-specific configuration files:

**config/dev.json:**
```json
{
  "wechat": {
    "app_id": "wxa5eea7ab9b3894a8",
    "app_secret": "your_dev_app_secret",
    "universal_link": "https://dev-applink.picnic.fan/wechat/"
  }
}
```

**config/prod.json:**
```json
{
  "wechat": {
    "app_id": "wxa5eea7ab9b3894a8",
    "app_secret": "your_prod_app_secret",
    "universal_link": "https://applink.picnic.fan/wechat/"
  }
}
```

### 2. Environment Loading

```dart
class Environment {
  static late Map<String, dynamic> _config;

  static Future<void> load(String environment) async {
    final configString = await rootBundle.loadString('config/$environment.json');
    _config = jsonDecode(configString);
  }

  static String get wechatAppId => _config['wechat']['app_id'];
  static String get wechatAppSecret => _config['wechat']['app_secret'];
  static String get wechatUniversalLink => _config['wechat']['universal_link'];
}
```

## Testing and Validation

### 1. Pre-Implementation Tests

- [ ] Verify WeChat app is installed on test devices
- [ ] Confirm App ID and App Secret are valid
- [ ] Test Universal Link configuration
- [ ] Validate Android app signature

### 2. Implementation Tests

- [ ] Test WeChat SDK initialization
- [ ] Verify authentication flow
- [ ] Test error handling scenarios
- [ ] Validate token exchange process

### 3. Platform-Specific Tests

**iOS:**
- [ ] Test on physical iOS device (WeChat doesn't work in simulator)
- [ ] Verify Universal Link handling
- [ ] Test app switching between WeChat and your app

**Android:**
- [ ] Test on physical Android device
- [ ] Verify WXEntryActivity is properly configured
- [ ] Test app switching between WeChat and your app

### 4. Region Simulation Testing (Debug Mode Only)

For testing region-based login options without changing your actual location, the app includes debug-only region simulation features:

#### Available Simulation Functions

```dart
// Simulate China mainland (shows only Apple + WeChat login)
await RegionDetectionService.simulateChina();

// Simulate other region like US (shows all login options)
await RegionDetectionService.simulateOtherRegion('US');

// Clear simulation and use real detection
await RegionDetectionService.clearSimulation();

// Set custom region
await RegionDetectionService.setDebugRegion('JP');
```

#### Debug UI Controls

In debug mode, the login screen displays region simulation controls:

- **CN Button (Red)**: Simulate China mainland region
- **US Button (Blue)**: Simulate US region  
- **Clear Button (Grey)**: Clear simulation and use real detection

#### Testing Scenarios

1. **Test China Region Behavior:**
   - Tap "CN" button in debug controls
   - Verify only Apple and WeChat login buttons appear
   - Test WeChat login flow

2. **Test Other Region Behavior:**
   - Tap "US" button in debug controls
   - Verify all login options (Google, Apple, Kakao, WeChat) appear
   - Test all login flows

3. **Test Real Detection:**
   - Tap "Clear" button to disable simulation
   - Verify app uses actual IP/locale-based detection

#### Important Notes

- Region simulation only works in **debug mode** (`kDebugMode = true`)
- Simulation settings persist across app restarts
- In release builds, all simulation functions are disabled
- Use VPN testing for additional validation of real region detection

## Troubleshooting

### Common Issues

#### 1. "WeChat not installed" Error
**Cause:** WeChat app is not installed on the device
**Solution:** 
- Install WeChat from App Store (iOS) or Google Play Store (Android)
- Use `isWeChatInstalled` to check before attempting login

#### 2. "Invalid App ID" Error
**Cause:** App ID doesn't match WeChat developer console configuration
**Solution:**
- Verify App ID in WeChat developer console
- Check configuration files for typos
- Ensure App ID matches exactly (case-sensitive)

#### 3. Universal Link Not Working (iOS)
**Cause:** Universal Link configuration issues
**Solution:**
- Verify `apple-app-site-association` file is accessible
- Check Associated Domains in Xcode
- Ensure Universal Link is configured in WeChat developer console

#### 4. Android App Signature Mismatch
**Cause:** SHA1 fingerprint doesn't match registered signature
**Solution:**
- Regenerate SHA1 fingerprint using correct keystore
- Update signature in WeChat developer console
- Ensure using same keystore for signing

### Error Codes

| Error Code | Description | Solution |
|------------|-------------|----------|
| -2 | User cancelled | Normal user behavior, no action needed |
| -3 | Send request failed | Check network connection and App ID |
| -4 | Auth denied | Check app permissions in WeChat |
| -5 | WeChat not supported | Update WeChat app version |

## Security Best Practices

### 1. App Secret Protection

- **Never include App Secret in client-side code**
- Store App Secret securely on your backend server
- Use environment variables for App Secret storage
- Implement proper access controls for App Secret

### 2. Token Handling

- Implement secure token storage using `flutter_secure_storage`
- Set appropriate token expiration times
- Implement token refresh mechanisms
- Clear tokens on logout

### 3. Data Privacy

- Comply with Chinese data protection regulations
- Implement proper user consent mechanisms
- Minimize data collection to necessary information only
- Provide clear privacy policy regarding WeChat data usage

### 4. Network Security

- Use HTTPS for all API communications
- Implement certificate pinning for critical endpoints
- Validate all server responses
- Implement proper error handling without exposing sensitive information

## Configuration Checklist

### Pre-Implementation

- [ ] WeChat Developer Account verified and approved
- [ ] Mobile application created and approved in WeChat Open Platform
- [ ] App ID and App Secret obtained
- [ ] iOS Bundle ID and Android Package Name registered
- [ ] Universal Link domain configured
- [ ] Android app signature generated and registered

### iOS Setup

- [ ] Universal Link configured in Apple Developer Console
- [ ] Associated Domains capability enabled
- [ ] Info.plist URL schemes configured
- [ ] `apple-app-site-association` file deployed
- [ ] WeChat developer console iOS settings updated

### Android Setup

- [ ] AndroidManifest.xml permissions added
- [ ] WXEntryActivity created and configured
- [ ] App signature registered in WeChat developer console
- [ ] Package name verified in WeChat developer console

### Flutter Integration

- [ ] `fluwx` package added to dependencies
- [ ] WeChat SDK initialization implemented
- [ ] Authentication flow implemented
- [ ] Error handling implemented
- [ ] Token storage implemented

### Testing

- [ ] WeChat installation check implemented
- [ ] Authentication flow tested on physical devices
- [ ] Error scenarios tested
- [ ] Token exchange with backend implemented
- [ ] User data retrieval tested

### Production Deployment

- [ ] Production App ID and App Secret configured
- [ ] Production Universal Link configured
- [ ] Production app signatures registered
- [ ] Security review completed
- [ ] Privacy policy updated
- [ ] User documentation created

## Additional Resources

- [WeChat Open Platform Documentation](https://developers.weixin.qq.com/doc/oplatform/en/Mobile_App/WeChat_Login/Development_Guide.html)
- [fluwx Package Documentation](https://pub.dev/packages/fluwx)
- [iOS Universal Links Guide](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
- [Android App Links Guide](https://developer.android.com/training/app-links)

## Support

For technical support regarding WeChat login implementation:

1. Check this documentation first
2. Review the troubleshooting section
3. Consult the fluwx package documentation
4. Contact the development team with specific error messages and logs

---

**Document Version:** 1.0  
**Last Updated:** 2024-01-XX  
**Maintained By:** Development Team 