module top (
    input clk,
    input rst,
    input [7:0] instr, 
    output reg [255:0] cycle_count
);
    
    // --- 1. INTERNAL CPU STATE ---
    reg [7:0] pc;
    reg [7:0] regs [0:3]; 
    reg halted;

    // --- 2. NEW WIRES FOR MAC INTEGRATION ---
    // These connect the decoder to the MAC unit and the MAC unit to the ALU
    wire mac_en, mac_clr;
    wire [15:0] mac_accum_raw; // The internal 16-bit high-precision sum
    wire [7:0]  mac_sat_out;   // The 8-bit saturated result for the Register File

    // --- 3. INSTRUCTION MEMORY ---
    reg [7:0] imem [0:255];
    initial begin
        $readmemb("program.asm", imem);
    end

    wire [7:0] current_instr = imem[pc];

    // --- 4. UPDATED DECODER INSTANTIATION ---
    // Ensure mac_en and mac_clr are connected here
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
        .mac_en(mac_en),   // <--- CONNECTED
        .mac_clr(mac_clr), // <--- CONNECTED
        .halt(halt)
    );

    // --- 5. NEW: MAC HARDWARE INSTANTIATION ---
    // This lives outside the 'always' block
    mac_unit #(.WIDTH(8)) hardware_mac (
        .clk(clk),
        .rst(rst),
        .en(mac_en),
        .clr(mac_clr),
        .a(regs[rs1_idx]),
        .b(regs[rs2_idx]),
        .out(mac_accum_raw),
        .sat_out(mac_sat_out)
    );

    // --- DATA RAM ---
    wire [7:0] ram_rdata;
    ram #(.DEPTH(256), .ADDR_WIDTH(8)) data_memory (
        .clk(clk),
        .wr_en(mem_we),
        .addr(regs[rs1_idx]),
        .wr_data(regs[rs2_idx]),
        .rd_data(ram_rdata)
    );

    // --- 6. UPDATED ALU MULTIPLEXER ---
    reg [7:0] alu_out;
    wire [7:0] val1 = regs[rs1_idx];
    wire [7:0] val2 = regs[rs2_idx];

    always @(*) begin
        case (alu_ctrl)
            4'b0000: alu_out = val1 + val2;
            4'b0001: alu_out = (val1 >= val2) ? (val1 - val2) : 8'h00; // Subtraction with saturation
            
            // KEY CHANGE: Route the Hardware MAC result to the ALU output
            4'b0010: alu_out = mac_sat_out; 
            
            4'b0011: alu_out = (val2 != 0) ? (mac_sat_out / val2) : 8'h00; 
            4'b0100: alu_out = val2;
            default: alu_out = 8'b0;
        endcase
    end

    // --- CORE DATAPATH (Remains the same) ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 8'b0;
            regs[0] <= 8'b0; regs[1] <= 8'b0;
            regs[2] <= 8'b0; regs[3] <= 8'b0;
            halted <= 1'b0;
        end else if (!halted) begin
            // PC Logic...
            if (halt) halted <= 1'b1;
            else if (branch_en && regs[3] != 8'b0) begin
                pc <= pc + {{4{current_instr[3]}}, current_instr[3:0]};
                regs[3] <= regs[3] - 1; 
            end else begin
                pc <= pc + 1;
            end

            // Writeback Logic...
            if (clr_rd) begin
                regs[rd_idx] <= 8'b0;
            end else if (reg_we) begin
                regs[rd_idx] <= reg_in_sel ? ram_rdata : alu_out;
            end

            // Pointer Logic...
            if (ptr_inc && (!reg_we || rs1_idx != rd_idx)) begin
                regs[rs1_idx] <= regs[rs1_idx] + 1;
            end else if (ptr_dec && (!reg_we || rs1_idx != rd_idx)) begin
                regs[rs1_idx] <= regs[rs1_idx] - 1;
            end
        end
    end

    // Cycle counter logic...
    always @(posedge clk or posedge rst) begin
        if (rst) cycle_count <= 256'b0;
        else cycle_count <= cycle_count + 1;
    end

endmodule
