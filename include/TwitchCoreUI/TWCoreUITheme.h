#import <UIKit/UIKit.h>

@protocol TWCoreUITheme <NSObject>
@required
@property(nonatomic, strong, readonly) UIColor *backgroundAccentColor;
@property(nonatomic, strong, readonly) UIColor *backgroundBodyColor;
@property(nonatomic, strong, readonly) UIColor *backgroundInputColor;
@end
