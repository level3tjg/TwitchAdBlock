#import "Settings.h"

extern "C" NSUserDefaults *tweakDefaults;

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
