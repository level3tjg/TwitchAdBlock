#import <AVFoundation/AVFoundation.h>
#import <AmazonIVSPlayer/IVSPlayer.h>
#import <AmazonIVSPlayer/IVSTextMetadataCue.h>
#import <CoreServices/LSApplicationProxy.h>
#import <Twitch/FollowingViewController.h>
#import <Twitch/HeadlinerFollowingAdManager.h>
#import <Twitch/LiveHLSURLProvider.h>
#import <Twitch/TheaterViewController.h>
#import <Twitch/URLController.h>
#import <TwitchCoreUI/TWDefaultThemeManager.h>
#import <TwitchKit/TKGraphQL.h>
#import <rootless.h>

#import "Config.h"
#import "NSData+TwitchAdBlock.h"
#import "NSURL+TwitchAdBlock.h"
#import "NSURLSession+TwitchAdBlock.h"
#import "TWAdBlockAssetResourceLoaderDelegate.h"
#import "fishhook/fishhook.h"

@interface _TtC6Twitch27AssetResourceLoaderDelegate : NSObject <AVAssetResourceLoaderDelegate>
- (BOOL)handleLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest;
@end