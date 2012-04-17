LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := minimal_recovery_ui.c
LOCAL_MODULE_TAGS := eng
LOCAL_C_INCLUDES := bootable/recovery
LOCAL_MODULE := libminimal_recovery_ui
LOCAL_CFLAGS := -Wall -Werror -Wno-unused-parameter
include $(BUILD_STATIC_LIBRARY)

