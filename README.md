# ASIC Digital Door Lock (FPGA VHDL)

A hardware-level digital door lock system implemented on the Xilinx Artix-7 FPGA (Nexys A7-100T development board) using VHDL. This project demonstrates the practical application of sequential digital logic, Finite State Machines (FSM), and custom hardware drivers.

## Live Hardware Demonstration
* **Video Demo & Explanation:** [Watch on YouTube](https://youtu.be/ouHHwR-JoAE) 

## System Architecture & FSM Controller
The core of the system is a 10-state FSM that strictly governs access control, ensuring non-blocking transitions between states:
* **Multi-Stage Input:** Processes an 8-digit password input using a limited 16-switch physical interface by storing the first 4 digits in a temporary buffer before validating the final 32-bit vector.
* **Auto-Lock Timer:** Utilizes a 29-bit unsigned counter synced with the 100MHz system clock to accurately trigger an automatic lock exactly 5 seconds after the door is opened.
* **Change Password (Program Mode):** Allows real-time overwriting of the stored password register without requiring an FPGA re-flash.
* **Emergency Override:** A dedicated state transition that bypasses the comparator logic for immediate unlocking.

## Custom Display Driver (Time-Division Multiplexing)
To provide intuitive visual feedback on the 8-digit 7-segment display using limited I/O pins, a custom multiplexer was engineered:
* **High-Frequency Scanning:** Actuates the anodes sequentially at a high refresh rate, exploiting Persistence of Vision (PoV) to eliminate flicker.
* **Custom Character Decoder:** Beyond standard hexadecimals (0-9, A-F), a custom switch-case decoder was mapped to display the specific segment patterns for the words "BENAR" (Correct) and "SALAH" (Wrong).

## Hardware Button Debouncing
Integrated a custom Edge Detector module for all physical push-buttons (Enter, Next, Program, Override) to convert mechanical switch bounces into clean, one-shot logic pulses, preventing accidental double-inputs.

## Source Code & Documentation
The raw VHDL logic, Vivado testbench simulations, and the `.xdc` pin-mapping files are available in the [src folder](./src).
