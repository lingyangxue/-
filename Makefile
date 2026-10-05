TARGET := iphone:clang:latest:14.0
ARCHS  := arm64

TWEAK_NAME = WCRClown

# ⚠️ 如果你把工程改名(比如改成 WCCLown),下面这行前缀必须一起改,
#    三处必须完全一致:TWEAK_NAME / _FILES / _CFLAGS / _FRAMEWORKS 的前缀。
WCRClown_FILES = WCRClownRuntime.m WCRClownSettingsController.m Tweak.xm

WCRClown_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
WCRClown_FRAMEWORKS = UIKit Foundation

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

# 装到设备后,自己手动重启一次微信让插件生效(macOS/Linux 上 make install 时:
# 重启微信命令 = /usr/bin/killall -9 WeChat ,这里不写死,免得误伤别的进程)
