#import "Tweak.h"

%hook _TtC6Twitch19TheaterAdController
- (void)theaterWasPresented:(NSNotification *)notification {
  %orig;
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"TWAdBlockEnabled"]) return;
  const char *ivars[] = {
      "displayAdController",
      "videoAdController",
      "vastAdController",
  };
  for (int i = 0; i < sizeof(ivars) / sizeof(const char *); i++)
    if (class_getInstanceVariable(object_getClass(self), ivars[i]))
      MSHookIvar<id>(self, ivars[i]) = NULL;
}
%end

%hook TWHLSProvider
- (NSString *)playerTypeStringForRequestType:(NSInteger)requestType {
  playerType = %orig;
  return playerType;
}
%end

static void handle_URLSession_dataTask_didReceieveData(
    id self, SEL _cmd, NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data,
    void (*orig)(id, SEL, NSURLSession *, NSURLSessionDataTask *, NSData *)) {
  NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
  if (![userDefaults boolForKey:@"TWAdBlockEnabled"] ||
      ![userDefaults boolForKey:@"TWAdBlockPlatformRandomizationEnabled"] ||
      dataTask.currentRequest.HTTPBody)
    return orig(self, _cmd, session, dataTask, data);
  NSError *error;
  NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                       options:NSJSONReadingMutableContainers
                                                         error:&error];
  if (error || ![json isKindOfClass:NSDictionary.class])
    return orig(self, _cmd, session, dataTask, data);
  if (json) {
    if (!json[@"data"][@"streamPlaybackAccessToken"])
      return orig(self, _cmd, session, dataTask, data);
    NSDictionary *tokenDictionary = [NSJSONSerialization
        JSONObjectWithData:[json[@"data"][@"streamPlaybackAccessToken"][@"value"]
                               dataUsingEncoding:NSASCIIStringEncoding]
                   options:NSJSONReadingMutableContainers
                     error:&error];
    if (error) return orig(self, _cmd, session, dataTask, data);
    NSString *channelName = tokenDictionary[@"channel"];
    uint32_t platformLength = 0;
    while (platformLength < 3) platformLength = arc4random_uniform(8);
    NSDictionary *body = @{
      @"extensions" : @{
        @"persistedQuery" : @{
          @"sha256Hash" : @"28fd67532c7e6e3cd78d03caf98f3acc0eda738049003b57d4dd8e529c89a9c3",
          @"version" : @1,
        }
      },
      @"id" : @"28fd67532c7e6e3cd78d03caf98f3acc0eda738049003b57d4dd8e529c89a9c3",
      @"operationName" : @"StreamAccessToken",
      @"variables" : @{
        @"channelName" : channelName,
        @"params" : @{
          @"platform" :
              [[NSUUID UUID].UUIDString substringWithRange:NSMakeRange(0, platformLength)],
          @"playerType" : playerType,
        }
      },
    };
    NSMutableURLRequest *request = dataTask.currentRequest.mutableCopy;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
    if (error) return orig(self, _cmd, session, dataTask, data);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSData *newData = data;
    [[NSURLSession.sharedSession
        dataTaskWithRequest:request
          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
              dispatch_semaphore_signal(semaphore);
              return;
            }
            newData = data;
            dispatch_semaphore_signal(semaphore);
          }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    orig(self, _cmd, session, dataTask, newData);
  }
}

%hook _TtC6PMHTTPP33_7DE81BD859C4442C3EC1B705AFDC8F2922MetricsSessionDelegate
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
  return handle_URLSession_dataTask_didReceieveData(
      self, _cmd, session, dataTask, data,
      (void (*)(id, SEL, NSURLSession *, NSURLSessionDataTask *, NSData *)) & %orig);
}
%end

%hook _TtC9TwitchKit18TKURLSessionClient
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
  return handle_URLSession_dataTask_didReceieveData(
      self, _cmd, session, dataTask, data,
      (void (*)(id, SEL, NSURLSession *, NSURLSessionDataTask *, NSData *)) & %orig);
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
  if ([NSUserDefaults.standardUserDefaults boolForKey:@"TWAdBlockEnabled"] &&
      [NSUserDefaults.standardUserDefaults boolForKey:@"TWAdBlockPlatformRandomizationEnabled"] &&
      [[[NSString alloc] initWithData:content
                             encoding:NSUTF8StringEncoding] containsString:@"stitched-ad"]) {
    TWHLSProvider *provider = providers[player.path.path];
    if (provider) [provider requestManifest];
  }
}
%end

%hook TWHLSResource
- (NSURL *)URLWithAllowAudioOnly:(BOOL)allowAudioOnly
                     allowSource:(BOOL)allowSource
                     maxAVCLevel:(NSString *)maxAVCLevel {
  NSURL *url = %orig;

  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

  if (![userDefaults boolForKey:@"TWAdBlockEnabled"] ||
      ![userDefaults boolForKey:@"TWAdBlockProxyEnabled"])
    return url;

  NSURL *proxy = [userDefaults boolForKey:@"TWAdBlockCustomProxyEnabled"]
                     ? [NSURL URLWithString:[userDefaults objectForKey:@"TWAdBlockProxy"]]
                     : [NSURL URLWithString:PROXY_URL];

  // Get token dictionary
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
  NSUInteger tokenQueryItemIdx = [components.queryItems
      indexOfObjectPassingTest:^(NSURLQueryItem *queryItem, NSUInteger idx, BOOL *stop) {
        if ([queryItem.name isEqualToString:@"token"]) {
          *stop = YES;
          return YES;
        }
        return NO;
      }];
  NSDictionary *tokenDictionary;
  if (tokenQueryItemIdx != NSNotFound) {
    NSURLQueryItem *tokenQueryItem = components.queryItems[tokenQueryItemIdx];
    tokenDictionary = [NSJSONSerialization
        JSONObjectWithData:[tokenQueryItem.value dataUsingEncoding:NSUTF8StringEncoding]
                   options:0
                     error:nil];
  }

  // Validate

  // Not sure if this flag is available for VODs, for now we'll just use the
  // proxy anyways
  if (tokenDictionary && tokenDictionary[@"server_ads"] &&
      ![tokenDictionary[@"server_ads"] boolValue])
    return url;

  if (!proxy || ![proxy.scheme hasPrefix:@"http"] || !proxy.host) return url;

  // Substitute
  NSString *channel =
      tokenDictionary ? tokenDictionary[@"channel"] : [url.path stringByDeletingPathExtension];
  NSString *path = [[NSString stringWithFormat:@"%@?%@", url.path, url.query] substringFromIndex:1];
  NSString *playlist = [NSString stringWithFormat:@"%@?%@", url.lastPathComponent, url.query];
  NSDictionary *substitutes = @{
    @"channel" : channel,
    @"path" : path,
    @"playlist" : playlist,
  };
  for (NSString *key in substitutes.allKeys)
    proxy = [NSURL
        URLWithString:[proxy.absoluteString
                          stringByReplacingOccurrencesOfString:[@":" stringByAppendingString:key]
                                                    withString:substitutes[key]]];

  return proxy;
}
%end

%ctor {
  providers = [NSMutableDictionary dictionary];
}
