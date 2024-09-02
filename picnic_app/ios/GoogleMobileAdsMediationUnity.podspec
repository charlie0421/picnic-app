# Pod::Spec.new do |s|
#   s.name         = 'GoogleMobileAdsMediationUnity'
#   s.version      = '4.10.0.0'
#   s.summary      = 'A short description of GoogleMobileAdsMediationUnity.'
#   s.description  = 'A longer description of GoogleMobileAdsMediationUnity.'
#   s.homepage     = 'https://example.com'
#   s.license      = { :type => 'MIT', :file => 'LICENSE' }
#   s.author       = { 'Author Name' => 'email@example.com' }
#   s.source       = { :git => 'https://example.com/GoogleMobileAdsMediationUnity.git', :tag => s.version.to_s }
#   s.source_files = 'GoogleMobileAdsMediationUnity/**/*.{h,m,mm,swift}'
#   s.requires_arc = true
#
#   # Add this line to ensure static linkage
#   s.pod_target_xcconfig = { 'LIBRARY_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/GoogleMobileAdsMediationUnity' }
# end
#

#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint gma_mediation_unity.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'GoogleMobileAdsMediationUnity'
  s.version          = '4.10.0.0'
  s.summary          = 'Unity adapter used for mediation with the Google Mobile Ads SDK'
  s.homepage         = 'https://developers.google.com/admob/ios/mediation/unity'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = 'Google LLC'
  s.source           = { :git => 'https://github.com/googleads/googleads-mobile-ios-mediation.git', :tag => 'unity-' + s.version.to_s }
  s.ios.deployment_target = '11.0'
  s.static_framework = true
  s.dependency 'UnityAds', '4.10.0'
  s.source_files = 'adapters/Unity/*.{h,m}'
  s.requires_arc = true
end