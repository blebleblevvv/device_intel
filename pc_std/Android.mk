PC_STD_LOCAL_PATH := $(call my-dir)
include $(call all-subdir-makefiles)
LOCAL_PATH := $(PC_STD_LOCAL_PATH)

include $(CLEAR_VARS)
LOCAL_MODULE := init.net.eth0.sh
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $(TARGET_OUT_ETC)
LOCAL_SRC_FILES := $(LOCAL_MODULE)
include $(BUILD_PREBUILT)


