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
#define SPEAKER_PLAYBACK_SWITCH     "Speaker Playback Switch"
#define HEADPHONE_PLAYBACK_VOLUME   "Headphone Playback Volume"
#define HEADPHONE_PLAYBACK_SWITCH   "Headphone Playback Switch"
#define AUTO_MUTE_MODE              "Auto-Mute Mode"
#define INTRL_MIC_VOLUME            "Internal Mic Boost Volume"
#define MIC_VOLUME                  "Mic Boost Volume"
#define CAPTURE_SWITCH              "Capture Switch"
#define CAPTURE_VOLUME              "Capture Volume"
#define MASTER_PLAYBACK_VOLUME      "Master Playback Volume"
#define MASTER_PLAYBACK_SWITCH      "Master Playback Switch"

struct mixer_control
{
// output control
    struct mixer_ctl *speaker_enable;
    struct mixer_ctl *speaker_volume;
    struct mixer_ctl *headphone_enable;
    struct mixer_ctl *headphone_volume;
 // input controls to be implemented
    float voice_volume;
    float master_volume;
};
static struct mixer *mixer_inst;
static struct mixer_control mixer_ctls;


static int set_output_mixer_volume()
{
    int i;
    int num_values;
    int speaker_max_value;
    int headset_max_value;

    _ENTER();
    speaker_max_value = mixer_ctl_get_range_max(mixer_ctls.speaker_volume);
    LOGD("Set Volume max %d current %f", speaker_max_value, mixer_ctls.voice_volume);
    if (!mixer_ctls.speaker_volume) {
        LOGE("mixer_ctls.speaker_volume: Invalid");
        return -ENOSYS;
    }
    num_values = mixer_ctl_get_num_values(mixer_ctls.speaker_volume);
        for (i = 0; i < num_values; i++) {
        if (mixer_ctl_set_value(mixer_ctls.speaker_volume, i, speaker_max_value*mixer_ctls.voice_volume)) {
            LOGE( "intel_hda_set_voice_volume: invalid value\n");
            return -ENOSYS;
        }
    }
    headset_max_value = mixer_ctl_get_range_max(mixer_ctls.headphone_volume);
    LOGD("Set Volume max %d current %f", headset_max_value, mixer_ctls.voice_volume);
    if (!mixer_ctls.headphone_volume) {
        LOGE("mixer_ctls.headphone_volume: Invalid");
        return -ENOSYS;
    }
    num_values = mixer_ctl_get_num_values(mixer_ctls.headphone_volume);
        for (i = 0; i < num_values; i++) {
        if (mixer_ctl_set_value(mixer_ctls.headphone_volume, i, headset_max_value*mixer_ctls.voice_volume)) {
            LOGE( "intel_hda_set_voice_volume: invalid value\n");
            return -ENOSYS;
        }
    }

    _EXIT();
    return 0;
}

int intel_hda_set_output_mode()
{
    set_output_mixer_volume();
    return 0;
}

int intel_hda_set_voice_volume(struct audio_hw_device *dev, float volume)
{
    _ENTER();
    mixer_ctls.voice_volume = volume;
    _EXIT();
    return 0;
}

int intel_hda_set_master_volume(struct audio_hw_device *dev, float volume)
{
    _ENTER();
    mixer_ctls.master_volume = volume;
    _EXIT();

    return 0;
}

bool intel_hda_setup_mixer()
{
    mixer_inst = mixer_open(0);
    if (!mixer_inst)
        return false;

    mixer_ctls.speaker_volume  = mixer_get_ctl_by_name(mixer_inst, SPEAKER_PLAYBACK_VOLUME);
    mixer_ctls.speaker_enable  = mixer_get_ctl_by_name(mixer_inst, SPEAKER_PLAYBACK_SWITCH);
    mixer_ctls.headphone_enable  = mixer_get_ctl_by_name(mixer_inst, HEADPHONE_PLAYBACK_SWITCH);
    mixer_ctls.headphone_volume  = mixer_get_ctl_by_name(mixer_inst, HEADPHONE_PLAYBACK_VOLUME);
    mixer_ctls.voice_volume = mixer_ctls.master_volume = 1.0f;
    return true;
}
