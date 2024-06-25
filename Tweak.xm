#import "Tweak.h"

NSBundle *tweakBundle;
NSUserDefaults *tweakDefaults;

static NSData *TWAdBlockRequestData(NSURLRequest *request, NSData *data) {
  if (![tweakDefaults boolForKey:@"TWAdBlockEnabled"] || !request || !data) return data;
  __block NSData *modifiedData;
  if ([request.URL.host isEqualToString:@"gql.twitch.tv"] &&
      [request.URL.path isEqualToString:@"/gql"]) {
    NSError *error;
    id json = [NSJSONSerialization JSONObjectWithData:data
                                              options:NSJSONReadingMutableContainers
                                                error:&error];
    if (!json || error) return data;
    if ([json isKindOfClass:NSMutableDictionary.class]) {
      NSMutableDictionary *jsonDictionary = json;
      uint32_t platformLength = 0;
      while (platformLength < 3) platformLength = arc4random_uniform(8);
      NSString *platform =
          [[NSUUID UUID].UUIDString substringWithRange:NSMakeRange(0, platformLength)];
      if ([jsonDictionary[@"operationName"] isEqualToString:@"StreamAccessToken"] ||
          [jsonDictionary[@"query"] containsString:@"StreamAccessToken"] ||
          [jsonDictionary[@"operationName"] isEqualToString:@"VodAccessToken"])
        jsonDictionary[@"variables"][@"params"][@"platform"] = platform;
      else if ([jsonDictionary[@"operationName"] isEqualToString:@"ClipAccessToken"])
        jsonDictionary[@"variables"][@"tokenParams"][@"platform"] = platform;
    }
    modifiedData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
    if (error) return data;
  }
  return modifiedData ?: data;
}

static NSData *TWAdBlockResponseData(NSURLRequest *request, NSData *data) {
  if ([tweakDefaults boolForKey:@"TWAdBlockEnabled"] || !request || !data) return data;
  __block NSData *modifiedData;
  if ([request.URL.host isEqualToString:@"gql.twitch.tv"] &&
      [request.URL.path isEqualToString:@"/gql"]) {
    NSError *error;
    id json = [NSJSONSerialization JSONObjectWithData:data
                                              options:NSJSONReadingMutableContainers
                                                error:&error];
    if (!json || error) return data;
    if ([json isKindOfClass:NSMutableArray.class]) {
      NSMutableArray *jsonArray = json;
      for (NSMutableDictionary *operation in jsonArray) {
        NSMutableDictionary *feedItems = operation[@"data"][@"feedItems"];
        if (feedItems) {
          feedItems[@"edges"] = [feedItems[@"edges"]
              filteredArrayUsingPredicate:
                  [NSPredicate predicateWithFormat:@"self.node.__typename != 'FeedAd'"]];
        }
      }
    }
    modifiedData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
    if (error) return data;
  }
  return modifiedData ?: data;
}

static NSData *TWAdBlockProxyData(NSURLRequest *request, NSData *data) {
  if (![tweakDefaults boolForKey:@"TWAdBlockEnabled"] ||
      ![tweakDefaults boolForKey:@"TWAdBlockProxyEnabled"] || !request || !data)
    return data;
  __block NSData *modifiedData;
  if ([request.URL.host isEqualToString:@"usher.ttvnw.net"]) {
    NSURLSessionConfiguration *configuration =
        NSURLSessionConfiguration.defaultSessionConfiguration;
    NSString *proxy = [tweakDefaults boolForKey:@"TWAdBlockCustomProxyEnabled"]
                          ? [tweakDefaults stringForKey:@"TWAdBlockProxy"]
                          : PROXY_URL;
    NSArray<NSString *> *proxyComponents = [proxy componentsSeparatedByString:@":"];
    NSString *host = proxyComponents[0];
    NSNumber *port = proxyComponents.count != 1 ? @(proxyComponents[1].integerValue) : @8080;
    configuration.connectionProxyDictionary = @{
      @"HTTPSEnable" : @YES,
      @"HTTPSProxy" : host,
      @"HTTPSPort" : port,
    };
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[session dataTaskWithURL:request.URL
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
              if (!error) modifiedData = data;
              dispatch_semaphore_signal(semaphore);
            }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
  }
  return modifiedData ?: data;
}

// Server-side video ad blocking

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
  NSData *modifiedData = TWAdBlockRequestData(request, request.HTTPBody);
  if ([request isKindOfClass:NSMutableURLRequest.class]) {
    ((NSMutableURLRequest *)request).HTTPBody = modifiedData;
  } else {
    NSMutableURLRequest *mutableRequest = request.mutableCopy;
    mutableRequest.HTTPBody = modifiedData;
    request = mutableRequest.copy;
  }
  return %orig;
}
%end

%hook NSURLSession
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(NSData *)bodyData {
  bodyData = TWAdBlockRequestData(request, bodyData);
  return %orig;
}
%end

// Client-side video ad blocking

id (*orig_swift_unknownObjectWeakLoadStrong)();
id hook_swift_unknownObjectWeakLoadStrong() {
  id obj = orig_swift_unknownObjectWeakLoadStrong();
  if (class_getInstanceVariable(object_getClass(obj), "theaterAdController")) {
    id theaterAdController = MSHookIvar<id>(obj, "theaterAdController");
    const char *ivars[] = {"displayAdController", "streamDisplayAdStateManager",
                           "vastAdController"};
    for (int i = 0; i < sizeof(ivars) / sizeof(const char *); i++) {
      const char *ivar = ivars[i];
      if (class_getInstanceVariable(object_getClass(theaterAdController), ivar))
        MSHookIvar<id>(theaterAdController, ivar) = NULL;
    }
  }
  return obj;
}

// Block ads in feed tab

%hook _TtC9TwitchKit18TKURLSessionClient
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
  data = TWAdBlockResponseData(dataTask.currentRequest, data);
  %orig;
}
%end

// Block ads in following tab

%hook _TtC6Twitch23FollowingViewController
- (instancetype)initWithGraphQL:(_TtC9TwitchKit9TKGraphQL *)graphQL
                   themeManager:(_TtC12TwitchCoreUI21TWDefaultThemeManager *)themeManager {
  if (![tweakDefaults boolForKey:@"TWAdBlockEnabled"]) return %orig;
  if ((self = %orig) && class_getInstanceVariable(self.class, "headlinerManager"))
    MSHookIvar<id>(MSHookIvar<id>(self, "headlinerManager"), "displayAdStateManager") = NULL;
  return self;
}
%end

%hook _TtC6Twitch27HeadlinerFollowingAdManager
+ (instancetype)shared {
  if (![tweakDefaults boolForKey:@"TWAdBlockEnabled"]) return %orig;
  _TtC6Twitch27HeadlinerFollowingAdManager *shared = %orig;
  if (shared && class_getInstanceVariable(shared.class, "displayAdStateManager"))
    MSHookIvar<id>(shared, "displayAdStateManager") = NULL;
  return shared;
}
%end

// Proxy m3u8 requests

%hook _TtC6PMHTTPP33_7DE81BD859C4442C3EC1B705AFDC8F2922MetricsSessionDelegate
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
  data = TWAdBlockProxyData(dataTask.currentRequest, data);
  return %orig;
}
%end

// Block update prompt

%hook TWAppUpdatePrompt
+ (void)startMonitoringSavantSettingsToShowPromptIfNeeded {
}
%end

%ctor {
  tweakBundle = [NSBundle bundleWithPath:[NSBundle.mainBundle pathForResource:@"TwitchAdBlock"
                                                                       ofType:@"bundle"]];
  if (!tweakBundle)
    tweakBundle = [NSBundle bundleWithPath:@THEOS_PACKAGE_INSTALL_PREFIX
                            @"/Library/Application Support/TwitchAdBlock.bundle"];
  tweakDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.level3tjg.twitchadblock"];
  if (![tweakDefaults objectForKey:@"TWAdBlockEnabled"])
    [tweakDefaults setBool:YES forKey:@"TWAdBlockEnabled"];
  if (![tweakDefaults objectForKey:@"TWAdBlockProxy"])
    [tweakDefaults setObject:PROXY_URL forKey:@"TWAdBlockProxy"];
  if (![tweakDefaults objectForKey:@"TWAdBlockProxyEnabled"])
    [tweakDefaults setBool:NO forKey:@"TWAdBlockProxyEnabled"];
  if (![tweakDefaults objectForKey:@"TWAdBlockCustomProxyEnabled"])
    [tweakDefaults setBool:NO forKey:@"TWAdBlockCustomProxyEnabled"];
  rebind_symbols((struct rebinding[]){{"swift_unknownObjectWeakLoadStrong",
                                       (void *)hook_swift_unknownObjectWeakLoadStrong,
                                       (void **)&orig_swift_unknownObjectWeakLoadStrong}},
                 1);
}
