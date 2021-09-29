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

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81), FlexSpin (tested with 6.0.0-beta)
* P2/SPIN2: FlexSpin (tested with 6.0.0-beta)
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build

## TODO

- [x] Port to P2/SPIN2
- [x] Support alternate I2C slave address
- [ ] Support 3-wire SPI
- [ ] Combine support for L3G4200
