`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/23 17:35:29
// Design Name: 
// Module Name: dist_mem_gen_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dist_mem_gen_test(
    input                           clk,
    input       [ 9: 0]             a,
    input       [31: 0]             d,
    input                           we,
    output      [31: 0]             spo
);
    dist_mem_gen_0 my_dist_mem_gen_0(
        .clk(clk),
        .a(a),
        .d(d),
        .we(we),
        .spo(spo)
    );
    
endmodule
