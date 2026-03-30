module opcode_gen (
    input  [2:0] op,    // 3 bits now (6 operations)
    input  [1:0] reg1,  // Rd / Rs1
    input  [1:0] reg2,  // Rs2
    output reg [7:0] instr
);
    reg [3:0] opcode;
 
    always @(*) begin
        case (op)
            3'b000: opcode = 4'b0000; // NOP
            3'b001: opcode = 4'b0001; // MAC
            3'b010: opcode = 4'b0010; // LOAD_RAM
            3'b011: opcode = 4'b0011; // STORE_RAM
            3'b100: opcode = 4'b0100; // LOAD_REG
            3'b101: opcode = 4'b0101; // STORE_REG
            default: opcode = 4'b0000; // NOP
        endcase
 
        instr = {opcode, reg1, reg2};
    end
endmodule
 
