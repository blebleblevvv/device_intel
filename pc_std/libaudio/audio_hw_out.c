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

struct intel_hda_stream_out {
    struct audio_stream_out stream;
    struct pcm_config config;
    struct pcm *pcm;
    bool standby;
};

#define DEFAULT_OUT_SAMPLING_RATE   44100
#define DEFAULT_OUT_PERIOD_SIZE     1024
#define DEFAULT_OUT_PERIOD_COUNT    4

struct pcm_config pcm_config_def = {
    .channels = 2,
    .rate = DEFAULT_OUT_SAMPLING_RATE,
    .period_size = DEFAULT_OUT_PERIOD_SIZE,
    .period_count = DEFAULT_OUT_PERIOD_COUNT,
    .format = PCM_FORMAT_S16_LE,
};



static uint32_t out_get_sample_rate(const struct audio_stream *stream)
{
    _ENTER();
    _EXIT();
    return DEFAULT_OUT_SAMPLING_RATE;
}

static int out_set_sample_rate(struct audio_stream *stream, uint32_t rate)
{
    _ENTER();
    _EXIT();
    return 0;
}

static size_t out_get_buffer_size(const struct audio_stream *stream)
{
    struct intel_hda_stream_out *out = (struct intel_hda_stream_out *)stream;
    _ENTER();
    _EXIT();
    if (out->pcm)
        return pcm_get_buffer_size(out->pcm);
    else
        return DEFAULT_OUT_PERIOD_SIZE*DEFAULT_OUT_PERIOD_COUNT;
}

static uint32_t out_get_channels(const struct audio_stream *stream)
{
    _ENTER();
    _EXIT();
    return AUDIO_CHANNEL_OUT_STEREO;
}

static int out_get_format(const struct audio_stream *stream)
{
    _ENTER();
    _EXIT();
    return AUDIO_FORMAT_PCM_16_BIT;
}

static int out_set_format(struct audio_stream *stream, int format)
{
    _ENTER();
    _EXIT();
    return 0;
}

static int out_standby(struct audio_stream *stream)
{
    struct intel_hda_stream_out *out = (struct intel_hda_stream_out *)stream;
    _ENTER();
    if (!out->standby) {
        pcm_close(out->pcm);
        out->standby = true;
        }
    _EXIT();
    return 0;
}

static int out_dump(const struct audio_stream *stream, int fd)
{
    _ENTER();
    _EXIT();
    return 0;
}

static int out_set_parameters(struct audio_stream *stream, const char *kvpairs)
{
    _ENTER();
    _EXIT();
    return 0;
}

static char * out_get_parameters(const struct audio_stream *stream, const char *keys)
{
    _ENTER();
    _EXIT();
    return strdup("");
}

static uint32_t out_get_latency(const struct audio_stream_out *stream)
{
    _ENTER();
    _EXIT();
    return 0;
}

static bool start_pcm_stream(struct intel_hda_stream_out *out)
{
    intel_hda_set_output_mode();
    out->pcm =  pcm_open(0, 0, PCM_OUT, &out->config);
    if (!out->pcm || !pcm_is_ready(out->pcm)) {
        return false;
        }
    return true;
}

static ssize_t out_write(struct audio_stream_out *stream, const void* buffer,
                         size_t bytes)
{
    struct intel_hda_stream_out *out = (struct intel_hda_stream_out *)stream;
    int ret;

    _ENTER();

    if (out->standby) {
        start_pcm_stream(out);
        out->standby = false;
    }
    if (bytes > pcm_get_buffer_size(out->pcm)) {
        ALOGE("out_write: Unexpected Size");
        ret = -EINVAL;
        goto fail;
    }
    ret = pcm_write(out->pcm, (void*)buffer, bytes);

fail:
    _EXIT();
    return ret;
}

static int out_get_render_position(const struct audio_stream_out *stream,
                                   uint32_t *dsp_frames)
{
    _ENTER();
    _EXIT();

    return -EINVAL;
}

static int out_add_audio_effect(const struct audio_stream *stream, effect_handle_t effect)
{
    return 0;
}

static int out_remove_audio_effect(const struct audio_stream *stream, effect_handle_t effect)
{
    _ENTER();
    _EXIT();

    return 0;
}

// Interface functions
int intel_hda_set_mode(struct audio_hw_device *dev, int mode)
{
    _ENTER();
    _EXIT();

    return 0;
}

static int out_set_volume(struct audio_stream_out *stream, float left,
            float right)
{
    return -ENOSYS;
}

int intel_hda_open_output_stream(struct audio_hw_device *dev,
                                   uint32_t devices, int *format,
                                   uint32_t *channels, uint32_t *sample_rate,
                                   struct audio_stream_out **stream_out)
{
    struct intel_hda_audio_device *ladev = (struct intel_hda_audio_device *)dev;
    struct intel_hda_stream_out *out;
    int ret;

    _ENTER();

    out = (struct intel_hda_stream_out *)calloc(1, sizeof(struct intel_hda_stream_out));
    if (!out) {
        ret = -ENOMEM;
        goto fail;
    }

    out->stream.common.get_sample_rate = out_get_sample_rate;
    out->stream.common.set_sample_rate = out_set_sample_rate;
    out->stream.common.get_buffer_size = out_get_buffer_size;
    out->stream.common.get_channels = out_get_channels;
    out->stream.common.get_format = out_get_format;
    out->stream.common.set_format = out_set_format;
    out->stream.common.standby = out_standby;
    out->stream.common.dump = out_dump;
    out->stream.common.set_parameters = out_set_parameters;
    out->stream.common.get_parameters = out_get_parameters;
    out->stream.common.add_audio_effect = out_add_audio_effect;
    out->stream.common.remove_audio_effect = out_remove_audio_effect;
    out->stream.get_latency = out_get_latency;
    out->stream.set_volume = out_set_volume;
    out->stream.write = out_write;
    out->stream.get_render_position = out_get_render_position;

    out->config = pcm_config_def;
    out->standby = true;
    *format = out_get_format(&out->stream.common);
    *channels = out_get_channels(&out->stream.common);
    *sample_rate = out_get_sample_rate(&out->stream.common);
    *stream_out = &out->stream;

    ret = 0;

fail:
    _EXIT();
    return ret;
}

void intel_hda_close_output_stream(struct audio_hw_device *dev,
                                     struct audio_stream_out *stream)
{
    _ENTER();
    _EXIT();

    free(stream);
}
