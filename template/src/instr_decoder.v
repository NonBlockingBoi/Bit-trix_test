module instr_decoder (
    input  wire [7:0] instr,
    
    // Register indices
    output reg  [3:0] opcode,
    output reg  [1:0] rd,
    output reg  [1:0] rs1,
    output reg  [1:0] rs2,
    
    // Datapath Control Signals
    output reg        reg_we,      // Enable writing to Register File
    output reg        mem_we,      // Enable writing to RAM
    output reg        mem_re,      // Enable reading from RAM
    output reg  [3:0] alu_ctrl,    // ALU Operation Select
    output reg        reg_in_sel,  // 0: ALU Output, 1: RAM Output
    output reg        ptr_inc,     // Trigger Register Auto-Increment
    output reg        ptr_dec,     // Trigger Register Auto-Decrement
    output reg        branch_en,   // Trigger Loop Branching
    output reg        clr_rd,      // Force 0 into Destination Register
    output reg        halt         // Halt execution
);

    // ALU Control Codes (Internal to our design)
    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;
    localparam ALU_MAC = 4'b0010;
    localparam ALU_DIV = 4'b0011;
    localparam ALU_PASS= 4'b0100; // Pass Rs1 straight through

    always @(*) begin
        // 1. Extract Fields
        opcode = instr[7:4];
        rd     = instr[3:2]; // Rd and Rs1 share the same bits in 2-operand ops
        rs1    = instr[3:2]; 
        rs2    = instr[1:0];

        // 2. Default Control Signals (CRITICAL to prevent inferred latches in Vivado/Verilator)
        reg_we     = 1'b0;
        mem_we     = 1'b0;
        mem_re     = 1'b0;
        alu_ctrl   = ALU_ADD;
        reg_in_sel = 1'b0; 
        ptr_inc    = 1'b0;
        ptr_dec    = 1'b0;
        branch_en  = 1'b0;
        clr_rd     = 1'b0;
        halt       = 1'b0;

        // 3. Instruction Decode Logic
        case (opcode)
            4'b0000: begin /* NOP */ end
            
            // Memory Operations (Using Rs1 as pointer)
            4'b0001: begin // LD_INC Rd, [Rs1]
                reg_we     = 1'b1;
                mem_re     = 1'b1;
                reg_in_sel = 1'b1; // Select RAM output
                ptr_inc    = 1'b1; // Tell reg file to increment Rs1
            end
            
            4'b0010: begin // LD_DEC Rd, [Rs1]
                reg_we     = 1'b1;
                mem_re     = 1'b1;
                reg_in_sel = 1'b1;
                ptr_dec    = 1'b1; // Tell reg file to decrement Rs1
            end
            
            4'b0011: begin // ST_INC [Rs1], Rd (Note: Rs2 field holds the data register here)
                mem_we     = 1'b1;
                ptr_inc    = 1'b1;
            end

            // Register/ALU Operations
            4'b0100: begin // MOV Rd, Rs2
                reg_we   = 1'b1;
                alu_ctrl = ALU_PASS;
            end
            
            4'b0101: begin // CLR Rd
                reg_we = 1'b1;
                clr_rd = 1'b1;
            end
            
            4'b0110: begin // ADD Rd, Rs2
                reg_we   = 1'b1;
                alu_ctrl = ALU_ADD;
            end
            
            4'b0111: begin // SUB Rd, Rs2
                reg_we   = 1'b1;
                alu_ctrl = ALU_SUB;
            end
            
            // Complex Hardware Blocks
            4'b1000: begin // MAC Rs1, Rs2 (Implicitly Accumulates to R0)
                // Note: The datapath must hardwire the MAC accumulator to R0
                alu_ctrl = ALU_MAC;
                // MAC manages its own internal R0 accumulation in the ALU, no standard reg_we needed
            end
            
            4'b1001: begin // DIV Rd, Rs2
                reg_we   = 1'b1;
                alu_ctrl = ALU_DIV;
            end
            
            // Control Flow
            4'b1010: begin // LOOP offset (Implicitly uses R3 as counter)
                branch_en = 1'b1;
                // The datapath will look at instr[3:0] for the backwards jump offset
            end
            
            4'b1111: begin // HLT
                halt = 1'b1;
            end
            
            default: halt = 1'b1; // Catch-all for safety
        endcase
    end
endmodule
