#import "Settings.h"

%hook _TtC6Twitch25AppSettingsViewController
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
    return [self.navigationController
        pushViewController:
            [[objc_getClass("TWAdBlockSettingsViewController") alloc]
                initWithTableViewStyle:2
                          themeManager:[objc_getClass("_TtC12TwitchCoreUI21TWDefaultThemeManager")
                                           defaultThemeManager]]
                  animated:YES];
  %orig;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return %orig + 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1) {
    _TtC6Twitch22SettingsDisclosureCell *cell =
        [[objc_getClass("_TtC6Twitch22SettingsDisclosureCell") alloc]
              initWithStyle:UITableViewCellStyleSubtitle
            reuseIdentifier:@"Twitch.SettingsDisclosureCell"];
    cell.textLabel.text = @"TwitchAdBlock";
    return cell;
  }
  return %orig;
}
%end

%ctor {
  NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
  if (![userDefaults objectForKey:@"TWAdBlockEnabled"])
    [userDefaults setBool:YES forKey:@"TWAdBlockEnabled"];
  if (![userDefaults objectForKey:@"TWAdBlockProxy"])
    [userDefaults setObject:PROXY_URL forKey:@"TWAdBlockProxy"];
  if (![userDefaults objectForKey:@"TWAdBlockProxyEnabled"])
    [userDefaults setBool:NO forKey:@"TWAdBlockProxyEnabled"];
  if (![userDefaults objectForKey:@"TWAdBlockCustomProxyEnabled"])
    [userDefaults setBool:NO forKey:@"TWAdBlockCustomProxyEnabled"];
}
