# make file for samsungxe700t
#

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE_TAGS := optional
include $(BUILD_KEY_CHAR_MAP)

allimages: installer_img

include device/intel/core_mesa/AndroidBoard.mk
