#import "Header.h"
#import <substrate.h>

@interface UIFont (TwitchCoreUI)
@property(class) UIFont *twitchBody;
@end

@protocol TWCoreUITheme <NSObject>
@required
@property(nonatomic, strong, readonly) UIColor *backgroundAccentColor;
@property(nonatomic, strong, readonly) UIColor *backgroundBodyColor;
@property(nonatomic, strong, readonly) UIColor *backgroundInputColor;
@end

@interface TWThemeableView : UIView
@property BOOL applyShadowPathForElevation;
@property id<TWCoreUITheme> lastConfiguredTheme;
@property _TtC12TwitchCoreUI21TWDefaultThemeManager *themeManager;
- (instancetype)initWithFrame:(CGRect)frame
                 themeManager:
                     (_TtC12TwitchCoreUI21TWDefaultThemeManager *)themeManager;
@end

@interface _TtC12TwitchCoreUI17StandardTextField
    : TWThemeableView <UITextFieldDelegate>
@end

@interface TWAdBlockProxyTextField : _TtC12TwitchCoreUI17StandardTextField
@end

@interface TWThemeableTableViewCell : UITableViewCell
@end

@interface TWBaseTableViewCell : TWThemeableTableViewCell
@end

@interface TWAdBlockProxyTextFieldTableViewCell : TWBaseTableViewCell
@property(nonatomic, strong) TWAdBlockProxyTextField *proxyTextField;
@end

@interface _TtC6Twitch27SettingsSwitchTableViewCell : UITableViewCell
@property BOOL isOn;
@property id delegate;
- (void)configureWithTitle:(NSString *)title
                   subtitle:(NSString *)subtitle
                  isEnabled:(BOOL)isEnabled
                       isOn:(BOOL)isOn
    accessibilityIdentifier:(NSString *)accessibilityIdentifier;
@end

@interface TWBaseTableViewController
    : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property UITableView *tableView;
- (instancetype)initWithTableViewStyle:(NSInteger)style
                          themeManager:(id)themeManager;
@end

@interface _TtC6Twitch32PreferenceSettingsViewController
    : TWBaseTableViewController
@end

@interface _TtC6Twitch22SettingsDisclosureCell : TWBaseTableViewCell
@end

@interface _TtC6Twitch25AppSettingsViewController : TWBaseTableViewController
@end

@interface TwitchAdBlockSettingsViewController : TWBaseTableViewController
@property(nonatomic, assign) BOOL adblock;
@property(nonatomic, assign) BOOL notify;
@property(nonatomic, assign) BOOL proxy;
@property(nonatomic, assign) BOOL customProxy;
@end