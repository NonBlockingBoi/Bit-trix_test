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
    ("CLR",    "R0", "00"), # Clear Accumulator (R0 = 0)
    ("LD_DEC", "R1", "R1"), # Load x[n-k] into R1, decrement pointer
    ("LD_INC", "R2", "R2"), # Load h[k] into R2, increment pointer
    ("MAC",    "R1", "R2"), # R0 = R0 + (R1 * R2)
    ("LOOP",   "1100", ""), # If R3 != 0, jump back 4 instructions (2's complement offset: -4 = 1100)
    ("DIV",    "R0", "R1"), # Divide accumulated sum by x[0]
    ("ST_INC", "R0", "R0"), # Store resulting h[n] into RAM
    ("HLT",    "00", "00"), # Stop CPU
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
