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
    # --- PHASE 1: Setup Constants ---
    ("LD_INC",   "R2", "R2"),    # Load '1' from RAM into R2 (to use for decrementing R3)
    ("CLR",      "R0", "00"),    # R0 = 0
    ("LD_INC",   "R3", "R3"),    # Load Loop Count (N) into R3
    
    # --- PHASE 2: Inner Loop (Summation) ---
    ("LD_DEC",   "R1", "R1"),    # PC=3: Fetch x[n-k], ptr_x--
    ("LD_INC",   "R2", "R2"),    # PC=4: Fetch h[k], ptr_h++
    ("MAC",      "R1", "R2"),    # PC=5: R0 = R0 + (R1 * R2)
    
    # --- PHASE 3: Loop Control ---
    ("SUB",      "R3", "R2"),    # PC=6: R3 = R3 - 1 (R2 holds the '1')
    ("LOOP",     "1100", ""),    # PC=7: Jump back 4 instructions (1100) if R3 != 0
    
    # --- PHASE 4: Finalize ---
    ("DIV",      "R0", "R1"),    # PC=8: Divide by x[0] (assumes x[0] was loaded into R1)
    ("ST_INC",   "R0", "00"),    # PC=9: Store result h[n]
    ("HLT",      "00", "00"),    # PC=10
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
