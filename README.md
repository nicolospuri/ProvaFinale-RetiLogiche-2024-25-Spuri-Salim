# Digital Logic Design Project — Differential Filter (VHDL / Vivado)

VHDL hardware module developed and tested in **Xilinx Vivado** that interfaces with a single-port memory and applies a differential filter to a sequence of signed bytes (range [-128, 127]), following the course specification.

## Overview

The module reads from memory at base address `ADD`: a 17-byte preamble (sequence length `K`, filter selector `S`, 14 filter coefficients), followed by `K` input samples `W`.  
It selects **order-3** (if LSB of `S` is 0) or **order-5** (if LSB is 1) filter, computes \( r_i = \frac{1}{n} \sum C_j \cdot w_{i+j} \) with approximated division via right shifts (negative-value correction), saturates to 8-bit signed range, and writes sequence `R` back at `ADD + 17 + K`.
Edge samples (before first and after last `W`) are treated as `0`.

## Key features

- Synchronous design (all signals on rising clock edge, except asynchronous reset).
- Saturation: clip results outside [-128, 127] to limits.
- Normalization: right-shift approximation with error correction for negatives (add 1 before shift if < 0).

## Module interface

Entity must be named `project_retilogiche` with ports:
- `i_clk`, `i_rst` (async reset)
- `i_start`, `i_add[15:0]`
- `o_done`
- Memory: `o_mem_addr[15:0]`, `i_mem_data[7:0]`, `o_mem_data[7:0]`, `o_mem_we`, `o_mem_en`

## Technologies

- **VHDL** (RTL description, FSM control)
- **Vivado** (simulation, synthesis, testbench integration)
- **LaTeX** (project report/documentation)
