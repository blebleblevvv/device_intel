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

struct intel_hda_stream_in {
    struct audio_stream_in stream;
};


/** audio_stream_in implementation **/
static uint32_t in_get_sample_rate(const struct audio_stream *stream)
{
    _ENTER();
    _EXIT();

    return 8000;
}

static int in_set_sample_rate(struct audio_stream *stream, uint32_t rate)
{
    return 0;
}

static size_t in_get_buffer_size(const struct audio_stream *stream)
{
    _ENTER();
    _EXIT();
    return 320;
}

static uint32_t in_get_channels(const struct audio_stream *stream)
{
    _ENTER();
    _EXIT();

    return AUDIO_CHANNEL_IN_MONO;
}

static int in_get_format(const struct audio_stream *stream)
{
    _ENTER();
    _EXIT();
    return AUDIO_FORMAT_PCM_16_BIT;
}

static int in_set_format(struct audio_stream *stream, int format)
{
    _ENTER();
    _EXIT();
    return 0;
}

static int in_standby(struct audio_stream *stream)
{
    _ENTER();
    _EXIT();
    return 0;
}

static int in_dump(const struct audio_stream *stream, int fd)
{
    _ENTER();
    _EXIT();
    return 0;
}

static int in_set_parameters(struct audio_stream *stream, const char *kvpairs)
{
    _ENTER();
    _EXIT();
    return 0;
}

static char * in_get_parameters(const struct audio_stream *stream,
                                const char *keys)
{
    _ENTER();
    _EXIT();
    return strdup("");
}

static int in_set_gain(struct audio_stream_in *stream, float gain)
{
    _ENTER();
    _EXIT();
    return 0;
}

static ssize_t in_read(struct audio_stream_in *stream, void* buffer,
                       size_t bytes)
{
    _ENTER();

    /* XXX: fake timing for audio input */
    usleep(bytes * 1000000 / audio_stream_frame_size(&stream->common) /
           in_get_sample_rate(&stream->common));
    _EXIT();
    return bytes;
}

static uint32_t in_get_input_frames_lost(struct audio_stream_in *stream)
{
    _ENTER();
    _EXIT();
    return 0;
}

static int in_add_audio_effect(const struct audio_stream *stream, effect_handle_t effect)
{
    _ENTER();
    _EXIT();
    return 0;
}

static int in_remove_audio_effect(const struct audio_stream *stream, effect_handle_t effect)
{
    _ENTER();
    _EXIT();
    return 0;
}

// Inteface functions

int intel_hda_set_mic_mute(struct audio_hw_device *dev, bool state)
{
    _ENTER();
    _EXIT();
    return -ENOSYS;
}

int intel_hda_get_mic_mute(const struct audio_hw_device *dev, bool *state)
{
    _ENTER();
    _EXIT();
    return -ENOSYS;
}

size_t intel_hda_get_input_buffer_size(const struct audio_hw_device *dev,
                                         uint32_t sample_rate, int format,
                                         int channel_count)
{
    _ENTER();
    _EXIT();
    return 320;
}

int intel_hda_open_input_stream(struct audio_hw_device *dev, uint32_t devices,
                                  int *format, uint32_t *channels,
                                  uint32_t *sample_rate,
                                  audio_in_acoustics_t acoustics,
                                  struct audio_stream_in **stream_in)
{
    struct intel_hda_audio_device *ladev = (struct intel_hda_audio_device *)dev;
    struct intel_hda_stream_in *in;
    int ret;

    _ENTER();

    in = (struct intel_hda_stream_in *)calloc(1, sizeof(struct intel_hda_stream_in));
    if (!in)
        return -ENOMEM;

    in->stream.common.get_sample_rate = in_get_sample_rate;
    in->stream.common.set_sample_rate = in_set_sample_rate;
    in->stream.common.get_buffer_size = in_get_buffer_size;
    in->stream.common.get_channels = in_get_channels;
    in->stream.common.get_format = in_get_format;
    in->stream.common.set_format = in_set_format;
    in->stream.common.standby = in_standby;
    in->stream.common.dump = in_dump;
    in->stream.common.set_parameters = in_set_parameters;
    in->stream.common.get_parameters = in_get_parameters;
    in->stream.common.add_audio_effect = in_add_audio_effect;
    in->stream.common.remove_audio_effect = in_remove_audio_effect;
    in->stream.set_gain = in_set_gain;
    in->stream.read = in_read;
    in->stream.get_input_frames_lost = in_get_input_frames_lost;
    *stream_in = &in->stream;
    _EXIT();
    return 0;
}

void intel_hda_close_input_stream(struct audio_hw_device *dev,
                                   struct audio_stream_in *in)
{
    _ENTER();
    _EXIT();
}
