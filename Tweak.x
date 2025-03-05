#import <dlfcn.h>
#import "Tweak.h"

NSBundle *tweakBundle;
NSUserDefaults *tweakDefaults;
TWAdBlockAssetResourceLoaderDelegate *assetResourceLoaderDelegate;

// Server-side video ad blocking

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
  if (![tweakDefaults boolForKey:@"TWAdBlockEnabled"]) return %orig;
  if (![request isKindOfClass:NSMutableURLRequest.class]) request = request.mutableCopy;
  ((NSMutableURLRequest *)request).HTTPBody = [request.HTTPBody twab_requestDataForRequest:request];
  if (![tweakDefaults boolForKey:@"TWAdBlockProxyEnabled"]) return %orig;
  NSString *proxy = [tweakDefaults boolForKey:@"TWAdBlockCustomProxyEnabled"]
                        ? [tweakDefaults stringForKey:@"TWAdBlockProxy"]
                        : PROXY_ADDR;
  if (![request.URL.host isEqualToString:@"usher.ttvnw.net"]) return %orig;
  NSURL *proxyURL = [NSURL URLWithString:proxy];
  if ([proxyURL.scheme hasPrefix:@"http"])
    ((NSMutableURLRequest *)request).URL = [request.URL twab_URLWithProxyURL:proxyURL];
  else
    return &%orig([self twab_proxySessionWithAddress:proxy], _cmd, request);
  return %orig;
}
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(NSData *)bodyData {
  if (![tweakDefaults boolForKey:@"TWAdBlockEnabled"]) return %orig;
  if (![request isKindOfClass:NSMutableURLRequest.class]) request = request.mutableCopy;
  bodyData = [bodyData twab_requestDataForRequest:request];
  if (![tweakDefaults boolForKey:@"TWAdBlockProxyEnabled"]) return %orig;
  NSString *proxy = [tweakDefaults boolForKey:@"TWAdBlockCustomProxyEnabled"]
                        ? [tweakDefaults stringForKey:@"TWAdBlockProxy"]
                        : PROXY_ADDR;
  if (![request.URL.host isEqualToString:@"usher.ttvnw.net"]) return %orig;
  NSURL *proxyURL = [NSURL URLWithString:proxy];
  if ([proxyURL.scheme hasPrefix:@"http"])
    ((NSMutableURLRequest *)request).URL = [request.URL twab_URLWithProxyURL:proxyURL];
  else
    return &%orig([self twab_proxySessionWithAddress:proxy], _cmd, request, bodyData);
  return %orig;
}
%end

%hook AVURLAsset
- (instancetype)initWithURL:(NSURL *)URL options:(NSDictionary<NSString *, id> *)options {
  if (![tweakDefaults boolForKey:@"TWAdBlockEnabled"] ||
      ![tweakDefaults boolForKey:@"TWAdBlockProxyEnabled"] ||
      ![URL.scheme isEqualToString:@"https"] || ![URL.host isEqualToString:@"usher.ttvnw.net"])
    return %orig;
  NSURL *proxyURL = [NSURL URLWithString:[tweakDefaults boolForKey:@"TWAdBlockCustomProxyEnabled"]
                                             ? [tweakDefaults stringForKey:@"TWAdBlockProxy"]
                                             : PROXY_ADDR];
  if ([proxyURL.scheme hasPrefix:@"http"])
    return %orig([URL twab_URLWithProxyURL:proxyURL], options);
  NSURLComponents *components = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES];
  components.scheme = @"twab";
  URL = components.URL;
  if ((self = %orig)) {
    [self.resourceLoader setDelegate:assetResourceLoaderDelegate
                               queue:dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)];
  }
  return self;
}
%end

%hook _TtC6Twitch27AssetResourceLoaderDelegate
%new
- (BOOL)handleLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
  NSURL *URL = loadingRequest.request.URL;
  if (![URL.scheme isEqualToString:@"twab"]) return NO;
  AVAssetResourceLoadingDataRequest *dataRequest = loadingRequest.dataRequest;
  NSURLComponents *components = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES];
  components.scheme = @"https";
  NSMutableURLRequest *request = loadingRequest.request.mutableCopy;
  request.URL = components.URL;
  NSString *proxy = [tweakDefaults boolForKey:@"TWAdBlockCustomProxyEnabled"]
                        ? [tweakDefaults stringForKey:@"TWAdBlockProxy"]
                        : PROXY_ADDR;
  NSURLSession *session = [[NSURLSession alloc] twab_proxySessionWithAddress:proxy];
  [[session dataTaskWithRequest:request
              completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error) return [loadingRequest finishLoadingWithError:error];
                loadingRequest.contentInformationRequest.contentType = AVFileTypeMPEG4;
                [dataRequest respondWithData:data];
                [loadingRequest finishLoading];
              }] resume];
  return YES;
}
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader
    shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
  return ![self handleLoadingRequest:loadingRequest] ? %orig : YES;
}
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader
    shouldWaitForRenewalOfRequestedResource:(AVAssetResourceRenewalRequest *)renewalRequest {
  return ![self handleLoadingRequest:renewalRequest] ? %orig : YES;
}
%end

%hook AVPlayer
- (instancetype)init {
  if ((self = %orig)) {
    [self addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
  }
  return self;
}
%new
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
  if ([keyPath isEqualToString:@"status"] &&
      [change[NSKeyValueChangeNewKey] integerValue] == AVPlayerStatusReadyToPlay)
    [self play];
}
%end

// Client-side video ad blocking

static void removeAdControllers(void *ptr) {
  if (((uintptr_t)ptr & 0xFFFF800000000000) != 0) return;
  id obj = (__bridge id)ptr;
  Ivar theaterAdControllerIvar =
      class_getInstanceVariable(object_getClass(obj), "theaterAdController");
  if (!theaterAdControllerIvar) return;
  id theaterAdController = object_getIvar(obj, theaterAdControllerIvar);
  const char *ivars[] = {"displayAdController", "streamDisplayAdStateManager", "vastAdController"};
  for (int i = 0; i < sizeof(ivars) / sizeof(ivars[0]); i++) {
    Ivar adControllerIvar =
        class_getInstanceVariable(object_getClass(theaterAdController), ivars[i]);
    if (adControllerIvar) object_setIvar(theaterAdController, adControllerIvar, nil);
  }
}

static void *(*orig_swift_unknownObjectWeakAssign)(void *, void *);
static void *hook_swift_unknownObjectWeakAssign(void *ref, void *value) {
  void *result = orig_swift_unknownObjectWeakAssign(ref, value);
  if (![tweakDefaults boolForKey:@"TWAdBlockEnabled"]) return result;
  removeAdControllers(value);
  return result;
}

static void *(*orig_swift_unknownObjectWeakLoadStrong)(void *);
static void *hook_swift_unknownObjectWeakLoadStrong(void *ref) {
  void *result = orig_swift_unknownObjectWeakLoadStrong(ref);
  if (![tweakDefaults boolForKey:@"TWAdBlockEnabled"]) return result;
  removeAdControllers(result);
  return result;
}

// Block ads in feed tab

%hook _TtC9TwitchKit18TKURLSessionClient
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
  if (![tweakDefaults boolForKey:@"TWAdBlockEnabled"]) return %orig;
  %orig(session, dataTask, [data twab_responseDataForRequest:dataTask.currentRequest]);
}
%end

// Block ads in following tab

%hook _TtC6Twitch23FollowingViewController
- (instancetype)initWithGraphQL:(_TtC9TwitchKit9TKGraphQL *)graphQL
                   themeManager:(_TtC12TwitchCoreUI21TWDefaultThemeManager *)themeManager {
  if (![tweakDefaults boolForKey:@"TWAdBlockEnabled"]) return %orig;
  if ((self = %orig)) {
    Ivar headlinerManagerIvar =
        class_getInstanceVariable(object_getClass(self), "headlinerManager");
    if (headlinerManagerIvar) {
      Ivar displayAdStateManagerIvar =
          class_getInstanceVariable(object_getClass(self), "displayAdStateManager");
      if (displayAdStateManagerIvar) object_setIvar(self, displayAdStateManagerIvar, nil);
    }
  }
  return self;
}
- (instancetype)initWithGraphQL:(_TtC9TwitchKit9TKGraphQL *)graphQL
                   themeManager:(_TtC12TwitchCoreUI21TWDefaultThemeManager *)themeManager
                  urlController:(_TtC6Twitch13URLController *)urlController {
  if (![tweakDefaults boolForKey:@"TWAdBlockEnabled"]) return %orig;
  if ((self = %orig)) {
    Ivar headlinerManagerIvar =
        class_getInstanceVariable(object_getClass(self), "headlinerManager");
    if (headlinerManagerIvar) {
      Ivar displayAdStateManagerIvar =
          class_getInstanceVariable(object_getClass(self), "displayAdStateManager");
      if (displayAdStateManagerIvar) object_setIvar(self, displayAdStateManagerIvar, nil);
    }
  }
  return self;
}
%end

%hook _TtC6Twitch27HeadlinerFollowingAdManager
+ (instancetype)shared {
  if (![tweakDefaults boolForKey:@"TWAdBlockEnabled"]) return %orig;
  _TtC6Twitch27HeadlinerFollowingAdManager *shared = %orig;
  if (shared) {
    Ivar displayAdStateManagerIvar =
        class_getInstanceVariable(object_getClass(shared), "displayAdStateManager");
    if (displayAdStateManagerIvar) object_setIvar(shared, displayAdStateManagerIvar, nil);
  }
  return shared;
}
%end

// Block update prompt

%hook TWAppUpdatePrompt
+ (void)startMonitoringSavantSettingsToShowPromptIfNeeded {
}
%end

%ctor {
  rebind_symbols(
      (struct rebinding[]){
          {"swift_unknownObjectWeakAssign", (void *)hook_swift_unknownObjectWeakAssign,
           (void **)&orig_swift_unknownObjectWeakAssign},
          {"swift_unknownObjectWeakLoadStrong", (void *)hook_swift_unknownObjectWeakLoadStrong,
           (void **)&orig_swift_unknownObjectWeakLoadStrong},
      },
      2);
  tweakBundle = [NSBundle bundleWithPath:[NSBundle.mainBundle pathForResource:@"TwitchAdBlock"
                                                                       ofType:@"bundle"]];
  if (!tweakBundle)
    tweakBundle = [NSBundle
        bundleWithPath:ROOT_PATH_NS(@"/Library/Application Support/TwitchAdBlock.bundle")];
  tweakDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.level3tjg.twitchadblock"];
  if (![tweakDefaults objectForKey:@"TWAdBlockEnabled"])
    [tweakDefaults setBool:YES forKey:@"TWAdBlockEnabled"];
  if (![tweakDefaults objectForKey:@"TWAdBlockProxyEnabled"])
    [tweakDefaults setBool:NO forKey:@"TWAdBlockProxyEnabled"];
  if (![tweakDefaults objectForKey:@"TWAdBlockCustomProxyEnabled"])
    [tweakDefaults setBool:NO forKey:@"TWAdBlockCustomProxyEnabled"];
  assetResourceLoaderDelegate = [[TWAdBlockAssetResourceLoaderDelegate alloc] init];
}
