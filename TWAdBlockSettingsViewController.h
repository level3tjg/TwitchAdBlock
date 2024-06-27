#import <Twitch/SettingsSwitchTableViewCell.h>
#import <TwitchCoreUI/TWBaseTableViewController.h>
#import <notify.h>
#import "TWAdBlockSettingsTextFieldTableViewCell.h"

@interface TWAdBlockSettingsViewController
    : TWBaseTableViewController <SettingsSwitchTableViewCellDelegate, UITextFieldDelegate>
@property(nonatomic, assign) BOOL adblockEnabled;
@property(nonatomic, assign) BOOL proxyEnabled;
@property(nonatomic, assign) BOOL customProxyEnabled;
@end
