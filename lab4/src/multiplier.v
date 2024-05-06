module multiplier (
    input wire [31: 0] a, b,
    output wire [63: 0] res_s, res_u
);

wallace wall1 (
    .a(a),
    .b(b),
    .res(res_u)
);

wire sign_a, sign_b;
wire [31: 0] abs_a, abs_b;
wire [63: 0] abs_res;

assign sign_a = a[31];
assign sign_b = b[31];
assign abs_a = sign_a ? -a : a;
assign abs_b = sign_b ? -b : b;

wallace wall2 (
    .a(abs_a),
    .b(abs_b),
    .res(abs_res)
);

assign res_s = (sign_a ^ sign_b) ? -abs_res : abs_res;

endmodule