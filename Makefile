TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = WeChat
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = JokerFix
JokerFix_FILES = JokerFix.mm
JokerFix_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
