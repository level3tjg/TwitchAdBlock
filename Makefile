TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = Twitch

ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TwitchAdBlock

TwitchAdBlock_FILES = Tweak.xm
TwitchAdBlock_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
