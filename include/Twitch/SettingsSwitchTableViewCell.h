#import <TwitchCoreUI/TWBaseTableViewCell.h>

@interface _TtC6Twitch27SettingsSwitchTableViewCell : TWBaseTableViewCell
@property BOOL isOn;
@property id delegate;
- (void)configureWithTitle:(NSString *)title
                   subtitle:(NSString *)subtitle
                  isEnabled:(BOOL)isEnabled
                       isOn:(BOOL)isOn
    accessibilityIdentifier:(NSString *)accessibilityIdentifier;
@end