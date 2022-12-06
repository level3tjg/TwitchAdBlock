#import <Foundation/Foundation.h>

#define PROXY_URL @"https://proxy.level3tjg.me/:path"

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

%hook NSURLSession
- (instancetype)dataTaskWithRequest:(NSURLRequest *)request {
  if ([NSUserDefaults.standardUserDefaults boolForKey:@"TWAdBlockPlatformRandomizationEnabled"] &&
      [request.URL.host isEqualToString:@"gql.twitch.tv"] && request.HTTPBody) {
    NSDictionary *operation = [NSJSONSerialization JSONObjectWithData:request.HTTPBody
                                                              options:NSJSONReadingMutableContainers
                                                                error:nil];
    if (![operation isKindOfClass:NSDictionary.class] ||
        ![operation[@"operationName"] isEqualToString:@"StreamAccessToken"])
      return %orig;
    NSMutableURLRequest *mutableRequest = request.mutableCopy;
    uint32_t platformLength = 0;
    while (platformLength < 3) platformLength = arc4random_uniform(8);
    operation[@"variables"][@"params"][@"platform"] =
        [[NSUUID UUID].UUIDString substringWithRange:NSMakeRange(0, platformLength)];
    mutableRequest.HTTPBody = [NSJSONSerialization dataWithJSONObject:operation
                                                              options:0
                                                                error:nil];
    request = mutableRequest.copy;
  }
  return %orig;
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
