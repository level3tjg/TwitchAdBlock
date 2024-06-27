#import <AmazonIVSPlayer/IVSPlayer.h>
#import <CoreServices/LSApplicationProxy.h>
#import <Twitch/FollowingViewController.h>
#import <Twitch/HeadlinerFollowingAdManager.h>
#import <Twitch/LiveHLSURLProvider.h>
#import <Twitch/TheaterViewController.h>
#import <TwitchCoreUI/TWDefaultThemeManager.h>
#import <TwitchKit/TKGraphQL.h>
#import <notify.h>

#import "fishhook/fishhook.h"

@interface NSUserDefaults ()
- (instancetype)_initWithSuiteName:(NSString *)suiteName container:(NSURL *)container;
@end