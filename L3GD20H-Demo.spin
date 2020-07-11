{
    --------------------------------------------
    Filename: L3GD20H-Demo.spin
    Author: Jesse Burt
    Description: Simple demo of the L3GD20H driver that
        outputs live data from the chip.
    Copyright (c) 2020
    Started Jul 11, 2020
    Updated Jul 11, 2020
    See end of file for terms of use.
    --------------------------------------------
}
'#define L3GD20H_I2C
#define L3GD20H_SPI

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

' I2C
    I2C_SCL     = 17
    I2C_SDA     = 19
    I2C_HZ      = 400_000

' SPI
    CS_PIN      = 16
    SCL_PIN     = 17
    SDO_PIN     = 18
    SDA_PIN     = 19
' --

OBJ

    cfg         : "core.con.boardcfg.flip"
    ser         : "com.serial.terminal.ansi"
    time        : "time"
    io          : "io"
    l3gd20h     : "sensor.gyroscope.3dof.l3gd20h.i2cspi"
    int         : "string.integer"

VAR

    long _overruns
    byte _ser_cog, _l3gd20h_cog

PUB Main | dispmode

    Setup
    ser.newline
    ser.hex(l3gd20h.deviceid, 8)
{
    l3gd20h.GyroOpMode(l3gd20h#NORMAL)
    l3gd20h.GyroDataRate(800)
    l3gd20h.GyroAxisEnabled(%111)
    l3gd20h.GyroScale(2000)

    repeat
        case ser.RxCheck
            "q", "Q":
                ser.Position(0, 5)
                ser.str(string("Halting"))
                l3gd20h.Stop
                time.MSleep(5)
                ser.Stop
                quit
            "r", "R":
                ser.Position(0, 3)
                repeat 2
                    ser.ClearLine
                    ser.Newline
                dispmode ^= 1


        ser.Position (0, 3)
        case dispmode
            0:
                GyroRaw
                ser.Newline
                TempRaw
            1:
                GyroCalc
                ser.Newline
                TempRaw

    FlashLED(LED, 100)

PUB GyroCalc | gx, gy, gz

    repeat until l3gd20h.GyroDataReady
    l3gd20h.GyroDPS (@gx, @gy, @gz)
    if l3gd20h.GyroDataOverrun
        _overruns++
    ser.Str (string("Gyro micro-DPS:  "))
    ser.Str (int.DecPadded (gx, 12))
    ser.Str (int.DecPadded (gy, 12))
    ser.Str (int.DecPadded (gz, 12))
    ser.Newline
    ser.Str (string("Overruns: "))
    ser.Dec (_overruns)

PUB GyroRaw | gx, gy, gz

    repeat until l3gd20h.GyroDataReady
    l3gd20h.GyroData (@gx, @gy, @gz)
    if l3gd20h.GyroDataOverrun
        _overruns++
    ser.Str (string("Raw Gyro:  "))
    ser.Str (int.DecPadded (gx, 7))
    ser.Str (int.DecPadded (gy, 7))
    ser.Str (int.DecPadded (gz, 7))
    ser.Newline
    ser.Str (string("Overruns: "))
    ser.Dec (_overruns)

PUB TempRaw

    ser.Str (string("Temperature: "))
    ser.Str (int.DecPadded (l3gd20h.Temperature, 7))
}
PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, %0000, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.Str (string("Serial terminal started", ser#CR, ser#LF))
#ifdef L3GD20H_SPI
    if _l3gd20h_cog := l3gd20h.Start (CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN)
        ser.Str (string("L3GD20H driver started (SPI)", ser#CR, ser#LF))
    else
#elseifdef L3GD20H_I2C
    if _l3gd20h_cog := l3gd20h.Startx (I2C_SCL, I2C_SDA, I2C_HZ)
        ser.Str (string("L3GD20H driver started (I2C)", ser#CR, ser#LF))
    else
#endif
        ser.Str (string("L3GD20H driver failed to start - halting", ser#CR, ser#LF))
        l3gd20h.Stop
        time.MSleep (5)
        ser.Stop
        FlashLED(LED, 500)

#include "lib.utility.spin"

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
