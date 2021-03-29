#import <UIKit/UIKit.h>
#import <sys/utsname.h>

#define domainString @"com.mtac.skiplock" // set domain string
#define notificationString @"com.mtac.skiplock/preferences.changed" // set prefs callback string, must equal PostNotification key

@interface SBLockScreenManager
+ (id)sharedInstance;
- (BOOL)unlockUIFromSource:(int)arg1 withOptions:(id)arg2; // Actual method to unlock
@end

@interface SBBacklightController: NSObject
- (void)turnOnScreenFullyWithBacklightSource:(long long)arg1; // Called when display is woken from sleep, raise to wake, tap or power/home button
- (void)unlock; // Add our method to unlock inside SBBacklightController
@end

@interface NSUserDefaults (SkipLock) // Category for our NSUserDefaults prefs
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain; // get prefs value
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain; // set prefs value
@end

@interface SBMediaController: NSObject
+ (id)sharedInstance; 
- (BOOL)isPlaying; // check if media is playing
@end

@interface SpringBoard: UIApplication
+ (id)sharedApplication;
@end

static BOOL enabled; // Main killswitch

static BOOL disableWithMedia; // Disable with media
static BOOL disableWithLPM; // Disable with LPM
static BOOL disableWithNotifs; // Disable if new notifications
static BOOL disableWithDND; // Disable if DND active

static BOOL disableForAlerts; 
static BOOL disableForDND;

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) { // prefs callback
	NSNumber *enabledValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:domainString];
	enabled = (enabledValue) ? [enabledValue boolValue] : NO;
	NSNumber *disableWithMediaValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"disableWithMedia" inDomain:domainString];
	disableWithMedia = (disableWithMediaValue) ? [disableWithMediaValue boolValue] : NO;
	NSNumber *disableWithLPMValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"disableWithLPM" inDomain:domainString];
	disableWithLPM = (disableWithLPMValue) ? [disableWithLPMValue boolValue] : NO;
	NSNumber *disableWithNotifsValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"disableWithNotifs" inDomain:domainString];
	disableWithNotifs = (disableWithNotifsValue) ? [disableWithNotifsValue boolValue] : NO;
	NSNumber *disableWithDNDValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"disableWithDND" inDomain:domainString];
	disableWithDND = (disableWithDNDValue) ? [disableWithDNDValue boolValue] : NO;
}

%group SkipLock // Main group 
%hook SBBacklightController // hook screen wake
- (void)turnOnScreenFullyWithBacklightSource:(long long)arg1 {
	%orig;
	if (enabled) { // check enabled here
		[self unlock]; // call new unlock method
	}
}
%new
- (void)unlock {
	if ((disableWithMedia && [[%c(SBMediaController) sharedInstance] isPlaying]) 
	|| (disableWithLPM && [[NSProcessInfo processInfo] isLowPowerModeEnabled]) 
	|| (disableWithNotifs && disableForAlerts) 
	|| (disableWithDND && disableForDND)) { // check prefs conditions
		NSLog(@"[+] SKIPLOCK DEBUG: Media playing ⏎"); 
		return;
	} else {
		NSLog(@"[+] SKIPLOCK DEBUG: Unlocking ⏎");
		[[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:2 withOptions:nil]; // Unlock UI
	}
}
%end
%end

%group SkipLockInit // Get Do Not Disturb and check if new notifications are present
%hook NCNotificationMasterList
- (unsigned long long)notificationCount {
	if (disableWithNotifs) {
		if (%orig > 0) {
			disableForAlerts = YES;
		} else {
			disableForAlerts = NO;
		}
	}
	return %orig;
}
%end
%hook DNDState
- (BOOL)isActive {
    if (%orig == YES) {
		disableForDND = YES;
	} else {
		disableForDND = NO;
	}
    return %orig;
}
%end
%end

%ctor {
	notificationCallback(NULL, NULL, NULL, NULL, NULL);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, (CFStringRef)notificationString, NULL, CFNotificationSuspensionBehaviorCoalesce);
	%init(SkipLock); // Init tweak
	%init(SkipLockInit); // Init getter group
}