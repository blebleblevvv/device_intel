/*
 * Copyright (C) 2012 The Android Open Source Project
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

#include "HDAPS_AccelSensor.h"

#include <fcntl.h>
#include <errno.h>
#include <math.h>
#include <poll.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/select.h>

#include <cutils/log.h>

#include "common.h"

const struct sensor_t HDAPS_AccelSensor::sSensorInfo = {
    "ThinkPad HDAPS accelerometer data", "Lenovo", 1,
    SENSORS_ACCELERATION_HANDLE, SENSOR_TYPE_ACCELEROMETER,
    RANGE_A, CONVERT_A, 0.50f, 20000, {}
};

HDAPS_AccelSensor::HDAPS_AccelSensor()
    : SensorInputDev("ThinkPad HDAPS accelerometer data")
{
    mPendingEvent.version = sizeof(sensors_event_t);
    mPendingEvent.sensor = accel;
    mPendingEvent.type = SENSOR_TYPE_ACCELEROMETER;
    mPendingEvent.acceleration.status = SENSOR_STATUS_ACCURACY_LOW;
    memset(mPendingEvent.data, 0x00, sizeof(mPendingEvent.data));
}

HDAPS_AccelSensor::~HDAPS_AccelSensor() {
}

int HDAPS_AccelSensor::enable(int enabled)
{
    // Accelerometer is always on
    mEnabled = true;
    return 0;
}

int HDAPS_AccelSensor::setDelay(int64_t ns)
{
    // Cannot set delay or polling interval
    return -EINVAL;
}

int HDAPS_AccelSensor::processEvent(struct input_event const &event)
{
    // accelerometer can send relative movement events
    // but the HDAPS module always send EV_ABS events.
    if (event.type == EV_ABS) {
        // Values from accelerometer is always centered at ~512.
        // If axis is inverted, it will give you -512. So we need to
        // account for inverted axes.
        int value = event.value;

        switch (event.code) {
            case EVENT_TYPE_ACCEL_X:
                value = (value > 0) ? (value - CENTER_A) : (value + CENTER_A);
                mPendingEvent.acceleration.x = value * CONVERT_A_X;
                break;
            case EVENT_TYPE_ACCEL_Y:
                value = (value > 0) ? (value - CENTER_A) : (value + CENTER_A);
                mPendingEvent.acceleration.y = value * CONVERT_A_Y;
                break;
            case EVENT_TYPE_ACCEL_Z:
                value = (value > 0) ? (value - CENTER_A) : (value + CENTER_A);
                mPendingEvent.acceleration.z = value * CONVERT_A_Z;
                break;
        }
    }

    return 0;
}
