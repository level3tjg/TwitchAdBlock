#import "TWAdBlockSettingsTextField.h"

%subclass TWAdBlockSettingsTextField : _TtC12TwitchCoreUI17StandardTextField
%new
- (id<UITextFieldDelegate>)delegate {
  return object_getIvar(self, class_getInstanceVariable(object_getClass(self), "delegate"));
}
%new
- (void)setDelegate:(id<UITextFieldDelegate>)delegate {
  object_setIvar(self, class_getInstanceVariable(object_getClass(self), "delegate"), delegate);
}
%new
- (UITextField *)textField {
  return object_getIvar(self, class_getInstanceVariable(object_getClass(self), "textField"));
}
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  if (![self.delegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]) return YES;
  return [self.delegate textFieldShouldBeginEditing:textField];
}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
  if ([self.delegate respondsToSelector:@selector(textFieldDidBeginEditing:)])
    [self textFieldDidBeginEditing:textField];
  self.backgroundColor = self.lastConfiguredTheme.backgroundBodyColor;
  self.layer.borderColor = self.lastConfiguredTheme.backgroundAccentColor.CGColor;
  self.layer.borderWidth = 2;
}
- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
                replacementString:(NSString *)string {
  if (![self.delegate respondsToSelector:@selector(textField:
                                             shouldChangeCharactersInRange:replacementString:)])
    return YES;
  return [self.delegate textField:textField
      shouldChangeCharactersInRange:range
                  replacementString:string];
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
  if (![self.delegate respondsToSelector:@selector(textFieldShouldEndEditing:)]) return YES;
  return [self.delegate textFieldShouldEndEditing:textField];
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
  if ([self.delegate respondsToSelector:@selector(textFieldDidEndEditing:)])
    [self.delegate textFieldDidEndEditing:textField];
  self.backgroundColor = self.lastConfiguredTheme.backgroundInputColor;
  self.layer.borderWidth = 0;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (![self.delegate respondsToSelector:@selector(textFieldShouldReturn:)])
    return [textField resignFirstResponder];
  return [self.delegate textFieldShouldReturn:textField];
}
- (void)textFieldEditingChanged {
}
- (instancetype)initWithFrame:(CGRect)frame
                 themeManager:(_TtC12TwitchCoreUI21TWDefaultThemeManager *)themeManager {
  Class originalClass = object_setClass(self, UIView.class);
  if ((self = [self initWithFrame:frame])) {
    object_setClass(self, originalClass);
    self.themeManager = themeManager;
    self.applyShadowPathForElevation = YES;
    UITextField *textField = [[objc_getClass("_TtC12TwitchCoreUI13BaseTextField") alloc] init];
    object_setIvar(self, class_getInstanceVariable(object_getClass(self), "textField"), textField);
    textField.borderStyle = UITextBorderStyleNone;
    textField.spellCheckingType = UITextSpellCheckingTypeNo;
    textField.returnKeyType = UIReturnKeyGo;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.font = UIFont.twitchBody;
    textField.enablesReturnKeyAutomatically = YES;
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.delegate = self;
    [textField addTarget:self
                  action:@selector(textFieldEditingChanged)
        forControlEvents:UIControlEventEditingChanged];
    [self addSubview:textField];
    CGFloat inputPadding = textField.intrinsicContentSize.width * 2;
    NSArray<NSLayoutConstraint *> *textFieldConstraints = @[
      [self.leftAnchor constraintEqualToAnchor:textField.leftAnchor constant:-inputPadding],
      [self.rightAnchor constraintEqualToAnchor:textField.rightAnchor constant:inputPadding],
      [self.topAnchor constraintEqualToAnchor:textField.topAnchor],
      [self.bottomAnchor constraintEqualToAnchor:textField.bottomAnchor],
    ];
    [NSLayoutConstraint activateConstraints:textFieldConstraints];
  }
  return self;
}
- (void)dealloc {
  self.themeManager = nil;
  object_setClass(self, UIView.class);
  %orig;
}
%end
