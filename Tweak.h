#import <AmazonIVSPlayer/IVSPlayer.h>
#import <Twitch/FollowingViewController.h>
#import <Twitch/HeadlinerFollowingAdManager.h>
#import <Twitch/LiveHLSURLProvider.h>
#import <Twitch/TheaterViewController.h>
#import <TwitchCoreUI/TWDefaultThemeManager.h>
#import <TwitchKit/TKGraphQL.h>

@interface _TtC6Twitch21TheaterViewController ()
- (void)removeAdControllers;
@end

static NSMutableDictionary<NSString *, TWHLSProvider *> *providers;