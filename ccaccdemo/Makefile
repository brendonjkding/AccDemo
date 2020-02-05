include $(THEOS)/makefiles/common.mk

export TARGET = iphone:clang:11.2:11.0
export ARCHS = arm64

BUNDLE_NAME = CCaccdemo
CCaccdemo_BUNDLE_EXTENSION = bundle
CCaccdemo_FILES = CCaccdemo.m
CCaccdemo_PRIVATE_FRAMEWORKS = ControlCenterUIKit
CCaccdemo_INSTALL_PATH = /Library/ControlCenter/Bundles/

after-install::
	install.exec "killall -9 SpringBoard"

include $(THEOS_MAKE_PATH)/bundle.mk
