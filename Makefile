TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WeChatMod
WeChatMod_FILES = WeChatMod.xm
WeChatMod_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
WeChatMod_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
