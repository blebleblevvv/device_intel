/*
 * Copyright (C) 2011 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include <errno.h>
#include <hardware/hardware.h>
#include <system/audio.h>
#include <hardware/audio.h>
#include "audio_hal.h"

// Forced to include, because the hardware/audio.h
// includes some header file with global variable defined
// inside header file. If compiled seprately this results in
// multiple definintions.
#include "audio_hw_out.c"
#include "audio_hw_in.c"
#include "audio_hw_mixer.c"

static int intel_hda_init_check(const struct audio_hw_device *dev)
{
    _ENTER();
    _EXIT();
    return 0;
}

static int intel_hda_set_parameters(struct audio_hw_device *dev, const char *kvpairs)
{
    _ENTER();
    _EXIT();
    return -ENOSYS;
}

static char * intel_hda_get_parameters(const struct audio_hw_device *dev,
                                  const char *keys)
{
    _ENTER();
    _EXIT();
    return NULL;
}

static int intel_hda_dump(const audio_hw_device_t *device, int fd)
{
    _ENTER();
    _EXIT();
    return 0;
}


static uint32_t intel_hda_get_supported_devices(const struct audio_hw_device *dev)
{
    _ENTER();
    _EXIT();

    return (/* OUT */
        AUDIO_DEVICE_OUT_EARPIECE |
        AUDIO_DEVICE_OUT_SPEAKER |
        AUDIO_DEVICE_OUT_WIRED_HEADSET |
        AUDIO_DEVICE_OUT_WIRED_HEADPHONE |
        AUDIO_DEVICE_OUT_AUX_DIGITAL |
        AUDIO_DEVICE_OUT_ANLG_DOCK_HEADSET |
        AUDIO_DEVICE_OUT_DGTL_DOCK_HEADSET |
        AUDIO_DEVICE_OUT_ALL_SCO |
        AUDIO_DEVICE_OUT_DEFAULT |
         /* IN */
        AUDIO_DEVICE_IN_COMMUNICATION |
        AUDIO_DEVICE_IN_AMBIENT |
        AUDIO_DEVICE_IN_BUILTIN_MIC |
        AUDIO_DEVICE_IN_WIRED_HEADSET |
        AUDIO_DEVICE_IN_AUX_DIGITAL |
        AUDIO_DEVICE_IN_BACK_MIC |
        AUDIO_DEVICE_IN_ALL_SCO |
        AUDIO_DEVICE_IN_DEFAULT);
}

static int intel_hda_close(hw_device_t *device)
{
    _ENTER();
    free(device);
    _EXIT();
    return 0;
}

static int intel_hda_open(const hw_module_t* module, const char* name,
                     hw_device_t** device)
{
    struct intel_hda_audio_device *adev;
    int ret;

    _ENTER();

    if (strcmp(name, AUDIO_HARDWARE_INTERFACE) != 0)
            return -EINVAL;

    adev = calloc(1, sizeof(struct intel_hda_audio_device));
    if (!adev)
            return -ENOMEM;

    adev->device.common.tag = HARDWARE_DEVICE_TAG;
    adev->device.common.version = 0;
    adev->device.common.module = (struct hw_module_t *) module;
    adev->device.common.close = intel_hda_close;

    adev->device.get_supported_devices = intel_hda_get_supported_devices;
    adev->device.init_check = intel_hda_init_check;
    adev->device.set_voice_volume = intel_hda_set_voice_volume;
    adev->device.set_master_volume = intel_hda_set_master_volume;
    adev->device.set_mode = intel_hda_set_mode;
    adev->device.set_mic_mute = intel_hda_set_mic_mute;
    adev->device.get_mic_mute = intel_hda_get_mic_mute;
    adev->device.set_parameters = intel_hda_set_parameters;
    adev->device.get_parameters = intel_hda_get_parameters;
    adev->device.get_input_buffer_size = intel_hda_get_input_buffer_size;
    adev->device.open_output_stream = intel_hda_open_output_stream;
    adev->device.close_output_stream = intel_hda_close_output_stream;
    adev->device.open_input_stream = intel_hda_open_input_stream;
    adev->device.close_input_stream = intel_hda_close_input_stream;
    adev->device.dump = intel_hda_dump;

    if (!intel_hda_setup_mixer())
        return -ENXIO;

    *device = &adev->device.common;
    _EXIT();
    return 0;
}

static struct hw_module_methods_t hal_module_methods = {
    .open = intel_hda_open,
};

struct audio_module HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .version_major = 1,
        .version_minor = 0,
        .id = AUDIO_HARDWARE_MODULE_ID,
        .name = "Intel HDA HW HAL",
        .author = "Intel Corp.",
        .methods = &hal_module_methods,
    },
};
