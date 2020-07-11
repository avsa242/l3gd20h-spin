{
    --------------------------------------------
    Filename: sensor.gyroscope.l3gd20h.i2c.spin
    Author: Jesse Burt
    Description: Driver for the ST L3GD20H 3DoF gyroscope
    Copyright (c) 2020
    Started Jul 11, 2020
    Updated Jul 11, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 100_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

VAR


OBJ

#ifdef L3GD20H_I2C
    i2c : "com.i2c"                                             'PASM I2C Driver
#elseifdef L3GD20H_SPI
    spi : "com.spi.bitbang"
#else
#error "One of L3GD20H_I2C or L3GD20H_SPI must be defined"
#endif
    core: "core.con.l3gd20h.spin"                       'File containing your device's register set
    time: "time"                                                'Basic timing functions

PUB Null
' This is not a top-level object

#ifdef L3GD20H_I2C
PUB Start: okay                                                 'Default to "standard" Propeller I2C pins and 400kHz

    okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                time.MSleep (1)
                if i2c.present (SLAVE_WR)                       'Response from device?
                    if DeviceID == core#DEVID_RESP
                        return okay

    return FALSE                                                'If we got here, something went wrong
#elseifdef L3GD20H_SPI
PUB Start(CS_PIN, SCL_PIN, MOSI_PIN, MISO_PIN): okay

    if lookdown(CS_PIN: 0..31) and lookdown(SCL_PIN: 0..31) and lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31)
        if okay := spi.start(CS_PIN, SCL_PIN, MOSI_PIN, MISO_PIN)    'I2C Object Started?
            time.MSleep (1)
            if DeviceID == core#DEVID_RESP
                return okay

    return FALSE                                                'If we got here, something went wrong
#endif

PUB Stop
' Put any other housekeeping code here required/recommended by your device before shutting down
#ifdef L3GD20H_I2C
    i2c.terminate
#elseifdef L3GD20H_SPI
    spi.stop
#endif

PUB Defaults
' Set factory defaults

PUB DeviceID
' Read device identification
    readreg(core#WHO_AM_I, 1, @result)
{
PUB FIFOEnabled(enabled) | tmp
' Enable FIFO for gyro data
'   Valid values:
'       FALSE (0): FIFO disabled
'       TRUE (-1 or 1): FIFO enabled
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#REG_NAME, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := (||enabled & %1) << core#FLD_NAME
        OTHER:
            result := ((tmp >> core#FLD_NAME) & %1) * TRUE
            return

    tmp &= core#MASK_NAME
    tmp := (tmp | enabled)
    writeReg(core#REG_NAME, 1, @tmp)

PUB GyroAxisEnabled(mask) | tmp
' Enable gyroscope individual axes, by mask
'   Valid values:
'       0: Disable axis, 1: Enable axis
'       Bits %210
'             ZYX
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#REG_NAME, 1, @tmp)
    case mask
        %000..%111:
        OTHER:
            return tmp & core#BITS_NAME

    tmp &= core#MASK_NAME
    tmp := (tmp | mask) & core#REG_NAME_MASK
    writeReg(core#REG_NAME, 1, @tmp)

PUB GyroData(ptr_x, ptr_y, ptr_z) | tmp[2]
' Read gyroscope data
    longfill(@tmp, 0, 2)
    readReg(core#REG_NAME, 6, @tmp)

    long[ptr_x] := ~~tmp.word[0]
    long[ptr_y] := ~~tmp.word[1]
    long[ptr_z] := ~~tmp.word[2]

PUB GyroDataOverrun
' Indicates previously acquired data has been overwritten
'   Returns: TRUE (-1) if data has overrun/been overwritten, FALSE otherwise
    result := $00
    readReg(core#REG_NAME, 1, @result)
    result := (result >> core#FLD_NAME) & %1
    result := result * TRUE

PUB GyroDataRate(Hz) | tmp
' Set rate of data output, in Hz
'   Valid values: RANGE
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#REG_NAME, 1, @tmp)
    case Hz
        RANGE:
            Hz := lookdownz(Hz: RANGE) << core#FLD_NAME
        OTHER:
            tmp := (tmp >> core#FLD_NAME) & core#BITS_NAME
            result := lookupz(tmp: RANGE)
            return

    tmp &= core#MASK_NAME
    tmp := (tmp | Hz)
    writeReg(core#REG_NAME, 1, @tmp)

PUB GyroDataReady | tmp
' Indicates data is ready
'   Returns: TRUE (-1) if data ready, FALSE otherwise
    tmp := $00
    readReg(core#REG_NAME, 1, @tmp)
    tmp := (tmp >> core#FLD_NAME) & %1
    return tmp == 1

PUB GyroDPS(ptr_x, ptr_y, ptr_z) | tmp[2]
' Read gyroscope data, calculated
'   Returns: Angular rate in millionths of a degree per second
    bytefill(@tmp, $00, 8)
    readReg(core#REG_NAME, 6, @tmp)
    long[ptr_x] := (~~tmp.word[0] * _gyro_cnts_per_lsb)
    long[ptr_y] := (~~tmp.word[1] * _gyro_cnts_per_lsb)
    long[ptr_z] := (~~tmp.word[2] * _gyro_cnts_per_lsb)

PUB GyroOpMode(mode) | tmp
' Set operation mode
'   Valid values:
'       LIST STATES
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#REG_NAME, 1, @tmp)
    case mode
        STATE1:
            mode := (1 << core#FLD_NAME)
            tmp &= core#MASK_NAME
        OTHER:
            result := (tmp >> core#FLD_NAME) & %1
            return

    tmp := (tmp | mode)
    writeReg(core#REG_NAME, 1, @tmp)

PUB GyroScale(dps) | tmp
' Set gyro full-scale range, in degrees per second
'   Valid values: RANGE
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#REG_NAME, 1, @tmp)
    case dps
        RANGE:
            dps := lookdownz(dps: RANGE) << core#FLD_NAME
            _gyro_cnts_per_lsb := lookupz(dps >> core#FLD_NAME: ADC_LSBS_PER_UNIT)
        OTHER:
            tmp := (tmp >> core#FLD_NAME) & core#BITS_NAME
            result := lookupz(tmp: RANGE)
            return

    tmp &= core#MASK_NAME
    tmp := (tmp | dps)
    writeReg(core#REG_NAME, 1, @tmp)
}
PUB Reset
' Reset the device

PRI readReg(reg_nr, nr_bytes, buff_addr) | cmd_packet, tmp
'' Read num_bytes from the slave device into the address stored in buff_addr
    case reg_nr                                             ' Basic register validation
        $0F:
        $28..$2D:                                           ' If reading from accel data regs,
#ifdef L3GD20H_SPI
            reg_nr := core#MS_SPI                           '   set multi-byte read mode (SPI)
#elseifdef L3GD20H_I2C
            reg_nr |= core#MS_I2C                           '   set multi-byte read mode (I2C)
#endif
        OTHER:
            return FALSE

#ifdef L3GD20H_SPI
    reg_nr |= core#R
    spi.Write(TRUE, @reg_nr, 1, FALSE)                      ' Ask for reg, but don't deselect after
    spi.Read(buff_addr, nr_bytes, TRUE)                     ' Read in the data
#elseifdef L3GD20H_I2C
    cmd_packet.byte[0] := SLAVE_WR
    cmd_packet.byte[1] := reg_nr
    i2c.start
    i2c.wr_block (@cmd_packet, 2)
    i2c.start
    i2c.write (SLAVE_RD)
    i2c.rd_block (buff_addr, nr_bytes, TRUE)
    i2c.stop
#endif

PRI writeReg(reg_nr, nr_bytes, buff_addr) | cmd_packet, tmp
'' Write num_bytes to the slave device from the address stored in buff_addr
    case reg_nr                                                 'Basic register validation
        $00..$FF:
#ifdef L3GD20H_SPI
#elseifdef L3GD20H_I2C
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg_nr
            i2c.start
            i2c.wr_block (@cmd_packet, 2)
            repeat tmp from 0 to nr_bytes-1
                i2c.write (byte[buff_addr][tmp])
            i2c.stop
#endif
        OTHER:
            return


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
