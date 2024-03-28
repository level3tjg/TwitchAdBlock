ifeq ($(SIDELOADED),1)
MODULES = jailed
endif

PACKAGE_VERSION = 0.1.0-2

TARGET := iphone:clang:14.5:12.0
INSTALL_TARGET_PROCESSES = Twitch

ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TwitchAdBlock

$(TWEAK_NAME)_FILES = $(wildcard *.*m)
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Iinclude
ifeq ($(SIDELOADED),1)
  $(TWEAK_NAME)_FILES += Sideloaded.x fishhook/fishhook.c
  CODESIGN_IPA = 0
  ifeq ($(LEGACY),1) # 12.8.1
    $(TWEAK_NAME)_INJECT_DYLIBS = $(THEOS_OBJ_DIR)/TwitchLoginFix.dylib
    SUBPROJECTS += TwitchLoginFix
    include $(THEOS_MAKE_PATH)/aggregate.mk
  endif
endif

include $(THEOS_MAKE_PATH)/tweak.mk
