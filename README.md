# Dragon 256 rev X4 Kitchen Sink Edition #

This repository contains the hardware design
for a heavily revised Dragon 32 computer
main board. Unlike my other designs this does
not conform to the original footprint and port
placement.

![Render of Dragon PCB](./DragonRevX4Plus.png)

The design is most definitely experimental
and absolutely unproven

## Features ##

The board differs from standard with the
following features:

* 256k SRAM - 64k address space, 32k pages
(lower and upper ram space)
* Multiple (selectable) cartridge slots
* 2 button joystick ports (compatible with
original single button joysticks)
* Hardware serial port (as with Dragon 64)
* Switchable ROM banks (as with Dragon 64)
* Twin AY-sound generators (6 channels)
* SAM X4
* Advanced, addressable 6847 compatible VDG
(one of different video output options)
* Fast CPU options (1.8 or 3.6 MHz)

## Board Layout ##

The regular interface ports are kept to the
left hand side of the board although the
serial port is a more commonly accepted DE9
configuration instead of the 7-pin DIN

The rear of the board is dedicated to the 
cartridge slots. The power and video output
is on the right of the board.

The board itself should (just) fit inside a 
regular Dragon case but the power and video 
interface needs to be external.

Without a constraint to fit in a pre-defined 
case there is no real need to retain the 
original case but some form of case will be 
required. I leave this to someone else for now

The keyboard connector is compatible with the
original Dragon design but also includes an 
extra +5V which makes it very convenient to 
fit an adapter for other styles of keyboard 
using a microcontroller.

## Progress ##

The design integrates most of the designs and
upgrades I've developed for the Dragon, all 
into a single board which helps to reduce the 
footprint and power requirements

At this point the task is to play around with
the component layout to find a relatively simple
and efficient approach. The board size, port 
positions and component layout has not been 
fixed. The only exception to this is the three 
video connectors - these can be moved around the
board but must retain the same relative 
positions

### Custom SamX4 Design ###

The samX4 VHDL requires modifying to suit the 
new design. Some features can be removed (like
support for 4k and 16k memory models and DRAM
refresh) and others points need adding 
(corrected VDG read/clk timing and faster CPU
multiplier).

### PIA Port Disambiguation ###

The original SAM memory map provides three
address blocks for interfacing with PIAs.
Noted as P0, P1 and P2, these are 32 bytes
each but the 6821 PIA only recognises a
4 byte range so the 32 byte block is 8
repeats of the PIAs 4 bytes.

The board design here splits P1 into 8
distinct blocks within the 32 byte range
thus allowing for much more complexity in
what the CPU can address. The devices are
noted as P1a - P1h.

P0 is left as-is (for now). P2 is the
responsibility of the cartridge port but
the same disambiguation can easily be
applied on a per-cartridge basis.

The upper half of the expanded P1 device 
range is dedicated to the 256k banking
scheme.

P1a is the original PIA (to retain
compatibility), P1b is assigned to the
VDG, P1c and P1d are the AY sound generators.

### SamX4 Timing ###

The default operation of the SAM chip
provides a synchronised Q/E quadrature clock
for the CPU and VDG. The two devices operate
on opposite phases of the same clock.

In order to retain a viable video signal
the VDG clock must operate at the default
0.89MHz frequency. Doubling the 

## Contributing ##

The project needs review and ultimately, 
testing, once the design progresses that far.

If you want to help please get in touch first 
to keep the work flow consistent and to avoid
potentially disasterous conflicts
