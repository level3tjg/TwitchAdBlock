#import <TwitchCoreUI/TWBaseTableViewCell.h>

@protocol SettingsSwitchTableViewCellDelegate <NSObject>
- (void)settingsCellSwitchToggled:(id)sender;
@end

@interface _TtC6Twitch27SettingsSwitchTableViewCell : TWBaseTableViewCell
@property BOOL isOn;
@property id<SettingsSwitchTableViewCellDelegate> delegate;
- (void)configureWithTitle:(NSString *)title
                   subtitle:(NSString *)subtitle
                  isEnabled:(BOOL)isEnabled
                       isOn:(BOOL)isOn
    accessibilityIdentifier:(NSString *)accessibilityIdentifier;
@end