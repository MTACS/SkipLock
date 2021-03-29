#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#define domainString @"com.mtac.skiplock"
#define notificationString @"com.mtac.skiplock/preferences.changed"

@interface SBLockScreenManager
+ (id)sharedInstance;
- (BOOL)unlockUIFromSource:(int)arg1 withOptions:(id)arg2;
@end

@interface SBBacklightController: NSObject
- (void)turnOnScreenFullyWithBacklightSource:(long long)arg1;
- (void)unlock;
@end

@interface NSUserDefaults (SkipLock)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

@interface SBMediaController: NSObject
+ (id)sharedInstance;
- (BOOL)isPlaying;
@end

@interface SpringBoard: UIApplication
+ (id)sharedApplication;
@end

static BOOL enabled;

static BOOL disableWithMedia;
static BOOL disableWithLPM;
static BOOL disableWithNotifs;
static BOOL disableWithDND;

static BOOL disableForAlerts;
static BOOL disableForDND;

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
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

%group SkipLock
%hook SBBacklightController
- (void)turnOnScreenFullyWithBacklightSource:(long long)arg1 {
	%orig;
	if (enabled) {
		[self unlock];
	}
}
%new
- (void)unlock {
	if ((disableWithMedia && [[%c(SBMediaController) sharedInstance] isPlaying]) 
	|| (disableWithLPM && [[NSProcessInfo processInfo] isLowPowerModeEnabled]) 
	|| (disableWithNotifs && disableForAlerts) 
	|| (disableWithDND && disableForDND)) {
		NSLog(@"[+] SKIPLOCK DEBUG: Media playing ⏎");
		return;
	} else {
		NSLog(@"[+] SKIPLOCK DEBUG: Unlocking ⏎");
		[[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:2 withOptions:nil];
	}
}
%end
%end

%group SkipLockInit
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
	%init(SkipLock);
	%init(SkipLockInit);
}