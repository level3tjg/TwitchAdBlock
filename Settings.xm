#import "Settings.h"

// clang-format off
%subclass TwitchAdBlockSettingsViewController : TWBaseTableViewController
%property (nonatomic, assign) BOOL adblock;
%property (nonatomic, assign) BOOL proxy;
%property (nonatomic, assign) BOOL customProxy;
// clang-format on
- (void)viewDidLoad {
  %orig;
  self.title = @"TwitchAdBlock";
  self.tableView.contentInsetAdjustmentBehavior =
      UIScrollViewContentInsetAdjustmentNever;
  self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
  [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc]
                                      initWithTarget:self.view
                                              action:@selector(endEditing:)]];
}
%new
- (void)settingsCellSwitchToggled:(UISwitch *)sender {
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  if ([sender.accessibilityIdentifier isEqualToString:@"AdBlockSwitchCell"]) {
    [userDefaults setBool:sender.isOn forKey:@"TWAdBlockEnabled"];
    self.adblock = sender.isOn;

    NSIndexSet *sections = [NSIndexSet indexSetWithIndex:1];
    if (sender.isOn) {
      [self.tableView insertSections:sections
                    withRowAnimation:UITableViewRowAnimationFade];
    } else {
      [self.tableView deleteSections:sections
                    withRowAnimation:UITableViewRowAnimationFade];
      [userDefaults setBool:NO forKey:@"TWAdBlockProxyEnabled"];
      [userDefaults setBool:NO forKey:@"TWAdBlockCustomProxyEnabled"];
      self.proxy = NO;
      self.customProxy = NO;
    }

  } else if ([sender.accessibilityIdentifier
                 isEqualToString:@"AdBlockProxySwitchCell"]) {
    [userDefaults setBool:sender.isOn forKey:@"TWAdBlockProxyEnabled"];
    self.proxy = sender.isOn;

    NSMutableArray *indexPaths = [NSMutableArray array];
    [indexPaths addObject:[NSIndexPath indexPathForRow:1 inSection:1]];
    if (self.customProxy)
      [indexPaths addObject:[NSIndexPath indexPathForRow:2 inSection:1]];
    if (sender.isOn) {
      [self.tableView insertRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationFade];
    } else {
      [self.tableView deleteRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationFade];
      if (self.customProxy) {
        [userDefaults setBool:NO forKey:@"TWAdBlockCustomProxyEnabled"];
        self.customProxy = NO;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                      withRowAnimation:UITableViewRowAnimationFade];
      }
    }

  } else if ([sender.accessibilityIdentifier
                 isEqualToString:@"AdBlockCustomProxySwitchCell"]) {
    [userDefaults setBool:sender.isOn forKey:@"TWAdBlockCustomProxyEnabled"];
    self.customProxy = sender.isOn;

    NSArray *indexPaths = @[ [NSIndexPath indexPathForRow:2 inSection:1] ];
    if (sender.isOn) {
      [self.tableView insertRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationFade];
    } else {
      [self.tableView deleteRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationFade];
    }
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                  withRowAnimation:UITableViewRowAnimationFade];
  }

  [userDefaults synchronize];
}
%new
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return self.adblock ? 2 : 1;
}
- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  if (section == 0)
    return 1;
  return self.proxy ? self.customProxy ? 3 : 2 : 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell;
  switch (indexPath.section) {
  case 0:
    cell = [[NSClassFromString(@"_TtC6Twitch27SettingsSwitchTableViewCell")
        alloc] initWithStyle:UITableViewCellStyleDefault
             reuseIdentifier:@"AdBlockSwitchCell"];
    [(_TtC6Twitch27SettingsSwitchTableViewCell *)cell
             configureWithTitle:@"Ad Block"
                       subtitle:nil
                      isEnabled:YES
                           isOn:[[NSUserDefaults standardUserDefaults]
                                    boolForKey:@"TWAdBlockEnabled"]
        accessibilityIdentifier:@"AdBlockSwitchCell"];
    [(_TtC6Twitch27SettingsSwitchTableViewCell *)cell setDelegate:self];
    break;
  case 1:
    switch (indexPath.row) {
    case 0:
      cell = [[NSClassFromString(@"_TtC6Twitch27SettingsSwitchTableViewCell")
          alloc] initWithStyle:UITableViewCellStyleDefault
               reuseIdentifier:@"AdBlockProxySwitchCell"];
      [(_TtC6Twitch27SettingsSwitchTableViewCell *)cell
               configureWithTitle:@"Ad Block Proxy"
                         subtitle:nil
                        isEnabled:YES
                             isOn:[[NSUserDefaults standardUserDefaults]
                                      boolForKey:@"TWAdBlockProxyEnabled"]
          accessibilityIdentifier:@"AdBlockProxySwitchCell"];
      [(_TtC6Twitch27SettingsSwitchTableViewCell *)cell setDelegate:self];
      break;
    case 1:
      cell = [[NSClassFromString(@"_TtC6Twitch27SettingsSwitchTableViewCell")
          alloc] initWithStyle:UITableViewCellStyleDefault
               reuseIdentifier:@"AdBlockCustomProxySwitchCell"];
      [(_TtC6Twitch27SettingsSwitchTableViewCell *)cell
               configureWithTitle:@"Custom Proxy"
                         subtitle:nil
                        isEnabled:YES
                             isOn:[[NSUserDefaults standardUserDefaults]
                                      boolForKey:@"TWAdBlockCustomProxyEnabled"]
          accessibilityIdentifier:@"AdBlockCustomProxySwitchCell"];
      [(_TtC6Twitch27SettingsSwitchTableViewCell *)cell setDelegate:self];
      break;
    case 2:
      cell = [[NSClassFromString(@"TWAdBlockProxyTextFieldTableViewCell") alloc]
            initWithStyle:tableView.style
          reuseIdentifier:@"TWAdBlockProxy"];
      break;
    }
    break;
  }
  return cell;
}
%new
- (NSString *)tableView:(UITableView *)tableView
    titleForFooterInSection:(NSInteger)section {
  if (section == 0)
    return @"Choose whether you want to block ads or not.";
  return [NSString
      stringWithFormat:
          @"Proxy HLS manifest requests through an external server%@. Only "
          @"works if server side ads are enabled.%@",
          self.customProxy ? @" specified by the URL above" : @"",
          self.customProxy
              ? @"\n\n:channel = Channel name (VOD id for VODs) \n:path = Full "
                @"path + query\n:playlist = :channel.m3u8 + query"
              : @""];
}
- (instancetype)initWithTableViewStyle:(NSInteger)tableViewStyle
                          themeManager:(id)themeManager {
  if ((self = %orig)) {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.adblock = [userDefaults boolForKey:@"TWAdBlockEnabled"];
    self.proxy = [userDefaults boolForKey:@"TWAdBlockProxyEnabled"];
    self.customProxy = [userDefaults boolForKey:@"TWAdBlockCustomProxyEnabled"];
  }
  return self;
}
%end

%hook _TtC6Twitch25AppSettingsViewController
- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row ==
      [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1) {
    [self.navigationController
        pushViewController:
            [[NSClassFromString(@"TwitchAdBlockSettingsViewController") alloc]
                initWithTableViewStyle:2
                          themeManager:
                              [NSClassFromString(
                                  @"_TtC12TwitchCoreUI21TWDefaultThemeManager")
                                  defaultThemeManager]]
                  animated:YES];
    return;
  }
  %orig;
}
- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return %orig + 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row ==
      [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1) {
    _TtC6Twitch22SettingsDisclosureCell *cell =
        [[NSClassFromString(@"_TtC6Twitch22SettingsDisclosureCell") alloc]
              initWithStyle:3
            reuseIdentifier:@"Twitch.SettingsDisclosureCell"];
    cell.textLabel.text = @"TwitchAdBlock";
    return cell;
  }
  return %orig;
}
%end

// clang-format off
%subclass TWAdBlockProxyTextField : _TtC12TwitchCoreUI17StandardTextField
// clang-format on
- (void)textFieldDidBeginEditing:(UITextField *)textField {
  %orig;
  MSHookIvar<BOOL>(self, "isEditing") = YES;
  self.backgroundColor = self.lastConfiguredTheme.backgroundBodyColor;
  self.layer.borderColor =
      self.lastConfiguredTheme.backgroundAccentColor.CGColor;
  self.layer.borderWidth = 2;
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
  %orig;
  MSHookIvar<BOOL>(self, "isEditing") = NO;
  self.backgroundColor = self.lastConfiguredTheme.backgroundInputColor;
  self.layer.borderWidth = 0;
  [[NSUserDefaults standardUserDefaults] setValue:textField.text
                                           forKey:@"TWAdBlockProxy"];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}
%end

// clang-format off
%subclass TWAdBlockProxyTextFieldTableViewCell : TWBaseTableViewCell
%property(nonatomic, strong) TWAdBlockProxyTextField *proxyTextField;
// clang-format on
- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier {
  if ((self = %orig)) {
    self.proxyTextField = [[NSClassFromString(@"TWAdBlockProxyTextField") alloc]
        initWithFrame:self.frame
         themeManager:[NSClassFromString(
                          @"_TtC12TwitchCoreUI21TWDefaultThemeManager")
                          defaultThemeManager]];
    UITextField *textField = self.proxyTextField.subviews[0];
    textField.returnKeyType = UIReturnKeyDone;
    textField.placeholder = PROXY_URL;
    textField.text =
        [[NSUserDefaults standardUserDefaults] objectForKey:@"TWAdBlockProxy"];
    [self addSubview:self.proxyTextField];
  }
  return self;
}
- (void)layoutSubviews {
  %orig;
  self.proxyTextField.frame = self.bounds;
  self.proxyTextField.layer.cornerRadius = self.layer.cornerRadius;
}
%end

%ctor {
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  if (![userDefaults objectForKey:@"TWAdBlockEnabled"])
    [userDefaults setBool:YES forKey:@"TWAdBlockEnabled"];
  if (![userDefaults objectForKey:@"TWAdBlockProxy"])
    [userDefaults setObject:PROXY_URL forKey:@"TWAdBlockProxy"];
  if (![userDefaults objectForKey:@"TWAdBlockProxyEnabled"])
    [userDefaults setBool:YES forKey:@"TWAdBlockProxyEnabled"];
  if (![userDefaults objectForKey:@"TWAdBlockCustomProxyEnabled"])
    [userDefaults setBool:NO forKey:@"TWAdBlockCustomProxyEnabled"];
}
