{
    --------------------------------------------
    Filename: sensor.gyroscope.l3gd20h.spin
    Author: Jesse Burt
    Description: Driver for the ST L3GD20H 3DoF gyroscope
    Copyright (c) 2022
    Started Jul 11, 2020
    Updated Oct 1, 2022
    See end of file for terms of use.
    --------------------------------------------
}
#include "sensor.gyroscope.common.spinh"

CON

    SLAVE_WR            = core#SLAVE_ADDR
    SLAVE_RD            = core#SLAVE_ADDR|1

    DEF_SCL             = 28
    DEF_SDA             = 29
    DEF_HZ              = 100_000
    DEF_ADDR            = 0
    I2C_MAX_FREQ        = core#I2C_MAX_FREQ

' Indicate to user apps how many Degrees of Freedom each sub-sensor has
'   (also imply whether or not it has a particular sensor)
    ACCEL_DOF           = 0
    GYRO_DOF            = 3
    MAG_DOF             = 0
    BARO_DOF            = 0
    DOF                 = ACCEL_DOF + GYRO_DOF + MAG_DOF + BARO_DOF

' Scales and data rates used during calibration/bias/offset process
    CAL_XL_SCL          = 0
    CAL_G_SCL           = 245
    CAL_M_SCL           = 0
    CAL_XL_DR           = 0
    CAL_G_DR            = 100
    CAL_M_DR            = 0

' Axis-specific constants
    X_AXIS              = 0
    Y_AXIS              = 1
    Z_AXIS              = 2
    ALL_AXIS            = 3

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

' FIFO operation modes
    #0, BYPASS, FIFO, STREAM, STREAM2FIFO, BYPASS2STREAM, #6, DYN_STREAM, BYPASS2FIFO

VAR

    long _CS
    byte _addr_bits

OBJ

{ SPI? }
#ifdef L3GD20H_SPI
{ decide: Bytecode SPI engine, or PASM? Default is PASM if BC isn't specified }
#ifdef L3GD20H_SPI_BC
    spi : "com.spi.25khz.nocog"                       ' BC SPI engine
#else
    spi : "com.spi.4mhz"                ' PASM SPI engine
#endif
#else
{ no, not SPI - default to I2C }
#define L3GD20H_I2C
{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef L3GD20H_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif

#endif
    core: "core.con.l3gd20h"
    time: "time"

PUB null{}
' This is not a top-level object

#ifdef L3GD20H_I2C
PUB start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    status := startx(DEF_SCL, DEF_SDA, DEF_HZ, DEF_ADDR)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start using custom I/O pins and I2C bus speed
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}       I2C_HZ =< core#I2C_MAX_FREQ and lookdown(ADDR_BITS: 0, 1)
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.msleep(1)                      ' wait for device startup
            _addr_bits := ADDR_BITS << 1
            if i2c.present(SLAVE_WR | _addr_bits)' check device bus presence
                if (dev_id{} == core#DEVID_RESP)' validate device
                    return status
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE
#elseifdef L3GD20H_SPI
PUB startx(CS_PIN, SCL_PIN, MOSI_PIN, MISO_PIN): status
' Start using custom I/O pins
    if lookdown(CS_PIN: 0..31) and lookdown(SCL_PIN: 0..31) and {
}   lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31)
        if (status := spi.init(SCL_PIN, MOSI_PIN, MISO_PIN, core#SPI_MODE))
            _CS := CS_PIN
            outa[_CS] := 1
            dira[_CS] := 1
            time.msleep(1)
            if (dev_id{} == core#DEVID_RESP)
                return status
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE
#endif

PUB stop{}
' Stop the driver
#ifdef L3GD20H_I2C
    i2c.deinit{}
#elseifdef L3GD20H_SPI
    spi.deinit{}
    _CS := 0
#endif

PUB defaults{}
' Set factory defaults
{'  This is what _would_ be set:
    blockupdateenabled(FALSE)
    databyteorder(LSBFIRST)
    fifoenabled(FALSE)
    gyroaxisenabled(%111)
    gyro_data_rate(100)
    gyroopmode(POWERDOWN)
    gyroscale(245)
    highpassfilterenabled(FALSE)
    highpassfilterfreq(8_00)
    highpassfiltermode(HPF_NORMAL_RES)
    int1mask(%00)
    int2mask(%0000)
    intactivestate(INTLVL_LOW)
    intoutputtype(INT_PP)
}'  but to save code space, just soft-reset, instead:
    reset{}

PUB preset_active{}
' Like Defaults(), but
'   * Normal (active) operating mode
    reset{}
    gyro_opmode(NORMAL)
    gyro_scale(245)                              ' already set at POR, but this
                                                ' needs to be called to set
                                                ' scaling value hub var

PUB blk_updt_ena(state): curr_state
' Enable block updates
'   Valid values:
'      *FALSE (0): Update gyro data outputs continuously
'       TRUE (-1 or 1): Pause further updates until both MSB and LSB of data have been read
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CTRL4, 1, @curr_state)
    case ||(state)
        0, 1:
            state := (||(state) & 1) << core#BDU
        other:
            return (((curr_state >> core#BDU) & 1) == 1)

    state := ((curr_state & core#BDU_MASK) | state)
    writereg(core#CTRL4, 1, @state)

PUB data_order(order): curr_ord
' Set byte order of gyro data
'   Valid values:
'      *LSBFIRST (0), MSBFIRST (1)
'   Any other value polls the chip and returns the current setting
'   NOTE: Intended only for use when utilizing raw gyro data from GyroData method.
'       GyroDPS expects the data order to be LSBFIRST
    curr_ord := 0
    readreg(core#CTRL4, 1, @curr_ord)
    case order
        LSBFIRST, MSBFIRST:
            order <<= core#BLE
        other:
            return ((curr_ord >> core#BLE) & 1)

    order := ((curr_ord & core#BLE_MASK) | order)
    writereg(core#CTRL4, 1, @order)

PUB dev_id{}: id
' Read device identification
    readreg(core#WHO_AM_I, 1, @id)

PUB fifo_ena(state): curr_state
' Enable FIFO for gyro data
'   Valid values:
'      *FALSE (0): FIFO disabled
'       TRUE (-1 or 1): FIFO state
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CTRL5, 1, @curr_state)
    case ||(state)
        0, 1:
            state := (||(state) & 1) << core#FIFO_EN
        other:
            return (((curr_state >> core#FIFO_EN) & 1) == 1)

    state := ((curr_state & core#FIFO_EN_MASK) | state)
    writereg(core#CTRL5, 1, @state)

PUB fifo_empty{}: flag
' Flag indicating FIFO empty
'   Returns: FALSE (0): FIFO not empty, TRUE(-1): FIFO empty
    readreg(core#FIFO_SRC, 1, @flag)
    return (((flag >> core#EMPTY) & 1) == 1)

PUB fifo_full{}: flag
' Flag indicating FIFO threshold reached
'   Returns: FALSE (0): lower than threshold level, TRUE(-1): at or higher than threshold level
    readreg(core#FIFO_SRC, 1, @flag)
    return (((flag >> core#FTH) & 1) == 1)

PUB fifo_mode(mode): curr_mode
' Set FIFO operation mode
'   Valid values:
'      *BYPASS (0)
'       FIFO (1)
'       STREAM (2)
'       STREAM2FIFO (3)
'       BYPASS2STREAM (4)
'       DYN_STREAM (6)
'       BYPASS2FIFO (7)
'   Any other value polls the chip and returns the current setting
    readreg(core#FIFO_CTRL, 1, @curr_mode)
    case mode
        BYPASS, FIFO, STREAM, STREAM2FIFO, BYPASS2STREAM, DYN_STREAM, BYPASS2FIFO:
            mode <<= core#FM
        other:
            return ((curr_mode >> core#FM) & core#FM_BITS)

    mode := ((curr_mode & core#FM_MASK) | mode)
    writereg(core#FIFO_CTRL, 1, @mode)

PUB fifo_thresh(level): curr_lvl
' Set FIFO threshold level
'   Valid values: 0..31
'   Any other value polls the chip and returns the current setting
    readreg(core#FIFO_CTRL, 1, @curr_lvl)
    case level
        0..31:
        other:
            return (curr_lvl & core#FTH_BITS)

    level := ((curr_lvl & core#FTH_MASK) | level)
    writereg(core#FIFO_CTRL, 1, @level)

PUB fifo_nr_unread{}: nr_samples
' Number of unread samples stored in FIFO
'   Returns: 0 (empty) .. 32
    readreg(core#FIFO_SRC, 1, @nr_samples)
    return nr_samples & core#FSS_BITS

PUB gyro_axis_ena(mask): curr_mask
' Enable gyroscope individual axes, by mask
'   Valid values:
'       0: Disable axis, 1: Enable axis
'       Bits %210
'             ZYX (default: %111)
'   Any other value polls the chip and returns the current setting
    curr_mask := 0
    readreg(core#CTRL1, 1, @curr_mask)
    case mask
        %000..%111:
        other:
            return (curr_mask & core#XYZEN_BITS)

    mask := ((curr_mask & core#XYZEN_MASK) | mask)
    writereg(core#CTRL1, 1, @mask)

PUB gyro_bias(x, y, z)
' Read gyroscope calibration offset values
'   x, y, z: pointers to copy offsets to
    long[x] := _gbias[X_AXIS]
    long[y] := _gbias[Y_AXIS]
    long[z] := _gbias[Z_AXIS]

PUB gyro_set_bias(x, y, z)
' Write gyroscope calibration offset values
'   Valid values:
'   -32768..32767
    longmove(@_gbias, @x, 3)

PUB gyro_data(ptr_x, ptr_y, ptr_z) | tmp[2]
' Read gyroscope data
    bytefill(@tmp, 0, 8)
    readreg(core#OUT_X_L, 6, @tmp)

    long[ptr_x] := (~~tmp.word[X_AXIS]) - _gbias[X_AXIS]
    long[ptr_y] := (~~tmp.word[Y_AXIS]) - _gbias[Y_AXIS]
    long[ptr_z] := (~~tmp.word[Z_AXIS]) - _gbias[Z_AXIS]

PUB gyro_data_overrun{}: flag
' Indicates previously acquired data has been overwritten
'   Returns: TRUE (-1) if data has overrun/been overwritten, FALSE otherwise
    flag := 0
    readreg(core#STATUS, 1, @flag)
    flag := (((flag >> core#ZYXOR) & 1) == 1)

PUB gyro_data_rate(rate): curr_rate
' Set rate of data output, in rate
'   Valid values: *100, 200, 400, 800
'   Any other value polls the chip and returns the current setting
    curr_rate := 0
    readreg(core#CTRL1, 1, @curr_rate)
    case rate
        100, 200, 400, 800:
            rate := lookdownz(rate: 100, 200, 400, 800) << core#DR
        other:
            curr_rate := ((curr_rate >> core#DR) & core#DR_BITS)
            return lookupz(curr_rate: 100, 200, 400, 800)

    rate := ((curr_rate & core#DR_MASK) | rate)
    writereg(core#CTRL1, 1, @rate)

PUB gyro_data_rdy{}: ready
' Indicates data is ready
'   Returns: TRUE (-1) if data ready, FALSE otherwise
    ready := 0
    readreg(core#STATUS, 1, @ready)
    return (((ready >> core#ZYXDA) & 1) == 1)

PUB gyro_opmode(mode): curr_mode | tmp_xyz
' Set operation mode
'   Valid values:
'      *POWERDOWN (0): Power down - lowest power state
'       SLEEP (1): Sleep - sensor enabled, but X, Y, Z outputs disabled
'       NORMAL (2): Normal - active operating state
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#CTRL1, 1, @curr_mode)
    case mode
        POWERDOWN:
            mode := (curr_mode & core#PD_MASK)
        SLEEP:
            mode := ((curr_mode & core#XYZEN_MASK) | (1 << core#PD))
        NORMAL:
            mode := ((curr_mode & core#PD_MASK) | (1 << core#PD))
        other:
            tmp_xyz := curr_mode & core#XYZEN_BITS
            curr_mode := (curr_mode >> core#PD) & 1
            case curr_mode                      ' check state of power mode bit
                0:                              ' power down
                    return POWERDOWN
                1:                              ' normal mode
                    if tmp_xyz                  ' if any axes are enabled,
                        return NORMAL           '   chip mode is normal
                    else
                        return SLEEP            ' if not, it's sleeping

    writereg(core#CTRL1, 1, @mode)

PUB gyro_scale(scale): curr_scale
' Set gyro full-scale range, in degrees per second
'   Valid values: *245, 500, 2000
'   Any other value polls the chip and returns the current setting
    curr_scale := 0
    readreg(core#CTRL4, 1, @curr_scale)
    case scale
        245, 500, 2000:
            scale := lookdownz(scale: 245, 500, 2000) << core#FS
            _gres := lookupz(scale >> core#FS: 8_750, 17_500, 70_000)
        other:
            curr_scale := (curr_scale >> core#FS) & core#FS_BITS
            return lookupz(curr_scale: 245, 500, 2000)

    scale := ((curr_scale & core#FS_MASK) | scale)
    writereg(core#CTRL4, 1, @scale)

PUB gyro_hpf_ena(state): curr_state
' Enable high-pass filter for gyro data
'   Valid values:
'      *FALSE (0): High-pass filter disabled
'       TRUE (-1 or 1): High-pass filter state
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CTRL5, 1, @curr_state)
    case ||(state)
        0, 1:
            state := (||(state) & 1) << core#HPEN
        other:
            return (((curr_state >> core#HPEN) & 1) == 1)

    state := ((curr_state & core#HPEN_MASK) | state)
    writereg(core#CTRL5, 1, @state)

PUB gyro_hpf_freq(freq): curr_freq
' Set high-pass filter frequency, in centi-Hz
'    Valid values:
'       If ODR=100Hz: *8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01
'       If ODR=200Hz: *15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02
'       If ODR=400Hz: *30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05
'       If ODR=800Hz: *56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10
    curr_freq := 0
    readreg(core#CTRL2, 1, @curr_freq)
    case gyro_data_rate(-2)
        100:
            case freq
                8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01:
                    freq := lookdownz(freq: 8_00, 4_00, 2_00, 1_00, 0_50, {
}                   0_20, 0_10, 0_05, 0_02, 0_01) << core#HPCF
                other:
                    curr_freq := (curr_freq >> core#HPCF) & core#HPCF_BITS
                    return lookupz(curr_freq: 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, {
}                   0_10, 0_05, 0_02, 0_01)
        200:
            case freq
                15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02:
                    freq := lookdownz(freq: 15_00, 8_00, 4_00, 2_00, 1_00, {
}                   0_50, 0_20, 0_10, 0_05, 0_02) << core#HPCF
                other:
                    curr_freq := (curr_freq >> core#HPCF) & core#HPCF_BITS
                    return lookupz(curr_freq: 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, {
}                   0_20, 0_10, 0_05, 0_02)
        400:
            case freq
                30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05:
                    freq := lookdownz(freq: 30_00, 15_00, 8_00, 4_00, 2_00, {
}                   1_00, 0_50, 0_20, 0_10, 0_05) << core#HPCF
                other:
                    curr_freq := (curr_freq >> core#HPCF) & core#HPCF_BITS
                    return lookupz(curr_freq: 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, {
}                   0_50, 0_20, 0_10, 0_05)
        800:
            case freq
                56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10:
                    freq := lookdownz(freq: 56_00, 30_00, 15_00, 8_00, 4_00, {
}                   2_00, 1_00, 0_50, 0_20, 0_10) << core#HPCF
                other:
                    curr_freq := (curr_freq >> core#HPCF) & core#HPCF_BITS
                    return lookupz(curr_freq: 56_00, 30_00, 15_00, 8_00, 4_00, 2_00, {
}                   1_00, 0_50, 0_20, 0_10)

    freq := ((curr_freq & core#HPCF_MASK) | freq)
    writereg(core#CTRL2, 1, @freq)

PUB gyro_hpf_mode(mode): curr_mode
' Set data output high pass filter mode
'   Valid values:
'      *HPF_NORMAL_RES (0): Normal mode (reset reading HP_RESET_FILTER) XXX - clarify/expand
'       HPF_REF (1): Reference signal for filtering
'       HPF_NORMAL (2): Normal
'       HPF_AUTO_RES (3): Autoreset on interrupt
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#CTRL2, 1, @curr_mode)
    case mode
        HPF_NORMAL_RES, HPF_REF, HPF_NORMAL, HPF_AUTO_RES:
            mode <<= core#HPM
        other:
            return ((curr_mode >> core#HPM) & core#HPM_BITS)

    mode := ((curr_mode & core#HPM_MASK) | mode)
    writereg(core#CTRL2, 1, @mode)

PUB int1_mask(mask): curr_mask
' Set interrupt mask for INT1 pin
'   Valid values:
'       Bit 10   10
'           ||   ||
'    Range %00..%11
'       Bit 1: Interrupt enable (*0: Disable, 1: Enable)
'       Bit 0: Boot status (*0: Disable, 1: Enable)
    curr_mask := 0
    readreg(core#CTRL3, 1, @curr_mask)
    case mask
        %00..%11:
            mask <<= core#INT1
        other:
            return ((curr_mask >> core#INT1) & core#INT1_BITS)

    mask := ((curr_mask & core#INT1_MASK) | mask)
    writereg(core#CTRL3, 1, @mask)

PUB int2_mask(mask): curr_mask
' Set interrupt/function mask for INT2 pin
'   Valid values:
'       Bit 3210   3210
'           ||||   ||||
'    Range %0000..%1111 (default value: %0000)
'       Bit 3: Data ready
'       Bit 2: FIFO watermark
'       Bit 1: FIFO overrun
'       Bit 0: FIFO empty
    curr_mask := 0
    readreg(core#CTRL3, 1, @curr_mask)
    case mask
        %0000..%1111:
        other:
            return (curr_mask & core#INT2_BITS)

    mask := ((curr_mask & core#INT2_MASK) | mask)
    writereg(core#CTRL3, 1, @mask)

PUB int_polarity(state): curr_state
' Set active state for interrupts
'   Valid values: *INTLVL_LOW (0), INTLVL_HIGH (1)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CTRL3, 1, @curr_state)
    case state
        INTLVL_LOW, INTLVL_HIGH:
            state := ((state ^ 1) & 1) << core#H_LACTIVE
        other:
            return (((curr_state >> core#H_LACTIVE) ^ 1) & 1)

    state := ((curr_state & core#H_LACTIVE_MASK) | state)
    writereg(core#CTRL3, 1, @state)

PUB int_outp_type(type): curr_type
' Set interrupt pin output type
'   Valid values:
'      *INT_PP (0): Push-pull
'       INT_OD (1): Open-drain
'   Any other value polls the chip and returns the current setting
    curr_type := 0
    readreg(core#CTRL3, 1, @curr_type)
    case type
        INT_PP, INT_OD:
            type := type << core#PP_OD
        other:
            return ((curr_type >> core#PP_OD) & 1)

    type := ((curr_type & core#PP_OD_MASK) | type)
    writereg(core#CTRL3, 1, @type)

PUB reset{} | tmp
' Perform soft-reset
    tmp := (1 << core#SW_RES)
    writereg(core#LOW_ODR, 1, @tmp)

PUB temp_data{}: temp_adc
' Read device temperature
    readreg(core#OUT_TEMP, 1, @temp_adc)

PRI readreg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from the slave device into ptr_buff
    case reg_nr                                 ' validate reg #
        $0F, $20..$27, $2E..$39:
        $28..$2D:                               ' If reading from data regs,
#ifdef L3GD20H_SPI
            reg_nr |= core#MS_SPI               '   set multi-byte read mode
#elseifdef L3GD20H_I2C
            reg_nr |= core#MS_I2C               '   same, for I2C
#endif
        other:
            return

#ifdef L3GD20H_SPI
    reg_nr |= core#R
    ' request read from reg_nr
    outa[_CS] := 0
    spi.wr_byte(reg_nr)
    spi.rdblock_lsbf(ptr_buff, nr_bytes)
    outa[_CS] := 1
#elseifdef L3GD20H_I2C
    cmd_pkt.byte[0] := SLAVE_WR | _addr_bits
    cmd_pkt.byte[1] := reg_nr
    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.start{}
    i2c.wr_byte(SLAVE_RD | _addr_bits)
    i2c.rdblock_lsbf(ptr_buff, nr_bytes, TRUE)
    i2c.stop{}
#endif

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write num_bytes to the slave device from the address stored in ptr_buff
    case reg_nr                                 ' validate reg #
        $20..$25, $2E, $30, $32..$39:
#ifdef L3GD20H_SPI
            ' request read from reg_nr
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            spi.wrblock_lsbf(ptr_buff, nr_bytes)
            outa[_CS] := 1
#elseifdef L3GD20H_I2C
            cmd_pkt.byte[0] := SLAVE_WR | _addr_bits
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wrblock_lsbf(ptr_buff, nr_bytes)
            i2c.stop{}
#endif
        other:
            return

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

