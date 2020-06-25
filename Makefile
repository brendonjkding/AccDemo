TARGET = iphone:clang:11.2:9.0
ARCHS= arm64 arm64e
INSTALL_TARGET_PROCESSES = fatego ProductName GameDemo-mobile

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = accDemo
accDemo_FILES = Tweak.x $(wildcard WQSuspendView/*.m) $(wildcard WHToast/*.m) $(wildcard readmem/*.m)
accDemo_CFLAGS = -fobjc-arc -Wno-unused-variable

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += accdemo
SUBPROJECTS += ccaccdemo
include $(THEOS_MAKE_PATH)/aggregate.mk

BUNDLE_NAME = com.brend0n.accdemo
com.brend0n.accdemo_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries
include $(THEOS)/makefiles/bundle.mk
