ifeq ($(SIDELOADED),1)
MODULES = jailed
endif

TARGET := iphone:clang:latest:11.0
INSTALL_TARGET_PROCESSES = Twitch

ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TwitchAdBlock

$(TWEAK_NAME)_FILES = $(wildcard *.m) $(wildcard *.xm)
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_FRAMEWORKS = CoreServices
ifeq ($(SIDELOADED),1)
$(TWEAK_NAME)_FILES += Sideloaded.x
$(TWEAK_NAME)_IPA = Twitch.ipa
_CODESIGN_IPA = 0
endif

include $(THEOS_MAKE_PATH)/tweak.mk
