{
    --------------------------------------------
    Filename: core.con.l3gd20h.spin
    Author:
    Description:
    Copyright (c) 2020
    Started Jul 11, 2020
    Updated Jul 11, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

' I2C
    I2C_MAX_FREQ        = 400_000
    SLAVE_ADDR          = $6A << 1
    MS_I2C              = 1 << 7

' SPI
    SCK_MAX_FREQ        = 10_000_000
    CPOL                = 1                                 ' 0 seems to work
    MS_SPI              = 1 << 6
    R                   = 1 << 7

' Register definitions
    WHO_AM_I            = $0F
        DEVID_RESP      = $D7

PUB Null
' This is not a top-level object
