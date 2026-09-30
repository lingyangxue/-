ARCHS = arm64e
TARGET = iphone:clang:latest:17.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = WCClown

WCClown_FILES = \
Tweak.xm \
ClownCore.mm \
ClownPrefs.mm

WCClown_CFLAGS = \
-fobjc-arc \
-Wno-deprecated-declarations \
-Wno-unused-variable \
-Wno-unused-function

WCClown_FRAMEWORKS = \
UIKit \
Foundation \
CoreGraphics

WCClown_LDFLAGS = \
-Wl,-no_warn_duplicate_libraries \
-Wl,-not_for_dyld_shared_cache

include $(THEOS_MAKE_PATH)/library.mk
