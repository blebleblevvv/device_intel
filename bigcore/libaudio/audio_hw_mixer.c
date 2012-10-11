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
#include <pthread.h>
#include <stdint.h>
#include <sys/time.h>
#include "audio_hal.h"

#define SPEAKER_PLAYBACK_VOLUME     "Speaker Playback Volume"
#define PCM_PLAYBACK_VOLUME         "PCM Playback Volume"
#define SURROUND_PLAYBACK_VOLUME    "Surround Playback Volume"
#define SPEAKER_PLAYBACK_SWITCH     "Speaker Playback Switch"
#define PCM_PLAYBACK_SWITCH         "PCM Playback Switch"
#define SURROUND_PLAYBACK_SWITCH    "Surround Playback Switch"
#define HEADPHONE_PLAYBACK_VOLUME   "Headphone Playback Volume"
#define HEADPHONE_PLAYBACK_SWITCH   "Headphone Playback Switch"
#define AUTO_MUTE_MODE              "Auto-Mute Mode"
#define INTRL_MIC_VOLUME            "Internal Mic Boost Volume"
#define MIC_VOLUME                  "Mic Boost Volume"
#define CAPTURE_SWITCH              "Capture Switch"
#define CAPTURE_VOLUME              "Capture Volume"
#define MASTER_PLAYBACK_VOLUME      "Master Playback Volume"
#define MASTER_PLAYBACK_SWITCH      "Master Playback Switch"

#define MAX_CAPTURE_VOLUME           100
#define DEFAULT_MIC_BOOST_VOLUME     1

struct mixer_control
{
// output control
    struct mixer_ctl *speaker_enable;
    struct mixer_ctl *speaker_volume;
    struct mixer_ctl *surround_enable;
    struct mixer_ctl *surround_volume;
    struct mixer_ctl *master_speaker_enable;
    struct mixer_ctl *master_speaker_volume;
    struct mixer_ctl *headphone_enable;
    struct mixer_ctl *headphone_volume;
// input controls
    struct mixer_ctl *capture_switch;
    struct mixer_ctl *capture_volume;
    struct mixer_ctl *mic_boost_volume;

    float voice_volume;
    float master_volume;
};
static struct mixer *mixer_inst;
static struct mixer_control mixer_ctls;
static bool mixer_initialized;

static int set_output_mixer_volume()
{
    int i;
    int num_values;
    int speaker_max_value;
    int headset_max_value;
    int surround_max_value;
    int master_speaker_max_value = 0;
    int ret;

    _ENTER();

    if (!mixer_initialized) {
        ret = intel_hda_setup_mixer();
        if (!ret) {
            ALOGE("intel_hda_setup_mixer: failed");
            goto fail;
        }
    }

    if (!mixer_ctls.master_speaker_volume) {
        ALOGE("mixer_ctls.master_speaker_volume: Invalid");
        ret = -ENOSYS;
        goto fail;
    }
    master_speaker_max_value = mixer_ctl_get_range_max(mixer_ctls.master_speaker_volume);

    if (master_speaker_max_value > 0) {
        num_values = mixer_ctl_get_num_values(mixer_ctls.master_speaker_volume);
        for (i = 0; i < num_values; i++) {
            if (mixer_ctl_set_value(mixer_ctls.master_speaker_volume, i,
                    master_speaker_max_value * mixer_ctls.master_volume)) {
                ALOGE( "intel_hda_set_voice_volume: invalid value\n");
                ret = -ENOSYS;
                goto fail;
            }
        }
    }

    num_values = mixer_ctl_get_num_values(mixer_ctls.master_speaker_enable);
    for (i = 0; i < num_values; i++) {
        if (mixer_ctl_set_value(mixer_ctls.master_speaker_enable, i, 1)) {
            ALOGE( "intel_hda_set_input_mode: invalid value\n");
            ret = -ENOSYS;
            goto fail;
        }
    }

    if (!mixer_ctls.speaker_volume) {
        ALOGE("mixer_ctls.speaker_volume: Invalid");
        ret = -ENOSYS;
        goto fail;
    }
    speaker_max_value = mixer_ctl_get_range_max(mixer_ctls.speaker_volume);
    ALOGD("Set Volume max %d current %f", speaker_max_value, mixer_ctls.voice_volume);

    num_values = mixer_ctl_get_num_values(mixer_ctls.speaker_volume);
        for (i = 0; i < num_values; i++) {
        if (mixer_ctl_set_value(mixer_ctls.speaker_volume, i, speaker_max_value)) {
            ALOGE( "intel_hda_set_voice_volume: invalid value\n");
            ret = -ENOSYS;
            goto fail;
        }
    }
    num_values = mixer_ctl_get_num_values(mixer_ctls.speaker_enable);
    for (i = 0; i < num_values; i++) {
        if (mixer_ctl_set_value(mixer_ctls.speaker_enable, i, 1)) {
            ALOGE( "mixer_ctls.speaker_enable: invalid value\n");
            ret = -ENOSYS;
            goto fail;
        }
    }
    headset_max_value = mixer_ctl_get_range_max(mixer_ctls.headphone_volume);
    ALOGD("Set Volume max %d current %f", headset_max_value, mixer_ctls.voice_volume);
    if (!mixer_ctls.headphone_volume) {
        ALOGE("mixer_ctls.headphone_volume: Invalid");
        ret = -ENOSYS;
        goto fail;
    }
    num_values = mixer_ctl_get_num_values(mixer_ctls.headphone_volume);
        for (i = 0; i < num_values; i++) {
        if (mixer_ctl_set_value(mixer_ctls.headphone_volume, i, headset_max_value)) {
            ALOGE( "intel_hda_set_voice_volume: invalid value\n");
            ret = -ENOSYS;
            goto fail;
        }
    }

    if (mixer_ctls.surround_enable) {
        num_values = mixer_ctl_get_num_values(mixer_ctls.surround_enable);
        for (i = 0; i < num_values; i++) {
            if (mixer_ctl_set_value(mixer_ctls.surround_enable, i, 1)) {
                ALOGE( "mixer_ctls.surround_switch: invalid value\n");
                ret = -ENOSYS;
                goto fail;
            }
        }
    }

    if (mixer_ctls.surround_volume) {
        surround_max_value = mixer_ctl_get_range_max(mixer_ctls.surround_volume);
        ALOGD("Set Volume max %d current %f", surround_max_value, mixer_ctls.surround_volume);
        if (!mixer_ctls.surround_volume) {
            ALOGE("mixer_ctls.surround_volume: Invalid");
            ret = -ENOSYS;
            goto fail;
        }
        num_values = mixer_ctl_get_num_values(mixer_ctls.surround_volume);
            for (i = 0; i < num_values; i++) {
            if (mixer_ctl_set_value(mixer_ctls.surround_volume, i, surround_max_value)) {
                ALOGE( "mixer_ctls.surround_volume: invalid value\n");
                ret = -ENOSYS;
                goto fail;
            }
        }
    }

    ret = 0;

fail:
    _EXIT();
    return ret;
}

int intel_hda_set_output_mode()
{
    return set_output_mixer_volume();
}

int intel_hda_set_voice_volume(struct audio_hw_device *dev, float volume)
{
    return -ENOSYS;
}

int intel_hda_set_master_volume(struct audio_hw_device *dev, float volume)
{
    return -ENOSYS;
}

int intel_hda_set_input_mode(bool on)
{
    int num_values, i, ret;

    _ENTER();

    if (!mixer_initialized) {
        ret = intel_hda_setup_mixer();
        if (!ret) {
            ALOGE("intel_hda_setup_mixer: failed");
            goto fail;
        }
    }

    ALOGD("Set input mode %d",on);
    if (!mixer_ctls.capture_switch || !mixer_ctls.capture_volume) {
        ALOGE("mixer_ctls.capture_switch/capture_volume: Invalid");
        ret = -ENOSYS;
        goto fail;
    }
    num_values = mixer_ctl_get_num_values(mixer_ctls.capture_switch);
    for (i = 0; i < num_values; i++) {
        if (mixer_ctl_set_value(mixer_ctls.capture_switch, i, on?1:0)) {
            ALOGE( "intel_hda_set_input_mode: invalid value\n");
            ret = -ENOSYS;
            goto fail;
        }
    }
    num_values = mixer_ctl_get_num_values(mixer_ctls.capture_volume);
    for (i = 0; i < num_values; i++) {
        if (mixer_ctl_set_value(mixer_ctls.capture_volume, i, on?MAX_CAPTURE_VOLUME:0)) {
            ALOGE( "intel_hda_set_input_mode: invalid value\n");
            ret = -ENOSYS;
            goto fail;
        }
    }

    num_values = mixer_ctl_get_num_values(mixer_ctls.mic_boost_volume);
    for (i = 0; i < num_values; i++) {
        if (mixer_ctl_set_value(mixer_ctls.mic_boost_volume, i, on?DEFAULT_MIC_BOOST_VOLUME:0)) {
            ALOGE( "intel_hda_set_input_mode: invalid value\n");
            ret = -ENOSYS;
            goto fail;
        }
    }

    ret = 0;

fail:
    _EXIT();
    return ret;
}

bool intel_hda_setup_mixer()
{
    mixer_inst = mixer_open(0);
    if (!mixer_inst)
        return false;

    mixer_ctls.surround_volume  = mixer_get_ctl_by_name(mixer_inst, SURROUND_PLAYBACK_VOLUME);
    mixer_ctls.surround_enable  = mixer_get_ctl_by_name(mixer_inst, SURROUND_PLAYBACK_SWITCH);
    mixer_ctls.speaker_volume  = mixer_get_ctl_by_name(mixer_inst, SPEAKER_PLAYBACK_VOLUME);
    if (!mixer_ctls.speaker_volume)
        mixer_ctls.speaker_volume  = mixer_get_ctl_by_name(mixer_inst, PCM_PLAYBACK_VOLUME);
    mixer_ctls.speaker_enable  = mixer_get_ctl_by_name(mixer_inst, SPEAKER_PLAYBACK_SWITCH);
    if (!mixer_ctls.speaker_enable)
        mixer_ctls.speaker_enable  = mixer_get_ctl_by_name(mixer_inst, PCM_PLAYBACK_SWITCH);
    mixer_ctls.master_speaker_volume  = mixer_get_ctl_by_name(mixer_inst, MASTER_PLAYBACK_VOLUME);
    mixer_ctls.master_speaker_enable  = mixer_get_ctl_by_name(mixer_inst, MASTER_PLAYBACK_SWITCH);
    mixer_ctls.headphone_enable  = mixer_get_ctl_by_name(mixer_inst, HEADPHONE_PLAYBACK_SWITCH);
    mixer_ctls.headphone_volume  = mixer_get_ctl_by_name(mixer_inst, HEADPHONE_PLAYBACK_VOLUME);
    mixer_ctls.voice_volume = mixer_ctls.master_volume = 1.0f;

    mixer_ctls.capture_switch  = mixer_get_ctl_by_name(mixer_inst, CAPTURE_SWITCH);
    mixer_ctls.capture_volume  = mixer_get_ctl_by_name(mixer_inst, CAPTURE_VOLUME);
    mixer_ctls.mic_boost_volume  = mixer_get_ctl_by_name(mixer_inst, INTRL_MIC_VOLUME);
    mixer_initialized = true;
    return true;
}
