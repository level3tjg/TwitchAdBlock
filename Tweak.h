#import <Foundation/Foundation.h>

#define PROXY_URL @"https://proxy.level3tjg.me/:path"

@interface TWAnalyticsController : NSObject
+ (instancetype)analyticsController;
@end

@interface _TtC6PMHTTP11HTTPManager : NSObject
+ (instancetype)defaultManager;
@end

@interface TWHLSProvider : NSObject
- (NSString *)playerTypeStringForRequestType:(NSInteger)requestType;
- (void)requestManifest;
- (instancetype)
    initWithAnalyticsController:(TWAnalyticsController *)analyticsController
                    httpManager:(_TtC6PMHTTP11HTTPManager *)httpManager
                     playerType:(NSInteger)playerType;
@end

@interface _TtC6Twitch18LiveHLSURLProvider : TWHLSProvider
@end

@interface IVSPlayer : NSObject
@property(nonatomic, copy) NSURL *path;
@end

static NSString *playerType;
static NSMutableDictionary<NSString *, TWHLSProvider *> *providers;