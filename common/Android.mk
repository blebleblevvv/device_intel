POWEROFF_WRAPPER := $(TARGET_ROOT_OUT_SBIN)/poweroff
$(POWEROFF_WRAPPER):
	$(hide) mkdir -p $(TARGET_ROOT_OUT_SBIN)
	@echo "Install: $@"
	@echo "#!/system/bin/sh" > $@
	@echo "/system/bin/reboot -p" >> $@
	@chmod 750 $@

ALL_DEFAULT_INSTALLED_MODULES += $(POWEROFF_WRAPPER)

.PHONY: tarballs
tarballs: droid boottarball systemtarball userdatatarball

