#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'pangle_custom_plugin'
  s.version          = '0.0.1'
  s.summary          = 'Flutter용 Pangle 광고 커스텀 플러그인'
  s.description      = <<-DESC
Flutter 앱에서 Pangle SDK를 쉽게 통합할 수 있는 커스텀 플러그인입니다.
                       DESC
  s.homepage         = 'https://github.com/your-username/pangle_custom_plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Ads-Global'
  s.platform = :ios, '13.0'

  # 필요한 시스템 프레임워크와 라이브러리 추가
  s.frameworks = 'UIKit', 'Foundation', 'CoreTelephony', 'SystemConfiguration', 'CoreLocation', 'Security', 'StoreKit', 'AdSupport', 'WebKit'
  s.libraries = 'z', 'sqlite3', 'bz2', 'resolv', 'c++', 'xml2'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  
  # 디버그 빌드에 대한 설정 추가
  s.user_target_xcconfig = { 'OTHER_LDFLAGS' => '-ObjC' }
  s.static_framework = true
end