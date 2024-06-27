ifeq ($(SIDELOADED),1)
MODULES = jailed
endif

PACKAGE_VERSION = 0.1.5
ifdef APP_VERSION
  PACKAGE_VERSION := $(APP_VERSION)-$(PACKAGE_VERSION)
endif

ifeq ($(STS),1)
  PACKAGE_VERSION := $(PACKAGE_VERSION)-STS
endif
ifeq ($(LTS),1)
  PACKAGE_VERSION := $(PACKAGE_VERSION)-LTS
endif

TARGET := iphone:clang:latest:12.4
INSTALL_TARGET_PROCESSES = mediaserverd Twitch

ARCHS = arm64

ADDITIONAL_CFLAGS = -Wno-module-import-in-extern-c

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TwitchAdBlock

$(TWEAK_NAME)_FILES = $(wildcard *.*m) fishhook/fishhook.c
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Iinclude -DPROXY_URL=@\"firefox.api.cdn-perfprod.com:2023\"
ifeq ($(SIDELOADED),1)
  $(TWEAK_NAME)_FILES += Sideloaded.x fishhook/fishhook.c
  CODESIGN_IPA = 0
  ifeq ($(LTS),1)
    $(TWEAK_NAME)_INJECT_DYLIBS = $(THEOS_OBJ_DIR)/TwitchLoginFix.dylib
    SUBPROJECTS += TwitchLoginFix
    include $(THEOS_MAKE_PATH)/aggregate.mk
  endif
endif

include $(THEOS_MAKE_PATH)/tweak.mk
