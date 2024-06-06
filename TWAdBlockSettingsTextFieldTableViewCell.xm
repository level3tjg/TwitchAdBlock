#import "TWAdBlockSettingsTextFieldTableViewCell.h"

%subclass TWAdBlockSettingsTextFieldTableViewCell : BaseTableViewCell
%property(nonatomic, strong) TWAdBlockSettingsTextField *textField;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  if ((self = %orig)) {
    self.textField = [[objc_getClass("TWAdBlockSettingsTextField") alloc]
        initWithFrame:self.frame
         themeManager:[objc_getClass("_TtC12TwitchCoreUI21TWDefaultThemeManager")
                          defaultThemeManager]];
    UITextField *textField = MSHookIvar<UITextField *>(self.textField, "textField");
    textField.returnKeyType = UIReturnKeyDone;
    [self addSubview:self.textField];
  }
  return self;
}
- (void)layoutSubviews {
  %orig;
  self.textField.frame = self.bounds;
  self.textField.layer.cornerRadius = self.layer.cornerRadius;
}
%end

%ctor {
  %init(BaseTableViewCell =
                       objc_getClass("TWBaseTableViewCell")
                           ?: objc_getClass("_TtC12TwitchCoreUI17BaseTableViewCell"));
}
