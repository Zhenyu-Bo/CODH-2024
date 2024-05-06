`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/13 09:57:22
// Design Name: 
// Module Name: carry_save_adder
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


module CSA #(
    parameter WIDTH = 64
)(
    input       [WIDTH-1: 0]     a,
    input       [WIDTH-1: 0]     b,
    input       [WIDTH-1: 0]     c,
    output      [WIDTH-1: 0]     y1,
    output      [WIDTH-1: 0]     y2
);
    assign y1 = a ^ b ^ c;
    assign y2 = (a & b) | (b & c) | (c & a);
endmodule
