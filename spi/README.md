## SPI Communication Protocol

This project includes the RTL code for the SPI (Serial Peripheral Interface) communication protocol. The following files are part of this project:

1. `top.sv` - RTL code for the SPI master and slave module.
2. `top_tb.sv` - Verification of `top.sv`.
3. `sv_top.sv` - RTL code for SPI modules with interface.
4. `sv_tb.sv` - Extensive verification of `sv_top.sv`.

### Overview

The SPI communication protocol is a synchronous serial communication interface used for short-distance communication, primarily in embedded systems. It operates in full duplex mode, allowing simultaneous data transmission and reception.

