module mac_unit #(parameter WIDTH = 8) (
    input wire clk,
    input wire rst,
    input wire en,             // Added: High when MAC instruction is executing
    input wire clr,            // Added: High when we need to reset the sum for a new h[n]
    input wire signed [WIDTH-1:0] a,
    input wire signed [WIDTH-1:0] b,
    output reg signed [2*WIDTH-1:0] out,        // 16-bit internal accumulator
    output wire signed [WIDTH-1:0] sat_out      // 8-bit clamped output (MEETS RULE 3.1)
);

    // 1. Calculate the signed product
    wire signed [2*WIDTH-1:0] product = $signed(a) * $signed(b);

    // 2. The Accumulator Register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out <= 0;
        end else if (clr) begin
            out <= 0; // Reset accumulation for the next h[n] calculation
        end else if (en) begin
            out <= out + product; // Accumulate
        end
    end

    // OVERFLOW & UNDERFLOW DOCUMENTATION (For your Deliverables / Demo)
    // =========================================================================
    // The MAC internally accumulates at 16-bit precision to prevent overflow 
    // during the loop. When routing back to the 8-bit register file, we use 
    // Saturation Arithmetic. 
    // - If the 16-bit sum > 127, we clamp the 8-bit output to 127.
    // - If the 16-bit sum < -128, we clamp the 8-bit output to -128.
    // This prevents catastrophic signal wrapping (e.g., a large positive sum 
    // suddenly becoming a large negative number).
    // =========================================================================

    assign sat_out = (out > 16'sd127)  ? 8'sd127 :
                     (out < -16'sd128) ? -8'sd128 :
                     out[7:0];

endmodule
