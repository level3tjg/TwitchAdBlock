#import <UIKit/UIKit.h>
#import <substrate.h>

@interface _TtC6Twitch27SettingsSwitchTableViewCell : UITableViewCell
@property BOOL isOn;
@property id delegate;
- (void)configureWithTitle:(NSString *)title
                   subtitle:(NSString *)subtitle
                  isEnabled:(BOOL)isEnabled
                       isOn:(BOOL)isOn
    accessibilityIdentifier:(NSString *)accessibilityIdentifier;
@end

@interface TWBaseTableViewController
    : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property UITableView *tableView;
@end

@interface _TtC6Twitch32PreferenceSettingsViewController
    : TWBaseTableViewController
@end

NSIndexPath *selectedIndexPath;

%hook _TtC6Twitch32PreferenceSettingsViewController
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return %orig + 1;
}
- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  if (section == [self numberOfSectionsInTableView:tableView] - 1)
    return 1;
  return %orig;
}
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell;
  if ([indexPath isMemberOfClass:NSIndexPath.class] &&
      indexPath.section == [self numberOfSectionsInTableView:tableView] - 1 &&
      indexPath.row == 0) {
    cell = [[%c(_TtC6Twitch27SettingsSwitchTableViewCell) alloc]
          initWithStyle:UITableViewCellStyleDefault
        reuseIdentifier:@"AdBlockSwitchCell"];
    [(_TtC6Twitch27SettingsSwitchTableViewCell *)cell
             configureWithTitle:@"Ad Block"
                       subtitle:nil
                      isEnabled:YES
                           isOn:[[NSUserDefaults standardUserDefaults]
                                    boolForKey:@"TWAdBlockEnabled"]
        accessibilityIdentifier:@"AdBlockSwitchCell"];
    [(_TtC6Twitch27SettingsSwitchTableViewCell *)cell setDelegate:self];
  } else {
    cell = %orig;
  }
  return cell;
}
- (NSString *)tableView:(UITableView *)tableView
    titleForFooterInSection:(NSInteger)section {
  if (section == [self numberOfSectionsInTableView:tableView] - 1)
    return @"Choose whether you want to block ads or not. Requires app "
           @"restart";
  return %orig;
}
- (void)settingsCellSwitchToggled:
    (_TtC6Twitch27SettingsSwitchTableViewCell *)sender {
  if ([sender.accessibilityIdentifier isEqualToString:@"AdBlockSwitchCell"]) {
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn
                                            forKey:@"TWAdBlockEnabled"];
  } else {
    %orig;
  }
}
%end

%hook _TtC6Twitch27SettingsSwitchTableViewCell
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  if (CGRectContainsPoint(self.contentView.bounds, point))
    return nil;
  return %orig;
}
%end

%hook _TtC6Twitch19TheaterAdController
- (void)theaterWasPresented:(NSNotification *)notification {
  %orig;
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TWAdBlockEnabled"]) {
    const char *ivars[] = {
        "displayAdController",
        "videoAdController",
        "vastAdController",
    };
    for (int i = 0; i < sizeof(ivars) / sizeof(const char *); i++) {
      if (class_getInstanceVariable(object_getClass(self), ivars[i])) {
        MSHookIvar<id>(self, ivars[i]) = NULL;
      }
    }
  }
}
%end

%ctor {
  if (![[NSUserDefaults standardUserDefaults] objectForKey:@"TWAdBlockEnabled"])
    [[NSUserDefaults standardUserDefaults] setBool:YES
                                            forKey:@"TWAdBlockEnabled"];
}
