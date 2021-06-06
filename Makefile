ifdef SIMULATOR
	TARGET = simulator:clang:latest:8.0
else
	TARGET = iphone:clang:latest:7.0
	ARCHS= armv7 arm64
endif
 
INSTALL_TARGET_PROCESSES = fatego ProductName GameDemo-mobile 
# INSTALL_TARGET_PROCESSES += SpringBoard

TWEAK_NAME = AccDemo AccDemoLoader

AccDemo_FILES = Tweak.x
AccDemo_CFLAGS = -fobjc-arc

AccDemo_FILES += WQSuspendView/SuspendView/SuspendView/WQSuspendView.m
AccDemo_CFLAGS += -I./WQSuspendView/SuspendView

AccDemo_FILES += $(wildcard WHToast/WHToast/*.m)
AccDemo_CFLAGS += -I./WHToast

AccDemo_LIBRARIES = substrate
AccDemo_LOGOSFLAGS = -c generator=MobileSubstrate



AccDemoLoader_FILES = TweakLoader.x
AccDemoLoader_CFLAGS = -fobjc-arc



ADDITIONAL_CFLAGS += -Wno-error=unused-variable -Wno-error=unused-function -include Prefix.pch

SUBPROJECTS += accdemopref
SUBPROJECTS += ccaccdemo

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
