THEOS_DEVICE_IP = 192.168.1.144

ifeq ($(ROOTLESS),1)
THEOS_PACKAGE_SCHEME=rootless
endif

export ARCHS = arm64
TARGET := iphone:clang:latest:12.4
INSTALL_TARGET_PROCESSES = YouTube
PACKAGE_VERSION = 1.2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iSponsorBlock

iSponsorBlock_FILES = iSponsorBlock.xm $(wildcard *.m) #SponsorBlockSettingsController.x $(wildcard *.x)
iSponsorBlock_LIBRARIES = colorpicker
iSponsorBlock_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk
