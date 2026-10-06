#import "Keys.h"
#import <React/RCTUtils.h>
#import <jsi/jsi.h>
#import <sys/utsname.h>
#import "YeetJSIUtils.h"
#ifdef RCT_NEW_ARCH_ENABLED
#import <ReactCommon/RCTTurboModuleWithJSIBindings.h>
#import <ReactCommon/CallInvoker.h>
#else
#import <React/RCTBridge+Private.h>
#endif

#import "crypto.h"
#import "GeneratedDotEnv.m"
#import "privateKey.m"

using namespace facebook::jsi;
using namespace std;

static void installKeysBindings(Runtime &runtime)
{
    auto secureFor = Function::createFromHostFunction(runtime,
                                                    PropNameID::forAscii(runtime,
                                                                         "secureFor"),
                                                    1,
                                                      [](Runtime &runtime,
                                                             const Value &thisValue,
                                                             const Value *arguments,
                                                             size_t count) -> Value {
        if (count < 1 || !arguments[0].isString()) {
            throw JSError(runtime, "secureFor expects a string key");
        }
        NSString *key = convertJSIStringToNSString(runtime, arguments[0].getString(runtime));
        NSString *value = [Keys secureFor:key];
        return Value(runtime, convertNSStringToJSIString(runtime, value));
    });

    runtime.global().setProperty(runtime, "secureFor", std::move(secureFor));

    auto publicKeys = Function::createFromHostFunction(runtime,
                                                    PropNameID::forAscii(runtime,
                                                                         "publicKeys"),
                                                    0,
                                                      [](Runtime &runtime,
                                                             const Value &thisValue,
                                                             const Value *arguments,
                                                             size_t count) -> Value {
        NSDictionary *s = [Keys public_keys];
        return Value(runtime, convertNSDictionaryToJSIObject(runtime, s));
    });

    runtime.global().setProperty(runtime, "publicKeys", std::move(publicKeys));
}

@implementation Keys

#ifndef RCT_NEW_ARCH_ENABLED
@synthesize bridge = _bridge;
#endif
@synthesize methodQueue = _methodQueue;

RCT_EXPORT_MODULE()

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

#ifdef RCT_NEW_ARCH_ENABLED
// New architecture: React Native hands us the runtime when the TurboModule is
// created. RCTCxxBridge no longer exists in bridgeless mode (RN 0.82+).
// RN 0.77+ calls this variant (and 0.87+ only this one).
- (void)installJSIBindingsWithRuntime:(facebook::jsi::Runtime &)runtime
                          callInvoker:(const std::shared_ptr<facebook::react::CallInvoker> &)callInvoker
{
    installKeysBindings(runtime);
}

// RN 0.75 and 0.76 only know this variant.
- (void)installJSIBindingsWithRuntime:(facebook::jsi::Runtime &)runtime
{
    installKeysBindings(runtime);
}

RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(install)
{
    return @true;
}
#else
// Old architecture: grab the runtime from the C++ bridge.
RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(install)
{
    RCTBridge* bridge = [RCTBridge currentBridge];
    RCTCxxBridge* cxxBridge = (RCTCxxBridge*)bridge;
    if (cxxBridge == nil) {
        return @false;
    }

    auto jsiRuntime = (jsi::Runtime*) cxxBridge.runtime;
    if (jsiRuntime == nil) {
        return @false;
    }

    installKeysBindings(*jsiRuntime);
    return @true;
}
#endif


+ (NSString *)secureFor: (NSString *)key {
      @try {
          NSDictionary *privatesKeyEnv = PRIVATE_KEY;
          NSString *privateKey = [privatesKeyEnv objectForKey:@"privateKey"];
           NSString* stringfyData = [NSString stringWithCString:Crypto().getJniJsonStringifyData([privateKey cStringUsingEncoding:NSUTF8StringEncoding]).c_str() encoding:NSUTF8StringEncoding];
           NSData *data = [stringfyData dataUsingEncoding:NSUTF8StringEncoding];
           NSMutableDictionary *s = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
           id value = [s objectForKey:key];
           if (value == nil || value == [NSNull null]) {
               return @"";
           }
           return [value isKindOfClass:[NSString class]] ? (NSString *)value : [value description];
      }
      @catch (NSException *exception) {
          return @"";
      }
  }

  + (NSDictionary *)public_keys {
    return (NSDictionary *)DOT_ENV;
  }

  + (NSString *)publicFor: (NSString *)key {
      NSString *value = (NSString *)[self.public_keys objectForKey:key];
      return value;
  }

// Don't compile this code when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeKeysSpecJSI>(params);
}
#endif
@end
