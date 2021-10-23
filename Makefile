# l3gd20h-spin Makefile - requires GNU Make, or compatible
# Variables below can be overridden on the command line
#      e.g. IFACE=L3GD20H_SPI3W make

# P1, P2 device nodes and baudrates
#P1DEV=
P1BAUD=115200
#P2DEV=
P2BAUD=2000000

# P1, P2 compilers
P1BUILD=openspin
#P1BUILD=flexspin
P2BUILD=flexspin

# L3GD20H interface: I2C, SPI-3wire or SPI-4wire
#IFACE=L3GD20H_I2C
#IFACE=L3GD20H_SPI3W
#IFACE=L3GD20H_SPI4W

# Paths to spin-standard-library, and p2-spin-standard-library,
#  if not specified externally
SPIN1_LIB_PATH=-L ../spin-standard-library/library
SPIN2_LIB_PATH=-L ../p2-spin-standard-library/library


# -- Internal --
SPIN1_DRIVER_FN=sensor.gyroscope.3dof.l3gd20h.i2cspi.spin
SPIN2_DRIVER_FN=sensor.gyroscope.3dof.l3gd20h.i2cspi.spin2
CORE_FN=core.con.l3gd20h.spin
# --

# Build all targets (build only)
all: L3GD20H-Demo.binary L3GD20H-Demo.bin2

# Load P1 or P2 target (will build first, if necessary)
p1demo: loadp1demo
p2demo: loadp2demo

# Build binaries
L3GD20H-Demo.binary: L3GD20H-Demo.spin $(SPIN1_DRIVER_FN) $(CORE_FN)
	$(P1BUILD) $(SPIN1_LIB_PATH) -b -D $(IFACE) L3GD20H-Demo.spin

L3GD20H-Demo.bin2: L3GD20H-Demo.spin2 $(SPIN2_DRIVER_FN) $(CORE_FN)
	$(P2BUILD) $(SPIN2_LIB_PATH) -b -2 -D $(IFACE) -o L3GD20H-Demo.bin2 L3GD20H-Demo.spin2

# Load binaries to RAM (will build first, if necessary)
loadp1demo: L3GD20H-Demo.binary
	proploader -t -p $(P1DEV) -Dbaudrate=$(P1BAUD) L3GD20H-Demo.binary

loadp2demo: L3GD20H-Demo.bin2
	loadp2 -SINGLE -p $(P2DEV) -v -b$(P2BAUD) -l$(P2BAUD) L3GD20H-Demo.bin2 -t

# Remove built binaries and assembler outputs
clean:
	rm -fv *.binary *.bin2 *.pasm *.p2asm
