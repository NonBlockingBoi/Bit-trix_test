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
    # --- PHASE 1: Setup ---
    ("LD_INC", "R0", "11"), # PC=0: Load constant '1' into R0 (R3 is pointer to constants)
    ("MOV",    "R2", "00"), # PC=1: Move '1' to R2 for later use in SUB
    ("CLR",    "R0", "00"), # PC=2: Reset Accumulator (R0=0, mac_clr=1)
    ("LD_INC", "R3", "11"), # PC=3: Load Loop Count (N) into R3

    # --- PHASE 2: Inner Loop ---
    ("LD_DEC", "R0", "01"), # PC=4: Load x[n-k] into R0, Decr R1 (Pointer)
    ("MOV",    "R3", "00"), # PC=5: Store x in R3 (temporary)
    ("LD_INC", "R0", "10"), # PC=6: Load h[k] into R0, Incr R2 (Pointer)
    ("MAC",    "R3", "00"), # PC=7: R0 = Saturated(R3 * R0) + Accumulator

    # --- PHASE 3: Loop Control ---
    ("SUB",    "R3", "R2"), # PC=8: R3 = R3 - 1 (Using R2 which holds '1')
    ("LOOP",   "1011", ""), # PC=9: Jump back 5 instructions (to PC=4)
    ("HLT",    "00", "00")  # PC=10
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
