#ifdef __cplusplus
#endif

#ifdef RCT_NEW_ARCH_ENABLED
#import <RNKeysSpec/RNKeysSpec.h>
#import <ReactCommon/RCTTurboModuleWithJSIBindings.h>

@interface Keys : NSObject <NativeKeysSpec, RCTTurboModuleWithJSIBindings>
#else
#import <React/RCTBridgeModule.h>

@interface Keys : NSObject <RCTBridgeModule>
#endif

+ (NSString *)secureFor:(NSString *)key;
+ (NSDictionary *)public_keys;
+ (NSString *)publicFor:(NSString *)key;

@end
