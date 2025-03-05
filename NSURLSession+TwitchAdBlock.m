#import "NSURLSession+TwitchAdBlock.h"

@implementation NSURLSession (TwitchAdBlock)
- (NSURLSession *)twab_proxySessionWithAddress:(NSString *)address {
  NSURLSessionConfiguration *configuration =
      self.configuration ?: NSURLSessionConfiguration.defaultSessionConfiguration;
  NSArray<NSString *> *addressComponents = [address componentsSeparatedByString:@":"];
  NSString *host = addressComponents[0];
  NSNumber *port = addressComponents.count > 1 ? @(addressComponents[1].integerValue) : @8080;
  configuration.connectionProxyDictionary = @{
    @"HTTPSEnable" : @YES,
    @"HTTPSProxy" : host,
    @"HTTPSPort" : port,
  };
  return [NSURLSession sessionWithConfiguration:configuration
                                       delegate:self.delegate
                                  delegateQueue:self.delegateQueue];
}
@end