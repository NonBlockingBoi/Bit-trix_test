module top (
    input clk,
    input rst,
    input [7:0] instr, // We ignore this external input because we embedded the IMEM to support Branching
    output reg [255:0] cycle_count
);
    
    // --- INTERNAL CPU STATE ---
    reg [7:0] pc;
    reg [7:0] regs [0:3]; // The 4 allowed General Purpose Registers
    reg halted;

    // --- INSTRUCTION MEMORY (ROM) ---
    // Embedded internally so the CPU can control its own looping and branching
    reg [7:0] imem [0:255];
    initial begin
        $readmemb("program.asm", imem);
    end

    // Fetch the current instruction
    wire [7:0] current_instr = imem[pc];

    // --- INSTRUCTION DECODER ---
    wire [3:0] opcode;
    wire [1:0] rd_idx, rs1_idx, rs2_idx;
    wire reg_we, mem_we, mem_re;
    wire [3:0] alu_ctrl;
    wire reg_in_sel, ptr_inc, ptr_dec, branch_en, clr_rd, halt;

    instr_decoder decoder (
        .instr(current_instr),
        .opcode(opcode),
        .rd(rd_idx),
        .rs1(rs1_idx),
        .rs2(rs2_idx),
        .reg_we(reg_we),
        .mem_we(mem_we),
        .mem_re(mem_re),
        .alu_ctrl(alu_ctrl),
        .reg_in_sel(reg_in_sel),
        .ptr_inc(ptr_inc),
        .ptr_dec(ptr_dec),
        .branch_en(branch_en),
        .clr_rd(clr_rd),
        .halt(halt)
    );

    // --- DATA RAM ---
    wire [7:0] ram_rdata;
    ram #(
        .DEPTH(256),
        .ADDR_WIDTH(8)
    ) data_memory (
        .clk(clk),
        .wr_en(mem_we),
        .addr(regs[rs1_idx]),    // Rs1 acts as the pointer
        .wr_data(regs[rs2_idx]), // Rs2 holds the data to store
        .rd_data(ram_rdata)
    );

    // --- ARITHMETIC LOGIC UNIT (ALU) ---
    reg [7:0] alu_out;
    wire [7:0] val1 = regs[rs1_idx];
    wire [7:0] val2 = regs[rs2_idx];

    always @(*) begin
        case (alu_ctrl)
            4'b0000: alu_out = val1 + val2;                      // ADD
            4'b0001: alu_out = val1 - val2;                      // SUB
            4'b0010: alu_out = regs[0] + (val1 * val2);          // MAC (Accumulates into R0)
            4'b0011: alu_out = (val2 != 0) ? (regs[0] / val2) : 8'h00; // DIV (R0 / val2)
            4'b0100: alu_out = val2;                             // PASS (MOV)
            default: alu_out = 8'b0;
        endcase
    end

    // --- CORE DATAPATH & CONTROL ---
always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 8'b0;
            regs[0] <= 8'b0; regs[1] <= 8'b0;
            regs[2] <= 8'b0; regs[3] <= 8'b0;
            halted <= 1'b0;
        end else if (!halted) begin
            
            // --- 1. PC & BRANCHING ---
            if (halt) halted <= 1'b1;
            else if (branch_en && regs[3] != 8'b0) begin
                pc <= pc + {{4{current_instr[3]}}, current_instr[3:0]};
                regs[3] <= regs[3] - 1; // Auto-decrement loop counter
            end else begin
                pc <= pc + 1;
            end

            // --- 2. UNIFIED REGISTER WRITEBACK ---
            // Prioritize Pointer updates vs ALU results
            if (clr_rd) begin
                regs[rd_idx] <= 8'b0;
            end else if (reg_we) begin
                // Select input: RAM, ALU Result, or Pointer Update
                if (reg_in_sel) begin
                    regs[rd_idx] <= ram_rdata;
                end else begin
                    regs[rd_idx] <= alu_out;
                end
            end
            
            // Pointer increments must be handled carefully to not overwrite writeback
            if (ptr_inc && (!reg_we || rs1_idx != rd_idx)) begin
                regs[rs1_idx] <= regs[rs1_idx] + 1;
            end else if (ptr_dec && (!reg_we || rs1_idx != rd_idx)) begin
                regs[rs1_idx] <= regs[rs1_idx] - 1;
            end
        end
    end
    // do not touch this !!!!!

endmodule
