#import "Settings.h"

extern NSUserDefaults *tweakDefaults;

%hook _TtC6Twitch25AccountMenuViewController
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == [self numberOfSectionsInTableView:tableView] - 1 &&
      indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1) {
    UITableViewStyle tableViewStyle = UITableViewStyleGrouped;
    if (@available(iOS 13, *)) tableViewStyle = UITableViewStyleInsetGrouped;
    TWAdBlockSettingsViewController *adblockSettingsViewController =
        [[objc_getClass("TWAdBlockSettingsViewController") alloc]
            initWithTableViewStyle:tableViewStyle
                      themeManager:[objc_getClass("_TtC12TwitchCoreUI21TWDefaultThemeManager")
                                       defaultThemeManager]];
    adblockSettingsViewController.tableView.separatorStyle =
        UITableViewCellSeparatorStyleSingleLine;
    return [self.navigationController pushViewController:adblockSettingsViewController

                                                animated:YES];
  }
  %orig;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSInteger numberOfRows = %orig;
  if (section == [self numberOfSectionsInTableView:tableView] - 1) numberOfRows++;
  return numberOfRows;
}
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == [self numberOfSectionsInTableView:tableView] - 1 &&
      indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1) {
    _TtC6Twitch34ConfigurableAccessoryTableViewCell *cell =
        [[objc_getClass("_TtC6Twitch34ConfigurableAccessoryTableViewCell") alloc]
              initWithStyle:UITableViewCellStyleSubtitle
            reuseIdentifier:@"Twitch.ConfigurableAccessoryTableViewCell"];
    [cell configureWithTitle:@"TwitchAdBlock"];
    NSBundle *twCoreUIBundle = [NSBundle bundleWithIdentifier:@"twitch.TwitchCoreUI"];
    cell.accessoryView =
        [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow-forward-Icon"
                                                                    inBundle:twCoreUIBundle
                                               compatibleWithTraitCollection:nil]];
    cell.useDefaultBackgroundColor = YES;
    Ivar customImageViewIvar = class_getInstanceVariable(object_getClass(cell), "customImageView");
    if (!customImageViewIvar) return cell;
    UIImageView *customImageView = object_getIvar(cell, customImageViewIvar);
    customImageView.image = [UIImage imageNamed:@"Un-Host-Icon"
                                       inBundle:twCoreUIBundle
                  compatibleWithTraitCollection:nil];
    customImageView.hidden = NO;
    return cell;
  }
  return %orig;
}
%end
