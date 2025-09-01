#import "Settings.h"

extern NSBundle *tweakBundle;
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
    cell.accessoryView =
        [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"arrow-forward"
                                                                    inBundle:tweakBundle
                                               compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    Ivar customImageViewIvar = class_getInstanceVariable(object_getClass(cell), "customImageView");
    if (!customImageViewIvar) return cell;
    UIImageView *customImageView = object_getIvar(cell, customImageViewIvar);
    customImageView.image = [[UIImage imageNamed:@"twab-icon"
                                       inBundle:tweakBundle
                  compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    customImageView.hidden = NO;

    if ([cell respondsToSelector:@selector(useDefaultBackgroundColor)]) {
      cell.useDefaultBackgroundColor = YES;
    } else {
      Ivar ivar = class_getInstanceVariable(object_getClass(cell), "useDefaultBackgroundColor");
      if (ivar) {
          ptrdiff_t offset = ivar_getOffset(ivar);
          uint8_t *bytes = (uint8_t *)(__bridge void *)cell;
          *((BOOL *)(bytes + offset)) = YES;
      }
    }
    return cell;
  }
  return %orig;
}
%end
