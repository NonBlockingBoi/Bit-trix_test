module ram #(
    parameter DEPTH = 64,
    parameter ADDR_WIDTH = 8  // log2(DEPTH)
)(
    input clk,
    input wr_en,
    input  [ADDR_WIDTH-1:0] addr,
    input  [7:0] wr_data,
    output reg [7:0] rd_data
);
    // Memory array: DEPTH locations, each 8 bits wide
    reg [7:0] mem [0:DEPTH-1];
 
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 8'b0;
    end
 
    always @(posedge clk) begin
        if (wr_en)
            mem[addr] <= wr_data;  // WRITE
        else
            rd_data <= mem[addr];  // READ
    end
 
endmodule
