#include "SkipLockController.h"
@import SafariServices; // In app browser
@interface BSAction : NSObject
@end
@interface SBSRelaunchAction : BSAction
+ (id)actionWithReason:(id)arg1 options:(unsigned long long)arg2 targetURL:(id)arg3;
@end

@interface FBSSystemService : NSObject
+ (id)sharedService;
- (void)sendActions:(id)arg1 withResult:(id)arg2;
@end

@interface SLTintedCell ()
@end 

@interface SLSwitchTableCell ()
@end 

UIImageView *secondaryHeaderImage; // fancy animations

@implementation SkipLockController
- (void)viewDidLoad {
	[super viewDidLoad];
	self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,200,200)];
	self.headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,200,200)];
    self.headerImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.headerImageView.image = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/SkipLockPrefs.bundle/locked.png"]; // load header image
    self.headerImageView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.headerView addSubview:self.headerImageView];
    [NSLayoutConstraint activateConstraints:@[
        [self.headerImageView.topAnchor constraintEqualToAnchor:self.headerView.topAnchor],
        [self.headerImageView.leadingAnchor constraintEqualToAnchor:self.headerView.leadingAnchor],
        [self.headerImageView.trailingAnchor constraintEqualToAnchor:self.headerView.trailingAnchor],
        [self.headerImageView.bottomAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
    ]];
	_table.tableHeaderView = self.headerView;
	[self playUnlock];
	[self checkEligibility];
}
- (void)playUnlock {
	secondaryHeaderImage = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,200,200)];
	secondaryHeaderImage.contentMode = UIViewContentModeScaleAspectFit;
	secondaryHeaderImage.image = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/SkipLockPrefs.bundle/unlocked.png"];
	secondaryHeaderImage.translatesAutoresizingMaskIntoConstraints = NO;
	secondaryHeaderImage.alpha = 0.0;
	[self.headerView addSubview:secondaryHeaderImage];

	[NSLayoutConstraint activateConstraints:@[
		[secondaryHeaderImage.topAnchor constraintEqualToAnchor:self.headerView.topAnchor],
		[secondaryHeaderImage.leadingAnchor constraintEqualToAnchor:self.headerView.leadingAnchor],
		[secondaryHeaderImage.trailingAnchor constraintEqualToAnchor:self.headerView.trailingAnchor],
		[secondaryHeaderImage.bottomAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
	]];

	[UIView animateWithDuration:0.5 animations:^ {
		secondaryHeaderImage.alpha = 1.0;
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:1.0 animations:^ {
			self.headerImageView.alpha = 0.0;
		} completion:nil];
	}];
}
- (void)checkEligibility {
	LAContext *context = [LAContext new];
	NSError *error = nil;
	if ([context canEvaluatePolicy:kLAPolicyDeviceOwnerAuthentication error:&error] && ![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.mtac.skiplock.plist"]) { // Check if device has passcode or biometric security
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"SkipLock is best used on devices without security (TouchID, FaceID, Passcode), but will function on all models." preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {}];
		[alert addAction:dismiss];
    	[self presentViewController:alert animated:YES completion:nil];
	}
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    if (offsetY > 0) offsetY = 0;
    self.headerImageView.frame = CGRectMake(0, offsetY, self.headerView.frame.size.width, 200 - offsetY);
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	tableView.tableHeaderView = self.headerView;
	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}
- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	return _specifiers;
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if ([self.view respondsToSelector:@selector(setTintColor:)]) {
		[UIApplication sharedApplication].keyWindow.tintColor = TINT_COLOR;
	}
}
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if ([self.view respondsToSelector:@selector(setTintColor:)]) {
		[UIApplication sharedApplication].keyWindow.tintColor = [UIColor systemBlueColor];
	}
}
- (void)source { // SafariServices presents in app browser
	[[NSBundle bundleWithPath:@"/System/Library/Frameworks/SafariServices.framework"] load];
	if ([SFSafariViewController class] != nil) {
		SFSafariViewController *safariView = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"https://github.com/MTACS/SkipLock"]];
		if ([safariView respondsToSelector:@selector(setPreferredControlTintColor:)]) {
			safariView.preferredControlTintColor = TINT_COLOR;
		}
		[self.navigationController presentViewController:safariView animated:YES completion:nil];
	} else {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/MTACS/SkipLock"]];
	}
}
@end

@implementation SLSwitchTableCell // Subclassed tinted switch cell
- (id)initWithStyle:(int)style reuseIdentifier:(id)identifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier];
	if (self) {
		[((UISwitch *)[self control]) setOnTintColor:TINT_COLOR];
		self.detailTextLabel.text = specifier.properties[@"subtitle"] ?: @"";
		self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
	}
	return self;
}
@end

@implementation SLTintedCell // Subclassed tinted cell
- (id)initWithSpecifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell" specifier:specifier];;
	return self;
}
- (void)tintColorDidChange {
	[super tintColorDidChange];
	self.textLabel.textColor = TINT_COLOR;
	self.textLabel.highlightedTextColor = TINT_COLOR;
}
- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];
	if ([self respondsToSelector:@selector(tintColor)]) {
		self.textLabel.textColor = TINT_COLOR;
		self.textLabel.highlightedTextColor = TINT_COLOR;
	}
	if (!self.accessoryView) {
		UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
		[iconView setImage:[UIImage systemImageNamed:@"safari.fill"]];
		self.accessoryView = iconView;
	}
}
@end