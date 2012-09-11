# make file for lenovox220t
#

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE_TAGS := optional
include $(BUILD_KEY_CHAR_MAP)

include device/intel/bigcore/AndroidBoard.mk
