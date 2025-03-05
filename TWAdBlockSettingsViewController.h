#import <Twitch/SettingsSwitchTableViewCell.h>
#import <Twitch/VersionLabel.h>
#import <TwitchCoreUI/TWBaseTableViewController.h>
#import "Config.h"
#import "TWAdBlockSettingsTextFieldTableViewCell.h"

@interface TWAdBlockSettingsViewController
    : TWBaseTableViewController <SettingsSwitchTableViewCellDelegate, UITextFieldDelegate>
@property(nonatomic, assign) BOOL adblockEnabled;
@property(nonatomic, assign) BOOL proxyEnabled;
@property(nonatomic, assign) BOOL customProxyEnabled;
@end
