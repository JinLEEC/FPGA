# SRAM Read/Write Controller

## Project Description
This project implements an SRAM read/write controller on an FPGA using Xilinx Memory IP. 
 It includes a finite state machine (FSM) to control timing and signals for reliable SRAM access.
 
The design was verified on-board through debugging 7 LEDs.

## Features

- FSM-Based Sequential Logic
  - State transition triggered by button input.
 
- Use Xilinx Memory IP
 - Write and Read data using internal Memory IP ('mem_gen').

- Asynchronous Reset

- Real-time Debugging through LEDs
 - Data read from SRAM is displayed on board LEDs.









