# [cite_start]Logic Design Project [cite: 1, 2]

## Overview
[cite_start]The goal of the project is to implement a hardware module described in VHDL that interfaces with a memory component. [cite: 5] [cite_start]The system reads a sequence of K words (W) from memory, applies a differential filter, and saves the resulting processed sequence of K words (R) back into memory. [cite: 6] [cite_start]All values processed are 8-bit integers represented in two's complement, spanning the range from -128 to +127. [cite: 6]

## Features & Mathematical Model
* [cite_start]**Differential Filtering:** The system applies either an Order 3 or Order 5 differential filter based on the initialization parameters. [cite: 16]
* [cite_start]**Filter Equation:** The mathematical application of the filter is defined as f'(i) = (1/n) * sum(C_j * f[j+i]). [cite: 23]
* [cite_start]**Normalization via Bit-shifting:** Since hardware division is costly, the normalization factor n (n=12 for Order 3, n=60 for Order 5) is approximated using right shifts. [cite: 20, 39, 40]
    * [cite_start]1/12 is approximated as 1/16 + 1/64 + 1/256 + 1/1024. [cite: 39]
    * [cite_start]1/60 is approximated as 1/64 + 1/1024. [cite: 39]
* [cite_start]**Truncation Error Correction:** To compensate for the truncation error introduced by bit-shifting negative numbers, a +1 correction is added to each individual shift result if the shifted value is negative. [cite: 41, 43, 44]
* [cite_start]**Saturation:** If the final calculated values for the sequence R fall outside the -128 to +127 range, they are strictly saturated to those limits. [cite: 7]

## Memory Layout
[cite_start]The system reads a continuous block of memory starting at a specified address (ADD). [cite: 8]
* [cite_start]**Header (17 Bytes):** Contains metadata and filter coefficients. [cite: 10]
    * [cite_start]`K1`, `K2` (2 bytes): Represent the length of the data sequence K, with K1 being the most significant byte. [cite: 12, 13]
    * `S` (1 byte): Selects the filter. [cite_start]If the least significant bit is 0, the Order 3 filter is used; if 1, the Order 5 filter is used. [cite: 16, 18]
    * [cite_start]`C1` to `C14` (14 bytes): Store the coefficients for the filters. [cite: 19]
* [cite_start]**Payload (K Bytes):** The numeric vector to be processed. [cite: 21, 22]
* [cite_start]**Output Memory:** The processed sequence is written back starting at address ADD+17+K, immediately following the input sequence. [cite: 28]

## Component Interface
[cite_start]The top-level entity is strictly named `project_reti_logiche` and includes the following ports: [cite: 71, 84]

| Port Name | Direction | Size | Description |
| :--- | :--- | :--- | :--- |
| `i_clk` | `in` | 1 bit | [cite_start]System clock signal. [cite: 86] |
| `i_rst` | `in` | 1 bit | [cite_start]Asynchronous reset signal. [cite: 87] |
| `i_start` | `in` | 1 bit | [cite_start]Signal to begin execution. [cite: 89] |
| `i_add` | `in` | 16 bit | [cite_start]Starting address (`ADD`) of the sequence. [cite: 90] |
| `o_done` | `out` | 1 bit | [cite_start]High when the processing is completed. [cite: 91] |
| `o_mem_addr` | `out` | 16 bit | [cite_start]Address sent to the memory for read/write. [cite: 92] |
| `i_mem_data` | `in` | 8 bit | [cite_start]Data read from the memory. [cite: 93] |
| `o_mem_data` | `out` | 8 bit | [cite_start]Data to be written into the memory. [cite: 94] |
| `o_mem_we` | `out` | 1 bit | [cite_start]Write Enable for the memory. [cite: 96] |
| `o_mem_en` | `out` | 1 bit | [cite_start]Enable signal for memory communication. [cite: 95] |

## Technologies Used
* [cite_start]**VHDL:** Used for the RTL description of the hardware module. [cite: 5]
* [cite_start]**Xilinx Vivado:** Used for synthesis, simulation, and analyzing the hardware behavior. [cite: 104, 105]
* **LaTeX:** Used to write the formal documentation and project report detailing the logic and design choices.
