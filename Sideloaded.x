// https://github.com/PoomSmart/IAmYouTube/blob/main/Tweak.x
// Allows low latency player while sideloaded

#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import "fishhook/fishhook.h"

#define TW_BUNDLE_ID @"tv.twitch"
#define TW_NAME @"Twitch"

%hook NSBundle

- (NSString *)bundleIdentifier {
  NSArray *address = [NSThread callStackReturnAddresses];
  Dl_info info;
  if (dladdr((void *)[address[2] longLongValue], &info) == 0) return %orig;
  NSString *path = [NSString stringWithUTF8String:info.dli_fname];
  if ([path hasPrefix:NSBundle.mainBundle.bundlePath]) return TW_BUNDLE_ID;
  return %orig;
}

- (id)objectForInfoDictionaryKey:(NSString *)key {
  if ([key isEqualToString:@"CFBundleIdentifier"]) return TW_BUNDLE_ID;
  if ([key isEqualToString:@"CFBundleDisplayName"] || [key isEqualToString:@"CFBundleName"])
    return TW_NAME;
  return %orig;
}

%end

// https://github.com/opa334/IGSideloadFix

NSString* keychainAccessGroup;
NSURL* fakeGroupContainerURL;

void createDirectoryIfNotExists(NSURL* URL) {
  if (![URL checkResourceIsReachableAndReturnError:nil]) {
    [[NSFileManager defaultManager] createDirectoryAtURL:URL
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:nil];
  }
}

%group SideloadedFixes

%hook NSFileManager

- (NSURL*)containerURLForSecurityApplicationGroupIdentifier:(NSString*)groupIdentifier {
  NSURL* fakeURL = [fakeGroupContainerURL URLByAppendingPathComponent:groupIdentifier];

  createDirectoryIfNotExists(fakeURL);
  createDirectoryIfNotExists([fakeURL URLByAppendingPathComponent:@"Library"]);
  createDirectoryIfNotExists([fakeURL URLByAppendingPathComponent:@"Library/Caches"]);

  return fakeURL;
}

%end

static void loadKeychainAccessGroup() {
  NSDictionary* dummyItem = @{
    (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
    (__bridge id)kSecAttrAccount : @"dummyItem",
    (__bridge id)kSecAttrService : @"dummyService",
    (__bridge id)kSecReturnAttributes : @YES,
  };

  CFTypeRef result;
  OSStatus ret = SecItemCopyMatching((__bridge CFDictionaryRef)dummyItem, &result);
  if (ret == -25300) {
    ret = SecItemAdd((__bridge CFDictionaryRef)dummyItem, &result);
  }

  if (ret == 0 && result) {
    NSDictionary* resultDict = (__bridge id)result;
    keychainAccessGroup = resultDict[(__bridge id)kSecAttrAccessGroup];
    NSLog(@"loaded keychainAccessGroup: %@", keychainAccessGroup);
  }
}

%end

static OSStatus (*orig_SecItemAdd)(CFDictionaryRef, CFTypeRef*);
static OSStatus hook_SecItemAdd(CFDictionaryRef attributes, CFTypeRef* result) {
  if (CFDictionaryContainsKey(attributes, kSecAttrAccessGroup)) {
    CFMutableDictionaryRef mutableAttributes =
        CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, attributes);
    CFDictionarySetValue(mutableAttributes, kSecAttrAccessGroup,
                         (__bridge void*)keychainAccessGroup);
    attributes = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableAttributes);
  }
  return orig_SecItemAdd(attributes, result);
}

static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef, CFTypeRef*);
static OSStatus hook_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef* result) {
  if (CFDictionaryContainsKey(query, kSecAttrAccessGroup)) {
    CFMutableDictionaryRef mutableQuery =
        CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, query);
    CFDictionarySetValue(mutableQuery, kSecAttrAccessGroup, (__bridge void*)keychainAccessGroup);
    query = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableQuery);
  }
  return orig_SecItemCopyMatching(query, result);
}

static OSStatus (*orig_SecItemUpdate)(CFDictionaryRef, CFDictionaryRef);
static OSStatus hook_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
  if (CFDictionaryContainsKey(query, kSecAttrAccessGroup)) {
    CFMutableDictionaryRef mutableQuery =
        CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, query);
    CFDictionarySetValue(mutableQuery, kSecAttrAccessGroup, (__bridge void*)keychainAccessGroup);
    query = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableQuery);
  }
  return orig_SecItemUpdate(query, attributesToUpdate);
}

static OSStatus (*orig_SecItemDelete)(CFDictionaryRef);
static OSStatus hook_SecItemDelete(CFDictionaryRef query) {
  if (CFDictionaryContainsKey(query, kSecAttrAccessGroup)) {
    CFMutableDictionaryRef mutableQuery =
        CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, query);
    CFDictionarySetValue(mutableQuery, kSecAttrAccessGroup, (__bridge void*)keychainAccessGroup);
    query = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableQuery);
  }
  return orig_SecItemDelete(query);
}

static void initSideloadedFixes() {
  fakeGroupContainerURL =
      [NSURL fileURLWithPath:[NSHomeDirectory()
                                 stringByAppendingPathComponent:@"Documents/FakeGroupContainers"]
                 isDirectory:YES];
  loadKeychainAccessGroup();
  rebind_symbols(
      (struct rebinding[]){
          {"SecItemAdd", (void*)hook_SecItemAdd, (void**)&orig_SecItemAdd},
          {"SecItemCopyMatching", (void*)hook_SecItemCopyMatching,
           (void**)&orig_SecItemCopyMatching},
          {"SecItemUpdate", (void*)hook_SecItemUpdate, (void**)&orig_SecItemUpdate},
          {"SecItemDelete", (void*)hook_SecItemDelete, (void**)&orig_SecItemDelete},
      },
      4);
  %init(SideloadedFixes);
}

%ctor {
  %init;
  initSideloadedFixes();
}
