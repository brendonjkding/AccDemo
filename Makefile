ifdef SIMULATOR
	TARGET = simulator:clang:11.2:8.0
	ARCHS = x86_64
else
	TARGET = iphone:clang:11.2:7.0
	ARCHS= armv7 arm64
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
