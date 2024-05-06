`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/13 09:57:37
// Design Name: 
// Module Name: Mul
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


module Mul(
    input       [31: 0]     a,
    input       [31: 0]     b,
    output      [63: 0]     res
);
wire [63: 0] r_0_0;
wire [63: 0] r_0_1;
wire [63: 0] r_0_2;
wire [63: 0] r_0_3;
wire [63: 0] r_0_4;
wire [63: 0] r_0_5;
wire [63: 0] r_0_6;
wire [63: 0] r_0_7;
wire [63: 0] r_0_8;
wire [63: 0] r_0_9;
wire [63: 0] r_0_10;
wire [63: 0] r_0_11;
wire [63: 0] r_0_12;
wire [63: 0] r_0_13;
wire [63: 0] r_0_14;
wire [63: 0] r_0_15;
wire [63: 0] r_0_16;
wire [63: 0] r_0_17;
wire [63: 0] r_0_18;
wire [63: 0] r_0_19;
wire [63: 0] r_0_20;
wire [63: 0] r_0_21;
wire [63: 0] r_0_22;
wire [63: 0] r_0_23;
wire [63: 0] r_0_24;
wire [63: 0] r_0_25;
wire [63: 0] r_0_26;
wire [63: 0] r_0_27;
wire [63: 0] r_0_28;
wire [63: 0] r_0_29;
wire [63: 0] r_0_30;
wire [63: 0] r_0_31;
wire [63: 0] r_1_0;
wire [63: 0] r_1_1;
wire [63: 0] r_1_2;
wire [63: 0] r_1_3;
wire [63: 0] r_1_4;
wire [63: 0] r_1_5;
wire [63: 0] r_1_6;
wire [63: 0] r_1_7;
wire [63: 0] r_1_8;
wire [63: 0] r_1_9;
wire [63: 0] r_1_10;
wire [63: 0] r_1_11;
wire [63: 0] r_1_12;
wire [63: 0] r_1_13;
wire [63: 0] r_1_14;
wire [63: 0] r_1_15;
wire [63: 0] r_1_16;
wire [63: 0] r_1_17;
wire [63: 0] r_1_18;
wire [63: 0] r_1_19;
wire [63: 0] r_2_0;
wire [63: 0] r_2_1;
wire [63: 0] r_2_2;
wire [63: 0] r_2_3;
wire [63: 0] r_2_4;
wire [63: 0] r_2_5;
wire [63: 0] r_2_6;
wire [63: 0] r_2_7;
wire [63: 0] r_2_8;
wire [63: 0] r_2_9;
wire [63: 0] r_2_10;
wire [63: 0] r_2_11;
wire [63: 0] r_2_12;
wire [63: 0] r_2_13;
wire [63: 0] r_3_0;
wire [63: 0] r_3_1;
wire [63: 0] r_3_2;
wire [63: 0] r_3_3;
wire [63: 0] r_3_4;
wire [63: 0] r_3_5;
wire [63: 0] r_3_6;
wire [63: 0] r_3_7;
wire [63: 0] r_3_8;
wire [63: 0] r_3_9;
wire [63: 0] r_4_0;
wire [63: 0] r_4_1;
wire [63: 0] r_4_2;
wire [63: 0] r_4_3;
wire [63: 0] r_4_4;
wire [63: 0] r_4_5;
wire [63: 0] r_5_0;
wire [63: 0] r_5_1;
wire [63: 0] r_5_2;
wire [63: 0] r_5_3;
wire [63: 0] r_6_0;
wire [63: 0] r_6_1;
wire [63: 0] r_7_0;
wire [63: 0] r_7_1;
wire [63: 0] r_8_0;
wire [63: 0] r_8_1;

assign r_0_0 = {32'b0, a & {32{b[0]}}};
assign r_0_1 = {31'b0, a & {32{b[1]}}, 1'b0};
assign r_0_2 = {30'b0, a & {32{b[2]}}, 2'b0};
assign r_0_3 = {29'b0, a & {32{b[3]}}, 3'b0};
assign r_0_4 = {28'b0, a & {32{b[4]}}, 4'b0};
assign r_0_5 = {27'b0, a & {32{b[5]}}, 5'b0};
assign r_0_6 = {26'b0, a & {32{b[6]}}, 6'b0};
assign r_0_7 = {25'b0, a & {32{b[7]}}, 7'b0};
assign r_0_8 = {24'b0, a & {32{b[8]}}, 8'b0};
assign r_0_9 = {23'b0, a & {32{b[9]}}, 9'b0};
assign r_0_10 = {22'b0, a & {32{b[10]}}, 10'b0};
assign r_0_11 = {21'b0, a & {32{b[11]}}, 11'b0};
assign r_0_12 = {20'b0, a & {32{b[12]}}, 12'b0};
assign r_0_13 = {19'b0, a & {32{b[13]}}, 13'b0};
assign r_0_14 = {18'b0, a & {32{b[14]}}, 14'b0};
assign r_0_15 = {17'b0, a & {32{b[15]}}, 15'b0};
assign r_0_16 = {16'b0, a & {32{b[16]}}, 16'b0};
assign r_0_17 = {15'b0, a & {32{b[17]}}, 17'b0};
assign r_0_18 = {14'b0, a & {32{b[18]}}, 18'b0};
assign r_0_19 = {13'b0, a & {32{b[19]}}, 19'b0};
assign r_0_20 = {12'b0, a & {32{b[20]}}, 20'b0};
assign r_0_21 = {11'b0, a & {32{b[21]}}, 21'b0};
assign r_0_22 = {10'b0, a & {32{b[22]}}, 22'b0};
assign r_0_23 = {9'b0, a & {32{b[23]}}, 23'b0};
assign r_0_24 = {8'b0, a & {32{b[24]}}, 24'b0};
assign r_0_25 = {7'b0, a & {32{b[25]}}, 25'b0};
assign r_0_26 = {6'b0, a & {32{b[26]}}, 26'b0};
assign r_0_27 = {5'b0, a & {32{b[27]}}, 27'b0};
assign r_0_28 = {4'b0, a & {32{b[28]}}, 28'b0};
assign r_0_29 = {3'b0, a & {32{b[29]}}, 29'b0};
assign r_0_30 = {2'b0, a & {32{b[30]}}, 30'b0};
assign r_0_31 = {1'b0, a & {32{b[31]}}, 31'b0};

carry_save_adder csa_1_0 (.a(r_0_0), .b(r_0_1), .c(r_0_2), .u(r_1_0), .v(r_1_1));
carry_save_adder csa_1_1 (.a(r_0_3), .b(r_0_4), .c(r_0_5), .u(r_1_2), .v(r_1_3));
carry_save_adder csa_1_2 (.a(r_0_6), .b(r_0_7), .c(r_0_8), .u(r_1_4), .v(r_1_5));
carry_save_adder csa_1_3 (.a(r_0_9), .b(r_0_10), .c(r_0_11), .u(r_1_6), .v(r_1_7));
carry_save_adder csa_1_4 (.a(r_0_12), .b(r_0_13), .c(r_0_14), .u(r_1_8), .v(r_1_9));
carry_save_adder csa_1_5 (.a(r_0_15), .b(r_0_16), .c(r_0_17), .u(r_1_10), .v(r_1_11));
carry_save_adder csa_1_6 (.a(r_0_18), .b(r_0_19), .c(r_0_20), .u(r_1_12), .v(r_1_13));
carry_save_adder csa_1_7 (.a(r_0_21), .b(r_0_22), .c(r_0_23), .u(r_1_14), .v(r_1_15));
carry_save_adder csa_1_8 (.a(r_0_24), .b(r_0_25), .c(r_0_26), .u(r_1_16), .v(r_1_17));
carry_save_adder csa_1_9 (.a(r_0_27), .b(r_0_28), .c(r_0_29), .u(r_1_18), .v(r_1_19));
carry_save_adder csa_2_0 (.a(r_0_30), .b(r_0_31), .c(r_1_0), .u(r_2_0), .v(r_2_1));
carry_save_adder csa_2_1 (.a(r_1_1), .b(r_1_2), .c(r_1_3), .u(r_2_2), .v(r_2_3));
carry_save_adder csa_2_2 (.a(r_1_4), .b(r_1_5), .c(r_1_6), .u(r_2_4), .v(r_2_5));
carry_save_adder csa_2_3 (.a(r_1_7), .b(r_1_8), .c(r_1_9), .u(r_2_6), .v(r_2_7));
carry_save_adder csa_2_4 (.a(r_1_10), .b(r_1_11), .c(r_1_12), .u(r_2_8), .v(r_2_9));
carry_save_adder csa_2_5 (.a(r_1_13), .b(r_1_14), .c(r_1_15), .u(r_2_10), .v(r_2_11));
carry_save_adder csa_2_6 (.a(r_1_16), .b(r_1_17), .c(r_1_18), .u(r_2_12), .v(r_2_13));
carry_save_adder csa_3_0 (.a(r_1_19), .b(r_2_0), .c(r_2_1), .u(r_3_0), .v(r_3_1));
carry_save_adder csa_3_1 (.a(r_2_2), .b(r_2_3), .c(r_2_4), .u(r_3_2), .v(r_3_3));
carry_save_adder csa_3_2 (.a(r_2_5), .b(r_2_6), .c(r_2_7), .u(r_3_4), .v(r_3_5));
carry_save_adder csa_3_3 (.a(r_2_8), .b(r_2_9), .c(r_2_10), .u(r_3_6), .v(r_3_7));
carry_save_adder csa_3_4 (.a(r_2_11), .b(r_2_12), .c(r_2_13), .u(r_3_8), .v(r_3_9));
carry_save_adder csa_4_0 (.a(r_3_0), .b(r_3_1), .c(r_3_2), .u(r_4_0), .v(r_4_1));
carry_save_adder csa_4_1 (.a(r_3_3), .b(r_3_4), .c(r_3_5), .u(r_4_2), .v(r_4_3));
carry_save_adder csa_4_2 (.a(r_3_6), .b(r_3_7), .c(r_3_8), .u(r_4_4), .v(r_4_5));
carry_save_adder csa_5_0 (.a(r_3_9), .b(r_4_0), .c(r_4_1), .u(r_5_0), .v(r_5_1));
carry_save_adder csa_5_1 (.a(r_4_2), .b(r_4_3), .c(r_4_4), .u(r_5_2), .v(r_5_3));
carry_save_adder csa_6_0 (.a(r_4_5), .b(r_5_0), .c(r_5_1), .u(r_6_0), .v(r_6_1));
carry_save_adder csa_7_0 (.a(r_5_2), .b(r_5_3), .c(r_6_0), .u(r_7_0), .v(r_7_1));
carry_save_adder csa_8_0 (.a(r_6_1), .b(r_7_0), .c(r_7_1), .u(r_8_0), .v(r_8_1));

assign res = r_8_0 + r_8_1;
endmodule
