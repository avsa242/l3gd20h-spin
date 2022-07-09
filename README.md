# l3gd20h-spin 
--------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the ST L3GD20H 3DoF Gyroscope.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 400kHz (default and alternate I2C address)
* SPI (4-wire) connection at up to 4MHz (P1), ~6MHz (P2)
* Read Gyroscope data (raw, or calculated in millionths of a degree per second)
* Read flags for data ready or overrun
* Set operation mode (power down, sleep, normal/active)
* Set output data rate
* Set high-pass filter freq for ODR, configure high-pass filter mode
* Set interrupt mask (int1 & int2), active pin state, output type
* Enable individual axes

## Requirements

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM I2C or SPI engine, as applicable
* sensor.imu.common.spinh (provided by spin-standard-library)

P2/SPIN2:
* p2-spin-standard-library
* sensor.imu.common.spin2h (provided by p2-spin-standard-library)

## Compiler Compatibility

| Processor | Language | Compiler               | Backend     | Status                |
|-----------|----------|------------------------|-------------|-----------------------|
| P1        | SPIN1    | FlexSpin (5.9.13-beta) | Bytecode    | OK                    |
| P1        | SPIN1    | FlexSpin (5.9.13-beta) | Native code | OK                    |
| P1        | SPIN1    | OpenSpin (1.00.81)     | Bytecode    | Untested (deprecated) |
| P2        | SPIN2    | FlexSpin (5.9.13-beta) | NuCode      | FTBFS                 |
| P2        | SPIN2    | FlexSpin (5.9.13-beta) | Native code | OK                    |
| P1        | SPIN1    | Brad's Spin Tool (any) | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | Propeller Tool (any)   | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | PNut (any)             | Bytecode    | Unsupported           |

## Limitations

* TBD

