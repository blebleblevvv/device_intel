$(call inherit-product, build/target/product/generic.mk)
$(call inherit-product-if-exists, vendor/google/products/gms.mk)
$(call inherit-product-if-exists, hardware/intel/PRIVATE/houdini/houdini.mk)

PRODUCT_PACKAGES += \
        libdrm \
        dristat \
        drmstat \
        drmioserver \
        drmserver \
        gpustate \
        grabfb \
        make_ext4fs \
        mke2fs \
        resize2fs \
        sound \
        tune2fs \
        v8shell \
        videoblt \
        egl.cfg \
        alsa_amixer \
        alsa_ctl \
        alsa_aplay \
        AudioHardwareRecord \
        cards/aliases.conf \
        00main \
        default \
        hda \
        help \
        info \
        test \
        pcm/center_lfe.conf \
        pcm/default.conf \
        pcm/dmix.conf \
        pcm/dpl.conf \
        pcm/dsnoop.conf \
        pcm/front.conf \
        pcm/iec958.conf \
        pcm/modem.conf \
        pcm/rear.conf \
        pcm/side.conf \
        pcm/surround40.conf \
        pcm/surround41.conf \
        pcm/surround50.conf \
        pcm/surround51.conf \
        pcm/surround71.conf \
        alsa.conf \
        AudioHardwareRecordLoop \
        libWnnEngDic \
        libWnnJpnDic \
        libaudioquality \
        libcts_jni \
        libctspermission_jni \
        libctsverifier_jni \
        libdrmframework_jni \
        libdrmpassthruplugin \
        libgl2jni \
        libgldualjni \
        libgljni \
        libglperf \
        libnfc \
        libsrv_init \
        libsrv_um \
        libublock \
        libusc \
        libwnndict \
        libmemrar \
        libwsbm \
        acoustics.default \
        alsa.default \
        AT_Translated_Set_2_keyboard.kcm \
        libcamera \
        modprobe \
        libglslcompiler \
        fs_mgr \
        libfs_mgr \

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

PRODUCT_COPY_FILES += \
        device/intel/common/apns-conf.xml:system/etc/apns-conf.xml \
        device/intel/common/asound.conf:system/etc/asound.conf \
        device/intel/common/init.rc:init.rc \
        device/intel/common/init.rc:root/init.rc \
        device/intel/common/media_profiles.xml:system/etc/media_profiles.xml \
        device/intel/common/wpa_supplicant.conf:system/etc/wifi/wpa_supplicant.conf \
        device/intel/common/bootanimation.zip:system/media/bootanimation.zip \
        frameworks/native/data/etc/tablet_core_hardware.xml:system/etc/permissions/tablet_core_hardware.xml \
        frameworks/native/data/etc/android.hardware.camera.front.xml:system/etc/permissions/android.hardware.camera.front.xml \
        frameworks/native/data/etc/android.hardware.camera.xml:system/etc/permissions/android.hardware.camera.xml \
        frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:system/etc/permissions/android.hardware.camera.flash-autofocus.xml \
        frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
        frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
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
include frameworks/native/build/tablet-dalvik-heap.mk

# Put en_US first in the list, so make it default.
PRODUCT_LOCALES := en_US

# Get a list of languages.
$(call inherit-product, $(SRC_TARGET_DIR)/product/locales_full.mk)

# Get the TTS language packs
$(call inherit-product-if-exists, external/svox/pico/lang/all_pico_languages.mk)
