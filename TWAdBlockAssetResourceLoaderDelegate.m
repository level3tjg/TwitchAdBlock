#import "TWAdBlockAssetResourceLoaderDelegate.h"

extern NSUserDefaults *tweakDefaults;

@implementation TWAdBlockAssetResourceLoaderDelegate
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
  return [self handleLoadingRequest:loadingRequest];
}
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader
    shouldWaitForRenewalOfRequestedResource:(AVAssetResourceRenewalRequest *)renewalRequest {
  return [self handleLoadingRequest:renewalRequest];
}
@end