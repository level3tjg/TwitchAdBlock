@interface TWBaseTableViewController
    : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property UITableView *tableView;
- (instancetype)initWithTableViewStyle:(NSInteger)style
                          themeManager:
                              (_TtC12TwitchCoreUI21TWDefaultThemeManager *)
                                  themeManager;
@end