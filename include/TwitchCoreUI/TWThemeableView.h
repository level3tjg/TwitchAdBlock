#import <UIKit/UIKit.h>
#import "TWCoreUITheme.h"

@interface TWThemeableView : UIView
@property BOOL applyShadowPathForElevation;
@property id<TWCoreUITheme> lastConfiguredTheme;
@property _TtC12TwitchCoreUI21TWDefaultThemeManager *themeManager;
- (instancetype)initWithFrame:(CGRect)frame themeManager:(_TtC12TwitchCoreUI21TWDefaultThemeManager *)themeManager;
@end