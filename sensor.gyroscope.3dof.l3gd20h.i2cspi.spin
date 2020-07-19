{
    --------------------------------------------
    Filename: sensor.gyroscope.l3gd20h.i2c.spin
    Author: Jesse Burt
    Description: Driver for the ST L3GD20H 3DoF gyroscope
    Copyright (c) 2020
    Started Jul 11, 2020
    Updated Jul 18, 2020
    See end of file for terms of use.
    --------------------------------------------
}
CON

    SLAVE_WR            = core#SLAVE_ADDR
    SLAVE_RD            = core#SLAVE_ADDR|1

    DEF_SCL             = 28
    DEF_SDA             = 29
    DEF_HZ              = 100_000
    I2C_MAX_FREQ        = core#I2C_MAX_FREQ

' Indicate to user apps how many Degrees of Freedom each sub-sensor has
'   (also imply whether or not it has a particular sensor)
    ACCEL_DOF           = 0
    GYRO_DOF            = 3
    MAG_DOF             = 0
    BARO_DOF            = 0
    DOF                 = ACCEL_DOF + GYRO_DOF + MAG_DOF + BARO_DOF

' High-pass filter modes
    #0, HPF_NORMAL_RES, HPF_REF, HPF_NORMAL, HPF_AUTO_RES

' Operation modes
    #0, POWERDOWN, SLEEP, NORMAL

' Interrupt pin active states
    #0, INTLVL_LOW, INTLVL_HIGH

' Interrupt pin output type
    #0, INT_PP, INT_OD

' Gyro data byte order
    #0, LSBFIRST, MSBFIRST

' Operation modes
    STANDBY             = 0
    MEASURE             = 1

    R                   = 0
    W                   = 1

VAR

    long _gyro_cnts_per_lsb

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
    BlockUpdateEnabled(FALSE)
    DataByteOrder(LSBFIRST)
    FIFOEnabled(FALSE)
    GyroAxisEnabled(%111)
    GyroDataRate(100)
    GyroOpMode(POWERDOWN)
    GyroScale(245)
    HighPassFilterEnabled(FALSE)
    HighPassFilterFreq(8_00)
    HighPassFilterMode(HPF_NORMAL_RES)
    Int1Mask(%00)
    Int2Mask(%0000)
    IntActiveState(INTLVL_LOW)
    IntOutputType(INT_PP)

PUB AccelAxisEnabled(axis_mask)
' Dummy method

PUB AccelBias(x, y, z, rw)
' Dummy method

PUB AccelData(x, y, z)
' Dummy method

PUB AccelDataRate(Hz)
' Dummy method

PUB AccelDataReady
' Dummy method

PUB AccelDataOverrun
' Dummy method

PUB AccelG(x, y, z)
' Dummy method

PUB AccelScale(scale)
' Dummy method

PUB BlockUpdateEnabled(enabled): tmp
' Enable block updates
'   Valid values:
'      *FALSE (0): Update gyro data outputs continuously
'       TRUE (-1 or 1): Pause further updates until both MSB and LSB of data have been read
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#CTRL4, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := (||enabled & %1) << core#FLD_BDU
        OTHER:
            return ((tmp >> core#FLD_BDU) & %1) * TRUE

    tmp &= core#MASK_BDU
    tmp := (tmp | enabled)
    writeReg(core#CTRL4, 1, @tmp)

PUB Calibrate
' Dummy method

PUB CalibrateXLG
' Dummy method

PUB CalibrateMag(samples)
' Dummy method

PUB DataByteOrder(lsb_msb_first): tmp
' Set byte order of gyro data
'   Valid values:
'      *LSBFIRST (0), MSBFIRST (1)
'   Any other value polls the chip and returns the current setting
'   NOTE: Intended only for use when utilizing raw gyro data from GyroData method.
'       GyroDPS expects the data order to be LSBFIRST
    tmp := $00
    readReg(core#CTRL4, 1, @tmp)
    case lsb_msb_first
        LSBFIRST, MSBFIRST:
            lsb_msb_first <<= core#FLD_BLE
        OTHER:
            return (tmp >> core#FLD_BLE) & %1

    tmp &= core#MASK_BLE
    tmp := (tmp | lsb_msb_first)
    writeReg(core#CTRL4, 1, @tmp)

PUB DeviceID: id
' Read device identification
    readreg(core#WHO_AM_I, 1, @id)

PUB FIFOEnabled(enabled): tmp
' Enable FIFO for gyro data
'   Valid values:
'      *FALSE (0): FIFO disabled
'       TRUE (-1 or 1): FIFO enabled
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#CTRL5, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := (||enabled & %1) << core#FLD_FIFO_EN
        OTHER:
            return ((tmp >> core#FLD_FIFO_EN) & %1) * TRUE

    tmp &= core#MASK_FIFO_EN
    tmp := (tmp | enabled)
    writeReg(core#CTRL5, 1, @tmp)

PUB GyroAxisEnabled(mask): tmp
' Enable gyroscope individual axes, by mask
'   Valid values:
'       0: Disable axis, 1: Enable axis
'       Bits %210
'             ZYX (default: %111)
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#CTRL1, 1, @tmp)
    case mask
        %000..%111:
        OTHER:
            return tmp & core#BITS_XYZEN

    tmp &= core#MASK_XYZEN
    tmp := (tmp | mask) & core#CTRL1_MASK
    writeReg(core#CTRL1, 1, @tmp)

PUB GyroBias(gxBias, gyBias, gzBias, rw)
' Read or write/manually set Gyroscope calibration offset values
'   Valid values:
'       rw:
'           R (0), W (1)
'       gxBias, gyBias, gzBias:
'           -32768..32767
'   NOTE: When rw is set to READ, gxBias, gyBias and gzBias must be addresses of respective variables to hold the returned calibration offset values.
    case rw
        R:
            long[gxBias] := _gBiasRaw[X_AXIS]
            long[gyBias] := _gBiasRaw[Y_AXIS]
            long[gzBias] := _gBiasRaw[Z_AXIS]

        W:
            case gxBias
                -32768..32767:
                    _gBiasRaw[X_AXIS] := gxBias
                OTHER:

            case gyBias
                -32768..32767:
                    _gBiasRaw[Y_AXIS] := gyBias
                OTHER:

            case gzBias
                -32768..32767:
                    _gBiasRaw[Z_AXIS] := gzBias
                OTHER:

PUB GyroData(ptr_x, ptr_y, ptr_z) | tmp[2]
' Read gyroscope data
    bytefill(@tmp, $00, 8)
    readReg(core#OUT_X_L, 6, @tmp)

    long[ptr_x] := ~~tmp.word[0]
    long[ptr_y] := ~~tmp.word[1]
    long[ptr_z] := ~~tmp.word[2]

PUB GyroDataOverrun: flag
' Indicates previously acquired data has been overwritten
'   Returns: TRUE (-1) if data has overrun/been overwritten, FALSE otherwise
    flag := $00
    readReg(core#STATUS, 1, @flag)
    flag := ((flag >> core#FLD_ZYXOR) & %1) == 1

PUB GyroDataRate(Hz): tmp
' Set rate of data output, in Hz
'   Valid values: *100, 200, 400, 800
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#CTRL1, 1, @tmp)
    case Hz
        100, 200, 400, 800:
            Hz := lookdownz(Hz: 100, 200, 400, 800) << core#FLD_DR
        OTHER:
            tmp := (tmp >> core#FLD_DR) & core#BITS_DR
            return lookupz(tmp: 100, 200, 400, 800)

    tmp &= core#MASK_DR
    tmp := (tmp | Hz)
    writeReg(core#CTRL1, 1, @tmp)

PUB GyroDataReady: ready
' Indicates data is ready
'   Returns: TRUE (-1) if data ready, FALSE otherwise
    ready := $00
    readReg(core#STATUS, 1, @ready)
    return ((ready >> core#FLD_ZYXDA) & %1) == 1

PUB GyroDPS(ptr_x, ptr_y, ptr_z) | tmp[2]
' Read gyroscope data, calculated
'   Returns: Angular rate in millionths of a degree per second
    bytefill(@tmp, $00, 8)
    readReg(core#OUT_X_L, 6, @tmp)
    long[ptr_x] := (~~tmp.word[0] * _gyro_cnts_per_lsb)
    long[ptr_y] := (~~tmp.word[1] * _gyro_cnts_per_lsb)
    long[ptr_z] := (~~tmp.word[2] * _gyro_cnts_per_lsb)

PUB GyroOpMode(mode): curr_mode
' Set operation mode
'   Valid values:
'      *POWERDOWN (0): Power down - lowest power state
'       SLEEP (1): Sleep - sensor enabled, but X, Y, Z outputs disabled
'       NORMAL (2): Normal - active operating state
'   Any other value polls the chip and returns the current setting
    curr_mode := $00
    readReg(core#CTRL1, 1, @curr_mode)
    case mode
        POWERDOWN:
            curr_mode &= core#MASK_PD
        SLEEP:
            mode := (1 << core#FLD_PD)
            curr_mode &= core#MASK_XYZEN
        NORMAL:
            mode := (1 << core#FLD_PD)
            curr_mode &= core#MASK_PD
        OTHER:
            result := (curr_mode >> core#FLD_PD) & %1
            if curr_mode & core#BITS_XYZEN
                result += 1
            return

    curr_mode := (curr_mode | mode)
    writeReg(core#CTRL1, 1, @curr_mode)

PUB GyroScale(dps): curr_scale
' Set gyro full-scale range, in degrees per second
'   Valid values: *245, 500, 2000
'   Any other value polls the chip and returns the current setting
    curr_scale := $00
    readReg(core#CTRL4, 1, @curr_scale)
    case dps
        245, 500, 2000:
            dps := lookdownz(dps: 245, 500, 2000) << core#FLD_FS
            _gyro_cnts_per_lsb := lookupz(dps >> core#FLD_FS: 8_750, 17_500, 70_000)
        OTHER:
            curr_scale := (curr_scale >> core#FLD_FS) & core#BITS_FS
            return lookupz(curr_scale: 245, 500, 2000)

    curr_scale &= core#MASK_FS
    curr_scale := (curr_scale | dps)
    writeReg(core#CTRL4, 1, @curr_scale)

PUB HighPassFilterEnabled(enabled): tmp
' Enable high-pass filter for gyro data
'   Valid values:
'      *FALSE (0): High-pass filter disabled
'       TRUE (-1 or 1): High-pass filter enabled
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#CTRL5, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := (||enabled & %1) << core#FLD_HPEN
        OTHER:
            return ((tmp >> core#FLD_HPEN) & %1) * TRUE

    tmp &= core#MASK_HPEN
    tmp := (tmp | enabled)
    writeReg(core#CTRL5, 1, @tmp)

PUB HighPassFilterFreq(freq): tmp
' Set high-pass filter frequency, in Hz
'    Valid values:
'       If ODR=100Hz: *8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01
'       If ODR=200Hz: *15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02
'       If ODR=400Hz: *30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05
'       If ODR=800Hz: *56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10
'       NOTE: Values are fractional values expressed as whole numbers. The '_' should be interpreted as a decimal point.
'           Examples: 8_00 = 8Hz, 0_50 = 0.5Hz, 0_02 = 0.02Hz
    tmp := $00
    readReg(core#CTRL2, 1, @tmp)
    case GyroDataRate(-2)
        100:
            case freq
                8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01:
                    freq := lookdownz(freq: 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01) << core#FLD_HPCF
                OTHER:
                    tmp := (tmp >> core#FLD_HPCF) & core#BITS_HPCF
                    return lookupz(tmp: 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01)

        200:
            case freq
                15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02:
                    freq := lookdownz(freq: 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02) << core#FLD_HPCF
                OTHER:
                    tmp := (tmp >> core#FLD_HPCF) & core#BITS_HPCF
                    return lookupz(tmp: 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02)

        400:
            case freq
                30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05:
                    freq := lookdownz(freq: 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05) << core#FLD_HPCF
                OTHER:
                    tmp := (tmp >> core#FLD_HPCF) & core#BITS_HPCF
                    return lookupz(tmp: 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05)

        800:
            case freq
                56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10:
                    freq := lookdownz(freq: 56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10) << core#FLD_HPCF
                OTHER:
                    tmp := (tmp >> core#FLD_HPCF) & core#BITS_HPCF
                    return lookupz(tmp: 56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10)

    tmp &= core#MASK_HPCF
    tmp := (tmp | freq)
    writeReg(core#CTRL2, 1, @tmp)

PUB HighPassFilterMode(mode): tmp
' Set data output high pass filter mode
'   Valid values:
'      *HPF_NORMAL_RES (0): Normal mode (reset reading HP_RESET_FILTER) XXX - clarify/expand
'       HPF_REF (1): Reference signal for filtering
'       HPF_NORMAL (2): Normal
'       HPF_AUTO_RES (3): Autoreset on interrupt
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#CTRL2, 1, @tmp)
    case mode
        HPF_NORMAL_RES, HPF_REF, HPF_NORMAL, HPF_AUTO_RES:
            mode <<= core#FLD_HPM
        OTHER:
            return (tmp >> core#FLD_HPM) & core#BITS_HPM

    tmp &= core#MASK_HPM
    tmp := (tmp | mode)
    writeReg(core#CTRL2, 1, @tmp)

PUB Int1Mask(func_mask): tmp
' Set interrupt/function mask for INT1 pin
'   Valid values:
'       Bit 10   10
'           ||   ||
'    Range %00..%11
'       Bit 1: Interrupt enable (*0: Disable, 1: Enable)
'       Bit 0: Boot status (*0: Disable, 1: Enable)
    tmp := $00
    readReg(core#CTRL3, 1, @tmp)
    case func_mask
        %00..%11:
            func_mask <<= core#FLD_INT1
        OTHER:
            return (tmp >> core#FLD_INT1) & core#BITS_INT1

    tmp &= core#MASK_INT1
    tmp := (tmp | func_mask)
    writeReg(core#CTRL3, 1, @tmp)

PUB Int2Mask(func_mask): tmp
' Set interrupt/function mask for INT2 pin
'   Valid values:
'       Bit 3210   3210
'           ||||   ||||
'    Range %0000..%1111 (default value: %0000)
'       Bit 3: Data ready
'       Bit 2: FIFO watermark
'       Bit 1: FIFO overrun
'       Bit 0: FIFO empty
    tmp := $00
    readReg(core#CTRL3, 1, @tmp)
    case func_mask
        %0000..%1111:
        OTHER:
            return tmp & core#BITS_INT2

    tmp &= core#MASK_INT2
    tmp := (tmp | func_mask)
    writeReg(core#CTRL3, 1, @tmp)

PUB IntActiveState(state): tmp
' Set active state for interrupts
'   Valid values: *INTLVL_LOW (0), INTLVL_HIGH (1)
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#CTRL3, 1, @tmp)
    case state
        INTLVL_LOW, INTLVL_HIGH:
            state := ((state ^ 1) & %1) << core#FLD_H_LACTIVE
        OTHER:
            return (((tmp >> core#FLD_H_LACTIVE) ^ 1) & %1)

    tmp &= core#MASK_H_LACTIVE
    tmp := (tmp | state)
    writeReg(core#CTRL3, 1, @tmp)

PUB Interrupt
' Dummy method

PUB IntMask(func_mask)
' Dummy method

PUB IntOutputType(pp_od): tmp
' Set interrupt pin output type
'   Valid values:
'      *INT_PP (0): Push-pull
'       INT_OD (1): Open-drain
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#CTRL3, 1, @tmp)
    case pp_od
        INT_PP, INT_OD:
            pp_od := pp_od << core#FLD_PP_OD
        OTHER:
            return (tmp >> core#FLD_PP_OD) & %1

    tmp &= core#MASK_PP_OD
    tmp := (tmp | pp_od)
    writeReg(core#CTRL3, 1, @tmp)

PUB MagBias(x, y, z, rw)
' Dummy method

PUB MagData(x, y, z)
' Dummy method

PUB MagDataRate(hz)
' Dummy method

PUB MagDataReady
' Dummy method

PUB MagGauss(x, y, z)
' Dummy method

PUB MagScale(scale)
' Dummy method

PUB OpMode(mode)
' Dummy method

PUB Temperature: result
' Read device temperature
    readReg(core#OUT_TEMP, 1, @result)

PRI readReg(reg_nr, nr_bytes, buff_addr) | cmd_packet, tmp
'' Read num_bytes from the slave device into the address stored in buff_addr
    case reg_nr                                             ' Basic register validation
        $0F, $20..$27, $2E..$39:
        $28..$2D:                                           ' If reading from gyro data regs,
#ifdef L3GD20H_SPI
            reg_nr |= core#MS_SPI                           '   set multi-byte read mode (SPI)
#elseifdef L3GD20H_I2C
            reg_nr |= core#MS_I2C                           '   set multi-byte read mode (I2C)
#endif
        OTHER:
            return

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
        $20..$25, $2E, $30, $32..$39:
#ifdef L3GD20H_SPI
            spi.write(TRUE, @reg_nr, 1, FALSE)                  ' Ask for reg, but don't deselect after
            spi.write(TRUE, buff_addr, nr_bytes, TRUE)
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
