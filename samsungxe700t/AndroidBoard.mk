# make file for samsungxe700t
#

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE_TAGS := optional
include $(BUILD_KEY_CHAR_MAP)

include device/intel/pc_std/AndroidBoard.mk
