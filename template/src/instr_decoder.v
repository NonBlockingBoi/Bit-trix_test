module instr_decoder (
    input  [7:0] instr,
    output reg [3:0] opcode,
    output reg [1:0] rd,
    output reg [1:0] rs1,
    output reg [1:0] rs2,
    //output reg  (every enable signal that you would need )_
);
    always @(*) begin
        opcode = instr[7:4];
        rd     = instr[3:2];
        rs1    = instr[3:2];
        rs2    = instr[1:0];
 
     
 
        case (opcode)
          // your implementation of a decoder
        endcase
    end
endmodule
