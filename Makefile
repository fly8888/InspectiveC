export THEOS_DEVICE_IP = 192.168.31.227
export THEOS_DEVICE_PORT = 22
export ARCHS = armv7 arm64		#指定架构为 armv7 和 arm64	
export TARGET = iphone:latest:8.0				#指定目标设备为 iPhone 8.0 及以上版本
export ADDITIONAL_OBJCFLAGS = -fobjc-exceptions #启用 Objective-C 的异常处理支持


include $(THEOS)/makefiles/common.mk


# 生成.s文件
# ADDITIONAL_OBJCFLAGS += -S

LIBRARY_NAME = libinspectivec
libinspectivec_FILES = hashmap.mm logging.mm blocks.mm InspectiveC.mm

# 如果 USE_FISHHOOK 为 true，则 使用 fishhook 替换 substrate 

ifeq ($(call __theos_bool,$(USE_FISHHOOK)),$(_THEOS_TRUE))
	libinspectivec_FILES += fishhook/fishhook.c
	libinspectivec_CFLAGS = -DUSE_FISHHOOK=1
else
	libinspectivec_LIBRARIES = substrate
endif

libinspectivec_FRAMEWORKS = Foundation UIKit
# If building to embed within an Xcode app
# libinspectivec_INSTALL_PATH = @rpath


include $(THEOS_MAKE_PATH)/library.mk

after-install::
#	install.exec "killall -9 SpringBoard"
