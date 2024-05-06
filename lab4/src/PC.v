`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/24 09:51:21
// Design Name: 
// Module Name: PC
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


module PC(
    input                       clk,
    input                       rst,
    input                       PCWrite,
    input           [31: 0]     npc,
    output reg      [31: 0]     pc
);
    always @(posedge clk) begin
        if(rst)
            pc <= 32'h1c00_0000;
        else if(PCWrite)
            pc <= npc;
        else
            pc <= pc;
    end

endmodule
