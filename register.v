module reg_file (
    input clk,
    input rst,
    input wr_en,
    input [1:0] rd_addr,   // destination register (write)
    input [1:0] rs1_addr,  // source register 1
    input [1:0] rs2_addr,  // source register 2
    input [7:0] wr_data,   // data to write
    output reg [7:0] rs1_data, // data out from rs1
    output reg [7:0] rs2_data  // data out from rs2
);
    reg [7:0] regs [0:3]; // 4 registers of 8 bits
    integer i;
 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 4; i = i + 1)
                regs[i] <= 8'b0;
        end else if (wr_en) begin
            regs[rd_addr] <= wr_data;
        end
    end
 
    always @(*) begin
        rs1_data = regs[rs1_addr];
        rs2_data = regs[rs2_addr];
    end
endmodule
