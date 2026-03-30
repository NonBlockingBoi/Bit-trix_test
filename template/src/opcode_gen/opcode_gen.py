# These perfectly match your instr_decoder.v
OPCODES = {
    "NOP":    "0000",
    "LD_INC": "0001", # Load and increment pointer
    "LD_DEC": "0010", # Load and decrement pointer
    "ST_INC": "0011", # Store and increment pointer
    "MOV":    "0100",
    "CLR":    "0101", # Clear register to 0
    "ADD":    "0110",
    "SUB":    "0111",
    "MAC":    "1000", # MAC Rs1, Rs2 (Accumulates in R0)
    "DIV":    "1001",
    "LOOP":   "1010", # Branch if R3 != 0
    "HLT":    "1111", # Halt execution
}

# ── Register Table ───────────────────────────────────────────────────────────
REGS = {
    "R0": "00", # Also our implicit MAC Accumulator
    "R1": "01",
    "R2": "10",
    "R3": "11", # Also our implicit Loop Counter
    "00": "00", # Dummy filler for 1-operand instructions
}

# This is a test snippet of the Recursive Forward Substitution inner loop.
# It assumes R1 points to x[n], R2 points to h[0], and R3 is the loop count.
program = [
    # --- PHASE 1: Initialization ---
    ("CLR",      "R0", "00"), # Reset Accumulator: R0 = 0 (Prepares for y[n] - sum)
    ("LD_INC",   "R3", "00"), # Load Loop Count: Fetch 'N' from RAM into R3 (Loop Control)
    ("LD_INC",   "R0", "01"), # Initial Value: Load y[n] into R0 (Sum = y[n])

    # --- PHASE 2: Convolution Summation (The Inner Loop) ---
    # Formula: Sum = Sum - (h[k] * x[n-k])
    ("LD_DEC",   "R1", "01"), # Fetch x[n-k]: Load sample from x-array, move ptr_x back
    ("LD_INC",   "R2", "10"), # Fetch h[k]: Load previous h sample, move ptr_h forward
    ("MAC",      "R1", "R2"), # Multiply-Accumulate: R0 = R0 + (R1 * R2) 
                              # Note: If hardware MAC adds, result must be subtracted later.
    
    # --- PHASE 3: Loop Control ---
    ("SUB",      "R3", "R_ONE"), # Decrement Counter: R3 = R3 - 1 (R_ONE must hold value 1)
    ("LOOP",     "1100", ""),    # Branch: If R3 != 0, jump back 4 instructions (to LD_DEC)

    # --- PHASE 4: Finalize h[n] ---
    # Formula: h[n] = (y[n] - sum) / x[0]
    ("LD_RAM",   "R1", "X_ZERO"),# Load Divisor: Fetch x[0] from fixed RAM address
    ("DIV",      "R0", "R1"),    # Divide: R0 = R0 / R1 (Result is the final h[n])
    ("ST_INC",   "R0", "00"),    # Store: Write h[n] to RAM, move ptr_h to next slot
    ("HLT",      "00", "00"),    # Termination: Stop all CPU operations
]

# ── Convert and print ────────────────────────────────────────────────────────
print(f"{'PC':<5} {'Mnemonic':<25} {'Binary'}")
print("-" * 45)

with open("program.asm", "w") as f:
    for i, inst in enumerate(program):
        op = inst[0]
        
        # Format 1: Loop instruction with immediate offset
        if op == "LOOP":
            offset = inst[1] # We pass the 4-bit binary offset directly
            binary = OPCODES[op] + offset
            asm_text = f"{op} {offset}"
            
        # Format 2 & 3: Register operations (1 or 2 operands)
        else:
            r1 = inst[1]
            r2 = inst[2]
            binary = OPCODES[op] + REGS[r1] + REGS[r2]
            
            if r2 == "00":
                asm_text = f"{op} {r1}"
            else:
                asm_text = f"{op} {r1}, {r2}"
                
        print(f"PC={i:<3} {asm_text:<25} {binary}")
        f.write(binary + "\n")

print("-" * 45)
print(f"Total: {len(program)} instructions written to program.asm. Ready to load into memory!")
