ARCHS= arm64
INSTALL_TARGET_PROCESSES = fatego
export TARGET_CODESIGN_FLAGS="-Sent.xml"
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = accDemo

accDemo_FILES = Tweak.x
accDemo_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
after-stage::
# 	$(ECHO_NOTHING)chmod 777 $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/accDemo.dylib$(ECHO_END)
	#$(ECHO_NOTHING)chown mobile:staff $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/accDemo.dylib$(ECHO_END)
after-install::
# 	install.exec "chown mobile:staff /Library/MobileSubstrate/DynamicLibraries/accDemo.dylib"