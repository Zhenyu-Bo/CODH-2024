`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/18 21:34:59
// Design Name: 
// Module Name: RegFile
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


module RegFile(
    input                   clk,
    input       [ 4: 0]     ra0,ra1,
    output      [31: 0]     rd0,rd1,
    input       [ 4: 0]     wa,
    input       [31: 0]     wd,
    input                   we
);
    reg [31: 0] x[31: 0];

    initial begin
        x[0] = 32'b0; // 0号寄存器初始化为0
    end

    always @(posedge clk) begin
        if(we && wa)
            x[wa] <= wd; // we有效且wa不为0时写入数据
    end

    assign rd0 = ((ra0 == wa) && we && wa) ? wd : x[ra0]; // 读端口0，同时读写且wa不为0时读取写优先，读取要写入的数据
    assign rd1 = ((ra1 == wa) && we && wa) ? wd : x[ra1]; // 读端口1
endmodule
