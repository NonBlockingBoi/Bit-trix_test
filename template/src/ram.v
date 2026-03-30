module ram #(
    parameter DEPTH = 256,     // Fixed: 2^8 = 256 to match the 8-bit address space
    parameter ADDR_WIDTH = 8
)(
    input  wire clk,
    input  wire wr_en,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [7:0] wr_data,
    output wire [7:0] rd_data  // Changed from 'reg' to 'wire' for async read
);

    // Memory array
    reg [7:0] mem [0:DEPTH-1];

    // Initialization (Verilator and Vivado both fully support this for FPGAs)
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 8'b0;
    end

    // SYNCHRONOUS WRITE: Memory updates strictly on the clock edge
    always @(posedge clk) begin
        if (wr_en) begin
            mem[addr] <= wr_data;
        end
    end

    // ASYNCHRONOUS READ: The absolute key to a 1-cycle LOAD instruction.
    // This infers highly efficient Distributed RAM (LUTRAM) on the FPGA.
    assign rd_data = mem[addr];

endmodule
