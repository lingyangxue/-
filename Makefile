ARCHS = arm64e
TARGET = iphone:clang:latest:17.0

INSTALL_TARGET_PROCESSES = WeChat

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WCClown

WCClown_FILES = Tweak.xm ClownCore.mm
WCClown_CFLAGS = -fobjc-arc

WCClown_FRAMEWORKS = UIKit Foundation CoreGraphics

WCClown_PRIVATE_FRAMEWORKS =

include $(THEOS_MAKE_PATH)/tweak.mk
