LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := bigcore_device.cpp
LOCAL_MODULE_TAGS := eng
LOCAL_C_INCLUDES := bootable/recovery
LOCAL_MODULE := libpcstd_recovery_ui
LOCAL_CFLAGS := -Wall -Werror
include $(BUILD_STATIC_LIBRARY)
