#import "TWAdBlockSettingsViewController.h"

%subclass TWAdBlockSettingsViewController : TWBaseTableViewController
%property(nonatomic, assign) BOOL adblock;
%property(nonatomic, assign) BOOL proxy;
%property(nonatomic, assign) BOOL customProxy;
- (instancetype)initWithTableViewStyle:(NSInteger)tableViewStyle themeManager:(id)themeManager {
  if ((self = %orig)) {
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    self.adblock = [userDefaults boolForKey:@"TWAdBlockEnabled"];
    self.proxy = [userDefaults boolForKey:@"TWAdBlockProxyEnabled"];
    self.customProxy = [userDefaults boolForKey:@"TWAdBlockCustomProxyEnabled"];
  }
  return self;
}
- (void)viewDidLoad {
  %orig;
  self.title = @"TwitchAdBlock";
  [self.view
      addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.view
                                                                   action:@selector(endEditing:)]];
}
%new
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return self.adblock ? 2 : 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case 0:
      return 1;
    case 1:
      return self.proxy ? self.customProxy ? 3 : 2 : 1;
    default:
      return 0;
  }
}
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell;
  switch (indexPath.section) {
    case 0:
      cell = [[objc_getClass("_TtC6Twitch27SettingsSwitchTableViewCell") alloc]
            initWithStyle:UITableViewCellStyleDefault
          reuseIdentifier:@"AdBlockSwitchCell"];
      [(_TtC6Twitch27SettingsSwitchTableViewCell *)cell
               configureWithTitle:@"Ad Block"
                         subtitle:nil
                        isEnabled:YES
                             isOn:[NSUserDefaults.standardUserDefaults
                                      boolForKey:@"TWAdBlockEnabled"]
          accessibilityIdentifier:@"AdBlockSwitchCell"];
      [(_TtC6Twitch27SettingsSwitchTableViewCell *)cell setDelegate:self];
      return cell;
    case 1:
      switch (indexPath.row) {
        case 0:
          cell = [[objc_getClass("_TtC6Twitch27SettingsSwitchTableViewCell") alloc]
                initWithStyle:UITableViewCellStyleDefault
              reuseIdentifier:@"AdBlockProxySwitchCell"];
          [(_TtC6Twitch27SettingsSwitchTableViewCell *)cell
                   configureWithTitle:@"Ad Block Proxy"
                             subtitle:nil
                            isEnabled:YES
                                 isOn:[NSUserDefaults.standardUserDefaults
                                          boolForKey:@"TWAdBlockProxyEnabled"]
              accessibilityIdentifier:@"AdBlockProxySwitchCell"];
          [(_TtC6Twitch27SettingsSwitchTableViewCell *)cell setDelegate:self];
          return cell;
        case 1:
          cell = [[objc_getClass("_TtC6Twitch27SettingsSwitchTableViewCell") alloc]
                initWithStyle:UITableViewCellStyleDefault
              reuseIdentifier:@"AdBlockCustomProxySwitchCell"];
          [(_TtC6Twitch27SettingsSwitchTableViewCell *)cell
                   configureWithTitle:@"Custom Proxy"
                             subtitle:nil
                            isEnabled:YES
                                 isOn:[NSUserDefaults.standardUserDefaults
                                          boolForKey:@"TWAdBlockCustomProxyEnabled"]
              accessibilityIdentifier:@"AdBlockCustomProxySwitchCell"];
          [(_TtC6Twitch27SettingsSwitchTableViewCell *)cell setDelegate:self];
          return cell;
        case 2:
          cell = [[objc_getClass("TWAdBlockSettingsTextFieldTableViewCell") alloc]
                initWithStyle:UITableViewCellStyleDefault
              reuseIdentifier:@"TWAdBlockProxy"];
          TWAdBlockSettingsTextField *textField = ((TWAdBlockSettingsTextFieldTableViewCell *)cell).textField;
          textField.textField.placeholder = PROXY_URL;
          textField.textField.text = [NSUserDefaults.standardUserDefaults stringForKey:@"TWAdBlockProxy"];
          textField.delegate = self;
          return cell;
      }
    default:
      return nil;
  }
}
%new
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
  switch (section) {
    case 0:
      return @"Choose whether you want to block ads or not.";
    case 1:
      return @"Proxy specific requests through a proxy server based in an ad-free country";
    default:
      return nil;
  }
}
%new
- (void)settingsCellSwitchToggled:(UISwitch *)sender {
  NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
  if ([sender.accessibilityIdentifier isEqualToString:@"AdBlockSwitchCell"]) {
    [userDefaults setBool:sender.isOn forKey:@"TWAdBlockEnabled"];
    self.adblock = sender.isOn;

    NSIndexSet *sections = [NSIndexSet indexSetWithIndex:1];
    if (sender.isOn)
      [self.tableView insertSections:sections withRowAnimation:UITableViewRowAnimationFade];
    else
      [self.tableView deleteSections:sections withRowAnimation:UITableViewRowAnimationFade];
  } else if ([sender.accessibilityIdentifier isEqualToString:@"AdBlockProxySwitchCell"]) {
    [userDefaults setBool:sender.isOn forKey:@"TWAdBlockProxyEnabled"];
    self.proxy = sender.isOn;

    NSMutableArray *indexPaths = [NSMutableArray array];
    [indexPaths addObject:[NSIndexPath indexPathForRow:1 inSection:1]];
    if (self.customProxy) [indexPaths addObject:[NSIndexPath indexPathForRow:2 inSection:1]];
    if (sender.isOn)
      [self.tableView insertRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationFade];
    else
      [self.tableView deleteRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationFade];
  } else if ([sender.accessibilityIdentifier isEqualToString:@"AdBlockCustomProxySwitchCell"]) {
    [userDefaults setBool:sender.isOn forKey:@"TWAdBlockCustomProxyEnabled"];
    self.customProxy = sender.isOn;

    NSArray *indexPaths = @[ [NSIndexPath indexPathForRow:2 inSection:1] ];
    if (sender.isOn)
      [self.tableView insertRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationFade];
    else
      [self.tableView deleteRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationFade];
  }

  [userDefaults synchronize];
}
%new
- (void)textFieldDidEndEditing:(UITextField *)textField {
  [NSUserDefaults.standardUserDefaults setValue:textField.text forKey:@"TWAdBlockProxy"];
}
%end