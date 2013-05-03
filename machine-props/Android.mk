LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := machine-props
LOCAL_MODULE_CLASS := ETC
machine-props_PATH := $(LOCAL_PATH)

# List of files containing DMI match strings.  Will be concatenated
# together to produce the final /system/etc/dmi-machine.conf file.
DMI_MATCH_SRCS += $(machine-props_PATH)/dmi-machine.conf

# List of files to be added to /system/etc/machine-props
MACH_PROP_FILES += $(wildcard $(machine-props_PATH)/*.prop)

include $(BUILD_SYSTEM)/base_rules.mk

# Evaluation note: make dependencies bind at parse time (i.e. they
# don't lazy-evaluate like variables assigned with "="), so while we
# would like this target to depend precisely on the full list
# (augmented in other makefiles) of inputs in MACH_PROP_FILES and
# DMI_MATCH_SRCS, we can't have that without forcing the derived files
# to jump through hoops and add dependencies manually.  Build them
# unconditionally via .PHONY.

.PHONY: $(LOCAL_BUILT_MODULE)

# Note hack: "mkdir $@" works to prevent the built system from trying
# to install a file named "machine-props", which doesn't exist (it
# works because cp/acp will benignly skip input directories without
# error).  This probably constitutes abuse of the paradigm, but I
# couldn't find the Right Way.

$(LOCAL_BUILT_MODULE):
	$(hide) mkdir -p $@
	$(hide) mkdir -p $(TARGET_OUT_ETC)/machine-props/
	$(hide) cat $(DMI_MATCH_SRCS) > $(TARGET_OUT_ETC)/dmi-machine.conf
	$(hide) cp $(MACH_PROP_FILES) $(TARGET_OUT_ETC)/machine-props/
