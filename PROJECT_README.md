# ⚡ Bit-Trix 2026: LTI Impulse Response Accelerator

![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)
![Architecture](https://img.shields.io/badge/Architecture-8--Bit_Harvard-blue)
![Simulation](https://img.shields.io/badge/Simulation-Cocotb_%7C_Verilator-orange)

A hyper-optimized, hardware-software co-designed 8-bit CPU built for the Bit-Trix 2026 competition at IIITDM Kancheepuram. 
*PS: The template file has the final code!*

This repository contains the Verilog RTL, the Python-based Cocotb testbench, and the custom Assembly instruction set designed specifically to compute the impulse response sequence `h[n]` of a discrete-time LTI system in the absolute minimum number of clock cycles.

---

## 🧠 The "Secret Sauce": Bypassing the FFT Trap
The competition constraints included complex multipliers and radix-2 butterflies, tempting teams to attempt a frequency-domain deconvolution (FFT/IFFT). 

However, implementing an FFT on an 8-bit architecture with only 4 general-purpose registers guarantees catastrophic memory spilling, drastically inflating the total execution cycle count. 

**Our Solution:** We bypassed the frequency domain entirely. We designed our datapath and custom Instruction Set Architecture (ISA) to execute **Recursive Forward Substitution** in the time domain:

$$h[n] = \frac{y[n] - \sum_{k=0}^{n-1} h[k]x[n-k]}{x[0]}$$

By tailoring the hardware strictly to this formula, we achieved a **Single-Cycle Execution (CPI = 1)** core loop that destroys standard multi-cycle implementations.

---

## 🏗️ The Apex Micro-Architecture Diagram

Unlike standard generic processors, our architecture was drawn from scratch to optimize the specific mathematical flow of discrete-time deconvolution. We implemented a pure, single-cycle Harvard architecture.

```mermaid
graph TD
    %% Define Styles
    classDef storage fill:#333,stroke:#fff,stroke-width:2px,color:#fff;
    classDef logic fill:#005577,stroke:#fff,stroke-width:1px,color:#fff;
    classDef control fill:#990000,stroke:#fff,stroke-width:1px,color:#fff;
    classDef winning fill:#ffcc00,stroke:#000,stroke-width:2px,color:#000;

    subgraph Stage1 ["FETCH & DECODE (Stage 1)"]
        PC[Program Counter]:::storage
        IMEM[Internal IMEM ROM]:::storage
        DECODER[Instr. Decoder]:::control
    end

    subgraph Stage2 ["EXECUTE (1-Cycle)"]
        REGFILE{{"Register File (4 Regs)"}}:::winning
        MAC_REG[Implicit MAC Accumulator R0]:::storage
        LOOP_REG[Implicit Loop Counter R3]:::storage
        
        ALU[Standard ALU ADD/SUB]:::logic
        MAC[Custom 1-Cycle MAC Unit]:::winning
        DIV[Serial Divider Block]:::logic
    end

    subgraph Stage3 ["MEMORY (Zero-Latency)"]
        RAM[RAM Block Async Read]:::winning
    end

    %% -- Connections --
    PC -->|Addr| IMEM
    IMEM -->|Instr| DECODER
    
    %% Control Paths
    DECODER -.->|Reg WE / Ctrl| REGFILE
    DECODER -.->|ALU Op| ALU
    DECODER -.->|MAC En/Clr| MAC
    DECODER -.->|DIV En| DIV
    DECODER -.->|RAM WE| RAM
    DECODER -.->|Branch Control| PC

    %% Data Paths (Winning paths highlighted)
    REGFILE ==>|Rs1 & Rs2| ALU
    REGFILE ==>|Rs1 & Rs2| MAC
    MAC_REG ==>|Accumulate In| MAC
    REGFILE ==>|Rs2 Denominator| DIV
    MAC_REG ==>|Numerator R0| DIV
    REGFILE ==>|Addr/Data Pointer| RAM
    
    %% Writeback
    ALU ==>|Writeback| REGFILE
    MAC ==>|Implicit WB to R0| MAC_REG:::winning
    DIV ==>|Writeback| REGFILE
    RAM ==>|Zero-Latency Read| REGFILE:::winning
    
    %% Hardware Branch Logic
    REGFILE -.->|Check R3 != 0| DECODER:::winning
