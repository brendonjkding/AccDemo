ARCHS= arm64
INSTALL_TARGET_PROCESSES = fatego ProductName GameDemo-mobile
#export TARGET_CODESIGN_FLAGS="-Sent.xml"
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = accDemo

accDemo_FILES = Tweak.x WQSuspendView.m
accDemo_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += accdemo
include $(THEOS_MAKE_PATH)/aggregate.mk
