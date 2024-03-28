#import <Foundation/Foundation.h>

@interface TWHLSProvider : NSObject
- (NSString *)playerTypeStringForRequestType:(NSInteger)requestType;
- (void)requestManifest;
@end