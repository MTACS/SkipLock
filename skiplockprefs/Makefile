TARGET = iphone:clang:13.0:13.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SkipLockPrefs

SkipLockPrefs_FILES = SkipLockController.mm
SkipLockPrefs_FRAMEWORKS = UIKit LocalAuthentication
SkipLockPrefs_PRIVATE_FRAMEWORKS = Preferences
SkipLockPrefs_INSTALL_PATH = /Library/PreferenceBundles
SkipLockPrefs_CFLAGS = -fobjc-arc -Wdeprecated-declarations -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/bundle.mk
