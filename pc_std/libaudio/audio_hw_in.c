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
#include <audio_utils/resampler.h>
#include "audio_hal.h"

struct intel_hda_stream_in {
    struct audio_stream_in stream;
    struct pcm_config config;
    struct pcm *pcm;
    struct resampler_itfe *resampler;
    struct resampler_buffer_provider buf_provider;
    bool standby;
    uint32_t requested_rate;
    struct intel_hda_audio_device *dev;
    int32_t read_status;
    size_t frames_in;
    int16_t *buffer;
};

#define DEFAULT_IN_PERIOD_SIZE    1024
#define DEFAULT_IN_PERIOD_COUNT  4
#define DEFAULT_IN_SAMPLING_RATE 44100

struct pcm_config pcm_config_input_def = {
    .channels = 2,
    .rate = DEFAULT_IN_SAMPLING_RATE,
    .period_size = DEFAULT_IN_PERIOD_SIZE,
    .period_count = DEFAULT_IN_PERIOD_COUNT,
    .format = PCM_FORMAT_S16_LE,
};

static int get_next_buffer(struct resampler_buffer_provider *buffer_provider,
                                   struct resampler_buffer* buffer);
static void release_buffer(struct resampler_buffer_provider *buffer_provider,
                                  struct resampler_buffer* buffer);
static ssize_t read_frames(struct intel_hda_stream_in *in, void *buffer, ssize_t frames);

/** audio_stream_in implementation **/
static uint32_t in_get_sample_rate(const struct audio_stream *stream)
{
    struct intel_hda_stream_in *in = (struct intel_hda_stream_in *)stream;
    _ENTER();
    _EXIT();
    return in->requested_rate;
}

static int in_set_sample_rate(struct audio_stream *stream, uint32_t rate)
{
    struct intel_hda_stream_in *in = (struct intel_hda_stream_in *)stream;
    _ENTER();
    LOGD("in_set_sample_rate %d\n", rate);
    in->requested_rate = rate;
    _EXIT();
    return 0;
}

static size_t in_get_buffer_size(const struct audio_stream *stream)
{
    struct intel_hda_stream_in *in = (struct intel_hda_stream_in *)stream;
    size_t size;
    _ENTER();
    size = intel_hda_get_input_buffer_size((struct audio_hw_device *)in->dev,
            in->requested_rate,
            AUDIO_FORMAT_PCM_16_BIT,in->config.channels);
    _EXIT();
    return size;
}

static uint32_t in_get_channels(const struct audio_stream *stream)
{
    struct intel_hda_stream_in *in = (struct intel_hda_stream_in *)stream;
    uint32_t channels;
    _ENTER();
    if (in->config.channels == 1) {
        channels = AUDIO_CHANNEL_IN_MONO;
    } else {
        channels = AUDIO_CHANNEL_IN_STEREO;
    }
    _EXIT();
    return channels;
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
     LOGD ("in_set_format:%d", format);
    _EXIT();
    return 0;
}

static int in_standby(struct audio_stream *stream)
{
    struct intel_hda_stream_in *in = (struct intel_hda_stream_in *)stream;
    _ENTER();
    if (!in->standby) {
        intel_hda_set_input_mode(false);
        if (in->pcm)
            pcm_close(in->pcm);
        in->pcm = NULL;
        in->standby = true;
    }
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
    LOGD ("in_set_gain:%f", gain);
    _EXIT();
    return 0;
}

static bool start_pcm_in_stream(struct intel_hda_stream_in *in)
{
    bool ret;

    _ENTER();
    intel_hda_set_input_mode(true);
    in->pcm =  pcm_open(0, 0, PCM_IN, &in->config);
    if (!in->pcm || !pcm_is_ready(in->pcm)) {
        ret = false;
        goto fail;
    }
    intel_hda_set_input_mode(true);

    /* if no supported sample rate is available, use the resampler */
    if (in->resampler) {
        in->resampler->reset(in->resampler);
        in->frames_in = 0;
    }

    ret = true;

fail:
    _EXIT();
    return ret;
}

static ssize_t in_read(struct audio_stream_in *stream, void* buffer,
                       size_t bytes)
{
    struct intel_hda_stream_in *in = (struct intel_hda_stream_in *)stream;
    size_t frames_rq = bytes / audio_stream_frame_size(&stream->common);
    int ret;

    _ENTER();

    if (in->standby) {
        start_pcm_in_stream(in);
        in->standby = false;
    }

    if (bytes < pcm_get_buffer_size(in->pcm)) {
        LOGE("in_read: Unexpected Size");
        ret = -EINVAL;
        goto fail;
    }

    if (in->resampler != NULL)
    {
        ret = read_frames(in,buffer,frames_rq);
    } else {
        ret = pcm_read(in->pcm, (void*)buffer, bytes);
    }

    if (ret < 0)
        goto fail;

    // Need to zero fill buffer if mic is muted.
    // This ensures apps read silence when mic is muted.
    if (in->dev->mic_mute)
        memset(buffer, 0, bytes);

    ret = bytes;

fail:
    _EXIT();
    return ret;
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
    struct intel_hda_audio_device *adev = (struct intel_hda_audio_device *)dev;
    _ENTER();
    adev->mic_mute = state;
    _EXIT();
    return 0;

}

int intel_hda_get_mic_mute(const struct audio_hw_device *dev, bool *state)
{
    struct intel_hda_audio_device *adev = (struct intel_hda_audio_device *)dev;
    _ENTER();
    *state = adev->mic_mute;
    _EXIT();
    return 0;
}

size_t intel_hda_get_input_buffer_size(const struct audio_hw_device *dev,
                                         uint32_t sample_rate, int format,
                                         int channel_count)
{
    size_t size;
    _ENTER();
    size = DEFAULT_IN_PERIOD_SIZE;
    _EXIT();
    return size*channel_count*sizeof(int16_t);
}

int intel_hda_open_input_stream(struct audio_hw_device *dev, uint32_t devices,
                                  int *format, uint32_t *channels,
                                  uint32_t *sample_rate,
                                  audio_in_acoustics_t acoustics,
                                  struct audio_stream_in **stream_in)
{
    struct intel_hda_audio_device *ladev = (struct intel_hda_audio_device *)dev;
    struct intel_hda_stream_in *in;
    int ret = 0;

    _ENTER();

    in = (struct intel_hda_stream_in *)calloc(1, sizeof(struct intel_hda_stream_in));
    if (!in) {
        ret = -ENOMEM;
        goto fail;
    }

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
    in->requested_rate = *sample_rate;
    in->standby = false;
    in->config = pcm_config_input_def;
    *stream_in = &in->stream;
    in->dev = (struct intel_hda_audio_device *)dev;
    LOGD("Requested sample rate %d default rate %d\n", in->requested_rate,
            in->config.rate);


    if (in->requested_rate != in->config.rate) {
        in->buf_provider.get_next_buffer = get_next_buffer;
        in->buf_provider.release_buffer = release_buffer;

        in->buffer = malloc(in->config.period_size *
                audio_stream_frame_size(&in->stream.common));
        if (!in->buffer) {
            ret = -ENOMEM;
            goto fail;
        }
        ret = create_resampler(in->config.rate,
                in->requested_rate,
                in->config.channels,
                RESAMPLER_QUALITY_DEFAULT,
                &in->buf_provider,
                &in->resampler);
        if (ret != 0) {
            LOGE("Unable to create resampler [%d]", ret);
            ret = -EINVAL;
        }
    }

fail:
    _EXIT();
    return ret;
}

void intel_hda_close_input_stream(struct audio_hw_device *dev,
                                   struct audio_stream_in *stream)
{
    struct intel_hda_stream_in *in = (struct intel_hda_stream_in *)stream;
    _ENTER();
    if (in->resampler) {
        free(in->buffer);
        release_resampler(in->resampler);
    }
    free(in);
    _EXIT();
}

static int get_next_buffer(struct resampler_buffer_provider *buffer_provider,
                                   struct resampler_buffer* buffer)
{
    struct intel_hda_stream_in *in;
    int ret = 0;
    _ENTER();
    if (buffer_provider == NULL || buffer == NULL){
        ret = -EINVAL;
        goto fail;
    }

    in = (struct intel_hda_stream_in *)((char *)buffer_provider -
            offsetof(struct intel_hda_stream_in, buf_provider));

    if (in->pcm == NULL) {
        buffer->raw = NULL;
        buffer->frame_count = 0;
        in->read_status = -ENODEV;
        ret = -ENODEV;
        goto fail;
    }

    if (in->frames_in == 0) {
        in->read_status = pcm_read(in->pcm,
                (void*)in->buffer,
                in->config.period_size *
                audio_stream_frame_size(&in->stream.common));
        ret = in->read_status;
        if (in->read_status != 0) {
            LOGE("get_next_buffer() pcm_read error %d", in->read_status);
            buffer->raw = NULL;
            buffer->frame_count = 0;
            goto fail;
        }
        in->frames_in = in->config.period_size;
    }

    buffer->frame_count = (buffer->frame_count > in->frames_in) ?
                                in->frames_in : buffer->frame_count;
    buffer->i16 = in->buffer + (in->config.period_size - in->frames_in) *
                                                in->config.channels;
fail:
    _EXIT();
    return ret;

}

static void release_buffer(struct resampler_buffer_provider *buffer_provider,
        struct resampler_buffer* buffer)
{
    struct intel_hda_stream_in *in;
    _ENTER();

    if (buffer_provider == NULL || buffer == NULL)
        goto fail;

    in = (struct intel_hda_stream_in *)((char *)buffer_provider -
            offsetof(struct intel_hda_stream_in, buf_provider));

    in->frames_in -= buffer->frame_count;

fail:
    _EXIT();
    return;
}

/* read_frames() reads frames from kernel driver, down samples to capture rate
 * if necessary and output the number of frames requested to the buffer specified */
static ssize_t read_frames(struct intel_hda_stream_in *in, void *buffer, ssize_t frames)
{
    ssize_t frames_wr = 0;
    ssize_t ret = 0;
    _ENTER();
    while (frames_wr < frames) {
        size_t frames_rd = frames - frames_wr;
        if (in->resampler != NULL) {
            in->resampler->resample_from_provider(in->resampler,
                    (int16_t *)((char *)buffer +
                            frames_wr * audio_stream_frame_size(&in->stream.common)),
                    &frames_rd);
        } else {
            struct resampler_buffer buf = {
                    { raw : NULL, },
                    frame_count : frames_rd,
            };
            get_next_buffer(&in->buf_provider, &buf);
            if (buf.raw != NULL) {
                memcpy((char *)buffer +
                        frames_wr * audio_stream_frame_size(&in->stream.common),
                        buf.raw,
                        buf.frame_count * audio_stream_frame_size(&in->stream.common));
                frames_rd = buf.frame_count;
            }
            release_buffer(&in->buf_provider, &buf);
        }
        /* in->read_status is updated by getNextBuffer() also called by
         * in->resampler->resample_from_provider() */
        if (in->read_status != 0) {
            ret = in->read_status;
            goto fail;
        }

        frames_wr += frames_rd;
    }
    ret = frames_wr;
fail:
    _EXIT();
    return ret;
}
