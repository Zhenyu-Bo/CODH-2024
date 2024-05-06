`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/23 17:45:17
// Design Name: 
// Module Name: blk_mem_gen_test
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


module blk_mem_gen_test(
    input                           clka,
    input       [ 9: 0]             addra,
    input       [31: 0]             dina,
    input                           ena,
    input                           wea,
    output      [31: 0]             douta
);
    blk_mem_gen_0 my_blk_mem_gen_0(
        .clka(clka),
        .addra(adrra),
        .dina(dina),
        .ena(ena),
        .wea(wea),
        .douta(douta)
    );
endmodule
