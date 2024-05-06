`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/19 21:22:22
// Design Name: 
// Module Name: Edge_capture
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


module Edge_capture(
    input                clk,
    input                rstn,
    input                sig_in,
    output               pos_edge,
    output               neg_edge
);
    reg sig_r1, sig_r2, sig_r3;

    always @(posedge clk) begin
        if (!rstn) begin
            sig_r1 <= 0;
            sig_r2 <= 0;
            sig_r3 <= 0;
        end
        else begin
            sig_r1 <= sig_in;
            sig_r2 <= sig_r1;
            sig_r3 <= sig_r2;
        end
    end

    assign pos_edge = sig_r3 & ~sig_r2;
    assign neg_edge = ~sig_r3 & sig_r2;
endmodule
