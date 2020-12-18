ifdef SIMULATOR
	TARGET = simulator:clang:11.2:8.0
	ARCHS = x86_64
else
	TARGET = iphone:clang:11.2:7.0
	ARCHS= armv7 arm64 arm64e
endif
 
INSTALL_TARGET_PROCESSES = fatego ProductName GameDemo-mobile 
# INSTALL_TARGET_PROCESSES += SpringBoard

TWEAK_NAME = accDemo
accDemo_FILES = Tweak.x
accDemo_CFLAGS = -fobjc-arc -Wno-error=unused-variable -Wno-error=unused-function -include Prefix.pch

accDemo_FILES += WQSuspendView/SuspendView/SuspendView/WQSuspendView.m 
accDemo_CFLAGS += -I./WQSuspendView/SuspendView

accDemo_FILES += $(wildcard WHToast/WHToast/*.m)
accDemo_CFLAGS += -I./WHToast

accDemo_LIBRARIES = substrate

ifdef SIMULATOR
accDemo_LOGOSFLAGS = -c generator=MobileSubstrate
endif

SUBPROJECTS += accdemopref
SUBPROJECTS += ccaccdemo
include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

ifdef SIMULATOR
include $(THEOS)/makefiles/locatesim.mk
BUNDLE_NAME = accDemo
PREF_FOLDER_NAME = accdemopref
endif

setup:: all
	@rm -f /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/$(TWEAK_NAME).dylib /opt/simject/$(TWEAK_NAME).dylib
	@codesign -f -s - /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(PWD)/$(TWEAK_NAME).plist /opt/simject
	@sudo cp -v $(PWD)/$(PREF_FOLDER_NAME)/entry.plist $(PL_SIMULATOR_PLISTS_PATH)/$(BUNDLE_NAME).plist
	@sudo cp -vR $(THEOS_OBJ_DIR)/$(BUNDLE_NAME).bundle $(PL_SIMULATOR_BUNDLES_PATH)/
	@sudo codesign -f -s - $(PL_SIMULATOR_BUNDLES_PATH)/$(BUNDLE_NAME).bundle/$(BUNDLE_NAME)
	@resim

remove::
	@rm -f /opt/simject/$(TWEAK_NAME).dylib /opt/simject/$(TWEAK_NAME).plist
	@sudo rm -r $(PL_SIMULATOR_BUNDLES_PATH)/$(BUNDLE_NAME).bundle
	@sudo rm $(PL_SIMULATOR_PLISTS_PATH)/$(BUNDLE_NAME).plist
	@resim