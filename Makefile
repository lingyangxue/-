TARGET := iphone:clang:latest:14.0
ARCHS  := arm64

TWEAK_NAME = WCRClown
WCRClown_FILES = WCRClownRuntime.m WCRClownSettingsController.m Tweak.xm
WCRClown_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
