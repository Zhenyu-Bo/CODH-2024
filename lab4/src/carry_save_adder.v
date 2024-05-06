module carry_save_adder (
    input wire [63: 0] a, b, c,
    output wire [63: 0] u, v
);

assign u = a ^ b ^ c;
assign v[63: 1] = (a & b) | (a & c) | (b & c);
assign v[0] = 0;

endmodule