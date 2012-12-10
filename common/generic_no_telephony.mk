$(call inherit-product, build/target/product/generic_no_telephony.mk)
$(call inherit-product-if-exists, vendor/google/products/gms.mk)
#$(call inherit-product-if-exists, hardware/intel/PRIVATE/houdini/houdini.mk)

# Extra debug tools
PRODUCT_PACKAGES += \
	AudioHardwareRecordLoop \
	AudioHardwareRecord \
	v8shell \
	sound \
	aklog \


# The Google SetupWizard will require a sim card in order to provision the device
# unless we override that behavior with this property.  See
# build/target/product/full_base_telephony.mk for an example where this is set (for ARM).
# See frameworks/base/policy/src/com/android/internal/policy/impl/KeyguardViewMediator.java
# for how this is used by policy.  Productizers who need to require a sim for provisioning
# should remove this.
PRODUCT_PROPERTY_OVERRIDES += \
        keyguard.no_require_sim=true \

# Add Google applications (that are compiled from source code
# and do not come from GMS Apps). For GMS Apps see
# vendor/google/products/gms.mk
PRODUCT_PACKAGES += \
        Camera

# Add CDD applications
PRODUCT_PACKAGES += \
        Amazed \
        AndroidGlobalTime \
        AnyCut \
        BTClickLinkCompete \
        CLiCkin2DaBeaT \
        DivideAndConquer \
        Downloader \
        HeightMapProfiler \
        LolcatBuilder \
        Panoramio \
        Photostream \
        Radar \
        RingsExtended \
        SpriteMethodTest \
        SpriteText \
        Translate \
        Triangle \
        WebViewDemo \
        WikiNotes \
        ReplicaIsland

# Add live wallpapers
PRODUCT_PACKAGES += \
        LiveWallpapers \
        HoloSpiralWallpaper \
        LiveWallpapersPicker \
        MagicSmokeWallpapers \
        VisualizationWallpapers

# libva
PRODUCT_PACKAGES += \
        libva \
        libva-android \
        libva-tpi \
        vainfo

PRODUCT_MANUFACTURER := intel

PRODUCT_CHARACTERISTICS := tablet

# The entry for android.hardware.wifi.direct has been removed from the list
# below because at this time the P2P functionality it represents depends on a
# BroadCom "dhd" device and driver.  We don't have this.  The P2P supplicant
# crashes as a result.
#
#        frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
#
# Removing this allows the wpa_supplicant to run, which we want
PRODUCT_COPY_FILES += \
        device/intel/common/apns-conf.xml:system/etc/apns-conf.xml \
        device/intel/common/asound.conf:system/etc/asound.conf \
        device/intel/common/audio_policy.conf:system/vendor/etc/audio_policy.conf \
        device/intel/common/media_profiles.xml:system/etc/media_profiles.xml \
        device/intel/common/media_codecs.xml:system/etc/media_codecs.xml \
        device/intel/common/wpa_supplicant.conf:system/etc/wifi/wpa_supplicant.conf \
        device/intel/common/bootanimation.zip:system/media/bootanimation.zip \
        frameworks/native/data/etc/tablet_core_hardware.xml:system/etc/permissions/tablet_core_hardware.xml \
        frameworks/native/data/etc/android.hardware.camera.front.xml:system/etc/permissions/android.hardware.camera.front.xml \
        frameworks/native/data/etc/android.hardware.camera.xml:system/etc/permissions/android.hardware.camera.xml \
        frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
        frameworks/native/data/etc/android.hardware.nfc.xml:system/etc/permissions/android.hardware.nfc.xml \
        frameworks/native/data/etc/android.hardware.location.gps.xml:system/etc/permissions/android.hardware.location.gps.xml \
        frameworks/native/data/etc/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml \
        frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:system/etc/permissions/android.hardware.sensor.gyroscope.xml \
        frameworks/native/data/etc/android.hardware.faketouch.xml:system/etc/permissions/android.hardware.faketouch.xml \
        frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
        frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml \
        frameworks/native/data/etc/android.hardware.audio.low_latency.xml:system/etc/permissions/android.hardware.audio.low_latency.xml \
        packages/wallpapers/LivePicker/android.software.live_wallpaper.xml:system/etc/permissions/android.software.live_wallpaper.xml \

# Copy sound effects (e.g. ringtones) to target:
include frameworks/base/data/sounds/AudioPackage4.mk

# Copy video effects to target:
include frameworks/base/data/videos/VideoPackage2.mk

# Heap size setting for tablet.
include frameworks/native/build/tablet-7in-hdpi-1024-dalvik-heap.mk

# Put en_US first in the list, so make it default.
PRODUCT_LOCALES := en_US

# Get a list of languages.
$(call inherit-product, $(SRC_TARGET_DIR)/product/locales_full.mk)

# Get the TTS language packs
$(call inherit-product-if-exists, external/svox/pico/lang/all_pico_languages.mk)
