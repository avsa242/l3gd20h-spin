{
    --------------------------------------------
    Filename: L3GD20H-Demo.spin
    Author: Jesse Burt
    Description: L3GD20H driver demo
        * 3DoF data output
    Copyright (c) 2022
    Started Jul 11, 2020
    Updated Nov 20, 2022
    See end of file for terms of use.
    --------------------------------------------

    Build-time symbols supported by driver:
        -DL3GD20H_SPI
        -DL3GD20H_SPI_BC
        -DL3GD20H_I2C (default if none specified)
        -DL3GD20H_I2C_BC
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200

    { I2C configuration }
    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000                       ' max is 400_000
    ADDR_BITS   = 0                             ' 0, 1
    ' NOTE: Be sure ADDR_BITS matches the state of the SA0 pin (0 if it's pulled low, 1 if high)

    { SPI configuration }
    CS_PIN      = 0
    SCK_PIN     = 1
    MOSI_PIN    = 2
    MISO_PIN    = 3
' --

OBJ

    cfg: "boardcfg.flip"
    sensor: "sensor.gyroscope.3dof.l3gd20h"
    ser: "com.serial.terminal.ansi"
    time: "time"

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(10)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

#ifdef L3GD20H_SPI
    if (sensor.startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN))
#else
    if (sensor.startx(SCL_PIN, SDA_PIN, I2C_FREQ, ADDR_BITS))
#endif
        ser.strln(string("L3GD20H driver started"))
    else
        ser.strln(string("L3GD20H driver failed to start - halting"))
        repeat

    sensor.preset_active{}

    repeat
        ser.pos_xy(0, 3)
        show_gyro_data{}
        if (ser.rx_check{} == "c")
            cal_gyro{}

#include "gyrodemo.common.spinh"                 ' code common to all IMU demos

DAT
{
Copyright 2022 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

