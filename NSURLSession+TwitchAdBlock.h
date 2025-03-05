#include <Foundation/Foundation.h>

@interface NSURLSession (TwitchAdBlock)
- (NSURLSession *)twab_proxySessionWithAddress:(NSString *)address;
@end