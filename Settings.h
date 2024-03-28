#import "Header.h"
#import <Twitch/AppSettingsViewController.h>
#import <Twitch/SettingsDisclosureCell.h>
#import <Twitch/SettingsSwitchTableViewCell.h>
#import <TwitchCoreUI/StandardTextField.h>
#import <TwitchCoreUI/TWBaseTableViewCell.h>
#import <TwitchCoreUI/TWBaseTableViewController.h>
#import <TwitchCoreUI/UIFont+TwitchCoreUI.h>

@interface TWAdBlockSettingsTextField : _TtC12TwitchCoreUI17StandardTextField
@property(nonatomic, weak) id<UITextFieldDelegate> delegate;
@end

@interface TWAdBlockSettingsTextFieldTableViewCell : TWBaseTableViewCell
@property(nonatomic, strong) TWAdBlockSettingsTextField *textField;
@end

@interface TWAdBlockSettingsViewController
    : TWBaseTableViewController <UITextFieldDelegate>
@property(nonatomic, assign) BOOL adblock;
@property(nonatomic, assign) BOOL notify;
@property(nonatomic, assign) BOOL proxy;
@property(nonatomic, assign) BOOL customProxy;
@end