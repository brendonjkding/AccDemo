export TARGET = iphone:clang:latest:11.0
export ARCHS = arm64 arm64e

BUNDLE_NAME = CCaccdemo
CCaccdemo_BUNDLE_EXTENSION = bundle
CCaccdemo_FILES = CCaccdemo.m
CCaccdemo_CFLAGS = -include Prefix.pch
CCaccdemo_PRIVATE_FRAMEWORKS = ControlCenterUIKit
CCaccdemo_INSTALL_PATH = /Library/ControlCenter/Bundles/

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk
