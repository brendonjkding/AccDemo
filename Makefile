export TARGET_CODESIGN_FLAGS="-Sent.xml"
ARCHS= arm64
INSTALL_TARGET_PROCESSES = fatego ProductName GameDemo-mobile

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = accDemo
accDemo_FILES = Tweak.x WQSuspendView.m $(wildcard WHToast/*.m) readmem/readmem.m
accDemo_CFLAGS = -fobjc-arc -Wno-unused-variable

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += accdemo
include $(THEOS_MAKE_PATH)/aggregate.mk

BUNDLE_NAME = com.brend0n.accdemo
com.brend0n.accdemo_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries
include $(THEOS)/makefiles/bundle.mk
