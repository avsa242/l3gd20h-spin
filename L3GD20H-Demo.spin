{
----------------------------------------------------------------------------------------------------
    Filename:       L3GD20H-Demo.spin
    Description:    Demo of the L3GD20H driver
        * 3DoF data output
    Author:         Jesse Burt
    Started:        Jul 11, 2020
    Updated:        Jul 5, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

' Uncomment one of the pairs of lines below for alternate connectivity options.
' The default if nothing is specified, is a PASM-based I2C engine
' NOTE: If using I2C, CS should be tied high.

' Uncomment the two lines below to use SPI
'#define L3GD20H_SPI
'#pragma exportdef(L3GD20H_SPI)

' Uncomment the two lines below to use SPI (bytecode-based engine)
'#define L3GD20H_SPI_BC
'#pragma exportdef(L3GD20H_SPI_BC)

' Uncomment the two lines below to use I2C (bytecode-based engine)
'#define L3GD20H_I2C_BC
'#pragma exportdef(L3GD20H_I2C_BC)

CON

    _clkmode    = cfg._clkmode
    _xinfreq    = cfg._xinfreq


OBJ

    cfg:    "boardcfg.flip"
    time:   "time"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    sensor: "sensor.gyroscope.3dof.l3gd20h" | {I2C} SCL=28, SDA=29, I2C_FREQ=400_000, I2C_ADDR=0,...
                                            {SPI} CS=0, SCK=1, MOSI=2, MISO=3, SPI_FREQ=1_000_000
    ' NOTE: When using I2C, I2C_ADDR can be 0, or any non-zero value to use the alternate address.


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"L3GD20H driver started")
    else
        ser.strln(@"L3GD20H driver failed to start - halting")
        repeat

    sensor.preset_active()

    repeat
        ser.pos_xy(0, 3)
        show_gyro_data()
        if ( ser.getchar_noblock() == "c" )
            cal_gyro()

#include "gyrodemo.common.spinh"                ' use code common to all gyro demos

DAT
{
Copyright 2024 Jesse Burt

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

