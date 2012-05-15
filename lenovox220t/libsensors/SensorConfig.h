/*
 * Copyright (C) 2008 The Android Open Source Project
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

#ifndef SENSOR_CONFIG_H
#define SENSOR_CONFIG_H

#include <hardware/hardware.h>
#include <hardware/sensors.h>

/* Maps senor id's to the sensor list */
enum {
    accel = 0,
    numSensorDrivers,
    numFds,
};



/*****************************************************************************/

/* Board specific sensor configs. */
#define GRAVITY 9.80665f
#define EVENT_TYPE_ACCEL_X          ABS_X
#define EVENT_TYPE_ACCEL_Y          ABS_Y
#define EVENT_TYPE_ACCEL_Z          ABS_Z

// Accelerometer value is 512 +/- 160
#define RANGE_A                     (2*GRAVITY_EARTH)
#define CENTER_A                    (512)
// conversion of acceleration data to SI units (m/s^2)
// X is inverted in X220t, Z is always 0
#define CONVERT_A                   (GRAVITY_EARTH / 160)
#define CONVERT_A_X                 (-CONVERT_A)
#define CONVERT_A_Y                 (CONVERT_A)
#define CONVERT_A_Z                 (CONVERT_A)

//Used in timespec_to_ns calculations
#define NSEC_PER_SEC    1000000000L


/*****************************************************************************/

#endif  // SENSOR_CONFIG_H
