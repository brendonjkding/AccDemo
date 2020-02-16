#TARGET = iphone:clang:11.2:9.0
ARCHS= arm64 arm64e
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = accDemo

accDemo_FILES = BDRootListController.m
accDemo_INSTALL_PATH = /Library/PreferenceBundles
accDemo_FRAMEWORKS = UIKit
accDemo_PRIVATE_FRAMEWORKS = Preferences
accDemo_CFLAGS = -fobjc-arc
accDemo_LIBRARIES = sparkapplist

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/accDemo.plist$(ECHO_END)
