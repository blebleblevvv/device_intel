# Pass-through build to include subdirectories

ifeq ($(TARGET_ARCH),x86)
include $(all-subdir-makefiles)
endif
