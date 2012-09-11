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
#ifndef _AUDIO_HAL_H
#define _AUDIO_HAL_H

//#define LOG_NDEBUG 0

#include <errno.h>
#include <pthread.h>
#include <stdint.h>
#include <sys/time.h>

#include <cutils/log.h>

#include <hardware/hardware.h>
#include <system/audio.h>
#include <hardware/audio.h>
#include <tinyalsa/asoundlib.h>

#undef LOG_TAG
#define LOG_TAG "audio_hw_intel_hda"

#define _ENTER() ALOGV(">>%s", __FUNCTION__)
#define _EXIT() ALOGV("<<%s", __FUNCTION__)

struct intel_hda_audio_device {
    struct audio_hw_device device;
    bool mic_mute;
};

// Function prototypes

// Output device
int intel_hda_set_mode(struct audio_hw_device *dev, int mode);
static int intel_hda_open_output_stream(struct audio_hw_device *dev,
                                   audio_io_handle_t handle,
                                   audio_devices_t devices,
                                   audio_output_flags_t flags,
                                   struct audio_config *config,
                                   struct audio_stream_out **stream_out);

void intel_hda_close_output_stream(struct audio_hw_device *dev,
                                     struct audio_stream_out *stream);

// Input devices
int intel_hda_set_mode(struct audio_hw_device *dev, int mode);
int intel_hda_set_mic_mute(struct audio_hw_device *dev, bool state);
int intel_hda_get_mic_mute(const struct audio_hw_device *dev, bool *state);
size_t intel_hda_get_input_buffer_size(const struct audio_hw_device *dev,
                                         const struct audio_config *config);

int intel_hda_open_input_stream(struct audio_hw_device *dev,
                                  audio_io_handle_t handle,
                                  audio_devices_t devices,
                                  struct audio_config *config,
                                  struct audio_stream_in **stream_in);

void intel_hda_close_input_stream(struct audio_hw_device *dev,
                                   struct audio_stream_in *in);
int intel_hda_set_input_mode(bool on);

// Mixer devices
bool intel_hda_setup_mixer();
int intel_hda_set_voice_volume(struct audio_hw_device *dev, float volume);
int intel_hda_set_master_volume(struct audio_hw_device *dev, float volume);
int intel_hda_set_output_mode();

#endif
