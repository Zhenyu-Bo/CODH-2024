`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/18 20:22:55
// Design Name: 
// Module Name: ALU
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


module ALU(
    input               [31: 0]    src0,src1,
    input               [ 3: 0]    op,
    output      reg     [31: 0]    res
);
    wire [31: 0]    sub_res = src0 - src1;
    always @(*) begin
        case (op)
            4'b0000: res = src0 + src1;
            4'b0001: res = src0 - src1;
            4'b0010: res = sub_res[31] ? 32'b1 : 32'b0;
            // 无符号比较时，src0 < src1当且仅当src0首位为0，src1首位为1或二者首位相同的情况下res[31] = 1
            4'b0011: res = ( (~src0[31] & src1[31]) | (((src0[31] & src1[31]) | (~src0[31] & ~src1[31])) & sub_res[31]) ) ? 32'b1 : 32'b0;
            //4'b0011: res = ($unsigned(src0) < $unsigned(src1)) ? 32'b1 : 32'b0;
            4'b0100: res = src0 & src1;
            4'b0101: res = src0 | src1;
            4'b0110: res = ~(src0 | src1);
            4'b0111: res = src0 ^ src1;
            4'b1000: res = src0 << src1[4 : 0];
            4'b1001: res = src0 >> src1[4 : 0];
            4'b1010: res = src0 >>> src1[4 : 0];
            4'b1011: res = src1;
            default: res = 32'b0;
        endcase
    end

endmodule
