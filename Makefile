TARGET = iphone:clang:11.2:11.0
export TARGET_CODESIGN_FLAGS="-Sent.xml"
ARCHS= arm64
INSTALL_TARGET_PROCESSES = fatego ProductName GameDemo-mobile

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = accDemo
accDemo_FILES = Tweak.x $(wildcard WQSuspendView/*.m) $(wildcard WHToast/*.m) $(wildcard readmem/*.m)
accDemo_CFLAGS = -fobjc-arc -Wno-unused-variable
#accDemo_LIBRARIES= rocketbootstrap
#accDemo_PRIVATE_FRAMEWORKS = AppSupport 

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += accdemo
SUBPROJECTS += ccaccdemo
include $(THEOS_MAKE_PATH)/aggregate.mk

BUNDLE_NAME = com.brend0n.accdemo
com.brend0n.accdemo_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries
include $(THEOS)/makefiles/bundle.mk
