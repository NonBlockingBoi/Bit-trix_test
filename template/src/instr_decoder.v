module instr_decoder (
    input  wire [7:0] instr,     // 8-bit Instruction from IMEM
    
    // --- Register Indices ---
    output reg  [3:0] opcode,    // [7:4] Operation code
    output reg  [1:0] rd,        // [3:2] Destination Register
    output reg  [1:0] rs1,       // [3:2] Source Register 1 (Pointer)
    output reg  [1:0] rs2,       // [1:0] Source Register 2 (Operand)
    
    // --- Control Signals ---
    output reg        reg_we,      // High to write ALU/RAM result to Register File
    output reg        mem_we,      // High to write data to RAM (Store)
    output reg        mem_re,      // High to read data from RAM (Load)
    output reg  [3:0] alu_ctrl,    // Selects ALU operation (ADD, SUB, MAC, etc.)
    output reg        reg_in_sel,  // 0: ALU result -> Reg, 1: RAM data -> Reg
    output reg        ptr_inc,     // Auto-increment the pointer in Rs1
    output reg        ptr_dec,     // Auto-decrement the pointer in Rs1
    output reg        branch_en,   // High for LOOP instruction
    output reg        clr_rd,      // Forces the destination register to 0
    output reg        mac_en,      // Enable signal for the MAC hardware block
    output reg        mac_clr,     // Reset signal for the 16-bit MAC accumulator
    output reg        halt         // Stops the Program Counter
);

    // --- ALU Opcode Definitions ---
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_MAC  = 4'b0010;
    localparam ALU_DIV  = 4'b0011;
    localparam ALU_PASS = 4'b0100; // Passes Rs2 to output (for MOV)

    always @(*) begin
        // --- 1. Field Extraction ---
        opcode = instr[7:4];
        rd     = instr[3:2]; 
        rs1    = instr[3:2]; 
        rs2    = instr[1:0];

        // --- 2. Default Signal States (Prevents Inferred Latches) ---
        reg_we     = 1'b0;
        mem_we     = 1'b0;
        mem_re     = 1'b0;
        alu_ctrl   = ALU_ADD;
        reg_in_sel = 1'b0; 
        ptr_inc    = 1'b0;
        ptr_dec    = 1'b0;
        branch_en  = 1'b0;
        clr_rd     = 1'b0;
        mac_en     = 1'b0;
        mac_clr    = 1'b0;
        halt       = 1'b0;

        // --- 3. Opcode Decoding Table ---
        case (opcode)
            // LD_INC: Load from RAM[Rs1] to Rd, then increment Rs1
            4'b0001: begin 
                reg_we = 1'b1; mem_re = 1'b1; reg_in_sel = 1'b1; ptr_inc = 1'b1;
            end
            
            // LD_DEC: Load from RAM[Rs1] to Rd, then decrement Rs1
            4'b0010: begin 
                reg_we = 1'b1; mem_re = 1'b1; reg_in_sel = 1'b1; ptr_dec = 1'b1;
            end
            
            // ST_INC: Store Rs2 into RAM[Rs1], then increment Rs1
            4'b0011: begin 
                mem_we = 1'b1; ptr_inc = 1'b1;
            end
            
            // MOV: Copy Rs2 value into Rd
            4'b0100: begin 
                reg_we = 1'b1; alu_ctrl = ALU_PASS;
            end
            
            // CLR: Set Rd to 0. If R0 is cleared, reset the MAC accumulator.
            4'b0101: begin 
                reg_we = 1'b1; clr_rd = 1'b1;
                if (rd == 2'b00) mac_clr = 1'b1; 
            end
            
            // ADD / SUB: Standard 8-bit Arithmetic
            4'b0110: begin reg_we = 1'b1; alu_ctrl = ALU_ADD; end
            4'b0111: begin reg_we = 1'b1; alu_ctrl = ALU_SUB; end
            
            // MAC: Multiply-Accumulate (R1 * R2). Result hard-wired to R0.
            4'b1000: begin 
                alu_ctrl = ALU_MAC;
                mac_en   = 1'b1;
                reg_we   = 1'b1;  // Update R0 in Register File
                rd       = 2'b00; // Destination forced to R0
            end
            
            // DIV: Divide Accumulator (R0) by Rs2. Result hard-wired to R0.
            4'b1001: begin 
                reg_we = 1'b1; alu_ctrl = ALU_DIV; rd = 2'b00;
            end
            
            // LOOP: Branch backwards if R3 != 0. Offset is in instr[3:0].
            4'b1010: begin 
                branch_en = 1'b1;
            end
            
            // HLT: Halt the CPU
            4'b1111: halt = 1'b1;
            
            default: halt = 1'b1;
        endcase
    end
endmodule
