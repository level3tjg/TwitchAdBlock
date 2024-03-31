#import "Tweak.h"

static NSData *TWAdBlockData(NSURLRequest *request, NSData *data) {
  if (![request.URL.host isEqualToString:@"gql.twitch.tv"] ||
      ![request.URL.path isEqualToString:@"/gql"])
    return data;
  NSError *error;
  NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                              options:NSJSONReadingMutableContainers
                                                                error:&error];
  if (error || ![json isKindOfClass:NSDictionary.class]) return data;

  uint32_t platformLength = 0;
  while (platformLength < 3) platformLength = arc4random_uniform(8);
  NSString *platform = [[NSUUID UUID].UUIDString substringWithRange:NSMakeRange(0, platformLength)];
  if ([json[@"operationName"] isEqualToString:@"StreamAccessToken"] ||
      [json[@"query"] containsString:@"StreamAccessToken"] ||
      [json[@"operationName"] isEqualToString:@"VodAccessToken"])
    json[@"variables"][@"params"][@"platform"] = platform;
  else if ([json[@"operationName"] isEqualToString:@"ClipAccessToken"])
    json[@"variables"][@"tokenParams"][@"platform"] = platform;
  else
    return data;
  NSData *modifiedData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
  if (error) return data;
  return modifiedData;
}

%hook _TtC6Twitch23FollowingViewController
- (instancetype)initWithGraphQL:(_TtC9TwitchKit9TKGraphQL *)graphQL
                   themeManager:(_TtC12TwitchCoreUI21TWDefaultThemeManager *)themeManager {
  if (![NSUserDefaults.standardUserDefaults boolForKey:@"TWAdBlockEnabled"])
    return %orig;
  if ((self = %orig) && class_getInstanceVariable(self.class, "headlinerManager"))
    MSHookIvar<id>(MSHookIvar<id>(self, "headlinerManager"), "displayAdStateManager") = NULL;
  return self;
}
%end

%hook _TtC6Twitch27HeadlinerFollowingAdManager
+ (instancetype)shared {
  if (![NSUserDefaults.standardUserDefaults boolForKey:@"TWAdBlockEnabled"])
    return %orig;
  _TtC6Twitch27HeadlinerFollowingAdManager *shared = %orig;
  if (shared && class_getInstanceVariable(shared.class, "displayAdStateManager"))
    MSHookIvar<id>(shared, "displayAdStateManager") = NULL;
  return shared;
}
%end

%hook _TtC6Twitch14VASTAdProvider
- (instancetype)init {
  if ((self = %orig)) {
    MSHookIvar<NSInteger>(self, "adLoadingTimeout") = -1;
  }
  return self;
}
%end

%hook NSURLSession
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(NSData *)bodyData {
  if (![NSUserDefaults.standardUserDefaults boolForKey:@"TWAdBlockEnabled"] || !bodyData)
    return %orig;
  bodyData = TWAdBlockData(request, bodyData);
  return %orig;
}
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
  if (![NSUserDefaults.standardUserDefaults boolForKey:@"TWAdBlockEnabled"] || !request.HTTPBody)
    return %orig;
  NSData *modifiedData = TWAdBlockData(request, request.HTTPBody);
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

%hook _TtC6PMHTTPP33_7DE81BD859C4442C3EC1B705AFDC8F2922MetricsSessionDelegate
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
  NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
  if (![userDefaults boolForKey:@"TWAdBlockEnabled"] ||
      ![userDefaults boolForKey:@"TWAdBlockProxyEnabled"])
    return %orig;
  if ([dataTask.currentRequest.URL.host isEqualToString:@"usher.ttvnw.net"]) {
    NSURLSessionConfiguration *configuration =
        NSURLSessionConfiguration.defaultSessionConfiguration;
    NSString *proxy = [userDefaults boolForKey:@"TWAdBlockCustomProxy"]
                          ? [userDefaults stringForKey:@"TWAdBlockProxy"]
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
    __block NSData *newData = data;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[session dataTaskWithURL:dataTask.currentRequest.URL
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
              if (!error) newData = data;
              dispatch_semaphore_signal(semaphore);
            }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    data = newData;
  }
  return %orig;
}
%end

%hook _TtC6Twitch18LiveHLSURLProvider
- (NSURL *)manifestURLWithToken:(NSString *)token
                tokenDictionary:(NSDictionary *)tokenDictionary
                      signature:(NSString *)signature {
  NSURL *manifestURL = %orig;
  providers[manifestURL.path] = self;
  return manifestURL;
}
%end

%hook _TtC6Twitch21PlayerCoreVideoPlayer
- (void)player:(IVSPlayer *)player
    didOutputMetadataWithType:(NSString *)type
                      content:(NSData *)content {
  %orig;
  if (![NSUserDefaults.standardUserDefaults boolForKey:@"TWAdBlockEnabled"]) return;
  if ([[[NSString alloc] initWithData:content
                             encoding:NSUTF8StringEncoding] containsString:@"stitched-ad"]) {
    TWHLSProvider *provider = providers[player.path.path];
    if (provider) [provider requestManifest];
  }
}
%end

%ctor {
  providers = [NSMutableDictionary dictionary];
}
