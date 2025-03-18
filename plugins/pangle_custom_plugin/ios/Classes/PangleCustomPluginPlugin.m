#import "PangleCustomPluginPlugin.h"
#if __has_include(<pangle_custom_plugin/pangle_custom_plugin-Swift.h>)
#import <pangle_custom_plugin/pangle_custom_plugin-Swift.h>
#else
#import "pangle_custom_plugin-Swift.h"
#endif

@implementation PangleCustomPluginPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPangleCustomPluginPlugin registerWithRegistrar:registrar];
}
@end 