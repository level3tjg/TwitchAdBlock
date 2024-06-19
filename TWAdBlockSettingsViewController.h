#import <Twitch/SettingsSwitchTableViewCell.h>
#import <TwitchCoreUI/TWBaseTableViewController.h>
#import "TWAdBlockSettingsTextFieldTableViewCell.h"

@interface TWAdBlockSettingsViewController
    : TWBaseTableViewController <SettingsSwitchTableViewCellDelegate, UITextFieldDelegate>
@property(nonatomic, assign) BOOL adblock;
@property(nonatomic, assign) BOOL notify;
@property(nonatomic, assign) BOOL proxy;
@property(nonatomic, assign) BOOL customProxy;
@end
