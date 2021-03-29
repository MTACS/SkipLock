TARGET = iphone:clang:13.0:13.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SkipLock

SkipLock_FILES = Tweak.xm
SkipLock_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += skiplockprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
