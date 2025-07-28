# SRAM Read/Write Controller

## Project Description
This project implements an SRAM read/write controller on an FPGA using Xilinx Memory IP. 
 It includes a finite state machine (FSM) to control timing and signals for reliable SRAM access.
 
The design was verified on-board through debugging 7 LEDs.

## Features

- FSM-Based Sequential Logic
  - State transitions triggered by button input.
 
- Uses Xilinx Memory IP
  - Write and Read data using internal Memory IP ('mem_gen').

- Asynchronous Reset

- Real-time Debugging via LEDs
  - Data read from SRAM is directly displayed on-board LEDs.









