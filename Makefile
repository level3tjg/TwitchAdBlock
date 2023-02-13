ifeq ($(SIDELOADED),1)
MODULES = jailed
endif

TARGET := iphone:clang:14.5:12.0
INSTALL_TARGET_PROCESSES = Twitch

ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TwitchAdBlock

$(TWEAK_NAME)_FILES = Tweak.xm Settings.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
ifeq ($(SIDELOADED),1)
$(TWEAK_NAME)_FILES += Sideloaded.x fishhook/fishhook.c
$(TWEAK_NAME)_IPA = Twitch.ipa
CODESIGN_IPA = 0
endif

include $(THEOS_MAKE_PATH)/tweak.mk
