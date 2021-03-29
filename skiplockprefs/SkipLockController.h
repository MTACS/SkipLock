#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import <LocalAuthentication/LocalAuthentication.h>

#define TINT_COLOR [UIColor colorWithRed: 1.00 green: 0.34 blue: 0.13 alpha: 1.00]

@interface UIView (SkipLock)
- (id)_viewControllerForAncestor;
@end

@interface SkipLockController : PSListController {
    UITableView * _table;
}
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *headerImageView;
@end

@interface PSControlTableCell : PSTableCell
- (UIControl *)control;
@end

@interface PSSwitchTableCell : PSControlTableCell
- (id)initWithStyle:(int)style reuseIdentifier:(id)identifier specifier:(id)specifier;
- (void)controlChanged:(id)arg1;
@end

@interface SLSwitchTableCell : PSSwitchTableCell
@end

@interface NSUserDefaults (SkipLock)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

@interface PSSpecifier : NSObject
- (id)properties;
@end

@interface SLTintedCell: PSTableCell
@end