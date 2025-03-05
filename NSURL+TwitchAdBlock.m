#include <Foundation/NSJSONSerialization.h>
#include <Foundation/NSURL.h>
#include <Foundation/NSURLResponse.h>
#import "NSURL+TwitchAdBlock.h"

@implementation NSURL (TwitchAdBlock)
- (NSURL *)twab_URLWithProxyURL:(NSURL *)proxyURL {
  BOOL isVOD = [self.path.pathComponents[1] isEqualToString:@"vod"];
  NSString *playlistItem = [self.lastPathComponent stringByDeletingPathExtension];
  __block BOOL isLuminousV1;
  dispatch_semaphore_t semaphpore = dispatch_semaphore_create(0);
  [[NSURLSession.sharedSession
      dataTaskWithRequest:[NSURLRequest
                              requestWithURL:[proxyURL URLByAppendingPathComponent:@"ping"]]
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
          isLuminousV1 = [response isKindOfClass:NSHTTPURLResponse.class] &&
                         ((NSHTTPURLResponse *)response).statusCode == 200;
          dispatch_semaphore_signal(semaphpore);
        }] resume];
  dispatch_semaphore_wait(semaphpore, dispatch_time(DISPATCH_TIME_NOW, 500000000));
  if (isLuminousV1) {
    NSString *playlistType = isVOD ? @"vod" : @"playlist";
    return [[proxyURL URLByAppendingPathComponent:playlistType]
        URLByAppendingPathComponent:playlistItem];
  }
  return self;
}
@end