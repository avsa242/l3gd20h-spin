{
    --------------------------------------------
    Filename: L3GD20H-Demo.spin
    Author: Jesse Burt
    Description: Demo of the L3GD20H driver
    Copyright (c) 2021
    Started Aug 12, 2017
    Updated Jan 26, 2021
    See end of file for terms of use.
    --------------------------------------------
}
' Uncomment one of the lines below to select an interface
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
    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 400_000

' SPI
    CS_PIN      = 0
    SCL_PIN     = 1
    SDO_PIN     = 2
    SDA_PIN     = 3
' --

    DAT_X_COL   = 20
    DAT_Y_COL   = DAT_X_COL + 15
    DAT_Z_COL   = DAT_Y_COL + 15

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
    gyro    : "sensor.gyroscope.3dof.l3gd20h.i2cspi"

PUB Main{}

    setup{}
    gyro.preset_normal{}                        ' default settings, but enable
                                                ' measurements, and set scale
                                                ' factor

    repeat
        ser.position(0, 3)
        gyrocalc{}

        if ser.rxcheck{} == "c"                 ' press the 'c' key in the demo
            calibrate{}                         ' to calibrate sensor offsets

PUB GyroCalc{} | gx, gy, gz

    repeat until gyro.gyrodataready{}           ' wait for new sensor data set
    gyro.gyrodps(@gx, @gy, @gz)                 ' read calculated sensor data
    ser.str(string("Gyro (dps):"))
    ser.positionx(DAT_X_COL)
    decimal(gx, 1000000)                        ' data is in micro-dps; display
    ser.positionx(DAT_Y_COL)                    ' it as if it were a float
    decimal(gy, 1000000)
    ser.positionx(DAT_Z_COL)
    decimal(gz, 1000000)
    ser.clearline{}
    ser.newline{}

PUB Calibrate{}

    ser.position(0, 7)
    ser.str(string("Calibrating..."))
    gyro.calibrategyro{}
    ser.positionx(0)
    ser.clearline{}

PRI Decimal(scaled, divisor) | whole[4], part[4], places, tmp, sign
' Display a scaled up number as a decimal
'   Scale it back down by divisor (e.g., 10, 100, 1000, etc)
    whole := scaled / divisor
    tmp := divisor
    places := 0
    part := 0
    sign := 0
    if scaled < 0
        sign := "-"
    else
        sign := " "

    repeat
        tmp /= 10
        places++
    until tmp == 1
    scaled //= divisor
    part := int.deczeroed(||(scaled), places)

    ser.char(sign)
    ser.dec(||(whole))
    ser.char(".")
    ser.str(part)
    ser.chars(" ", 5)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
#ifdef L3GD20H_SPI
    if gyro.startx(CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN)
        ser.strln(string("L3GD20H driver started (SPI)"))
    else
#elseifdef L3GD20H_I2C
    if gyro.startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.strln(string("L3GD20H driver started (I2C)"))
    else
#endif
        ser.strln(string("L3GD20H driver failed to start - halting"))
        gyro.stop{}
        time.msleep(5)
        ser.stop{}
        repeat

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
