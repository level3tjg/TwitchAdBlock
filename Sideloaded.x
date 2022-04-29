// https://github.com/PoomSmart/IAmYouTube/blob/main/Tweak.x
// Allows low latency player while sideloaded

#import <dlfcn.h>

#define TW_BUNDLE_ID @"tv.twitch"
#define TW_NAME @"Twitch"

%hook NSBundle

- (NSString *)bundleIdentifier {
  NSArray *address = [NSThread callStackReturnAddresses];
  Dl_info info = {0};
  if (dladdr((void *)[address[2] longLongValue], &info) == 0)
    return %orig;
  NSString *path = [NSString stringWithUTF8String:info.dli_fname];
  if ([path hasPrefix:NSBundle.mainBundle.bundlePath])
    return TW_BUNDLE_ID;
  return %orig;
}

- (id)objectForInfoDictionaryKey:(NSString *)key {
  if ([key isEqualToString:@"CFBundleIdentifier"])
    return TW_BUNDLE_ID;
  if ([key isEqualToString:@"CFBundleDisplayName"] ||
      [key isEqualToString:@"CFBundleName"])
    return TW_NAME;
  return %orig;
}

%end
