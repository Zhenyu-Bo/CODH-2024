`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/03 19:41:45
// Design Name: 
// Module Name: Forward
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


module Forward(
    input           [ 0: 0]         EX_MEM_rf_we,
    input           [ 0: 0]         MEM_WB_rf_we,
    input           [ 4: 0]         EX_MEM_dest,
    input           [ 4: 0]         MEM_WB_dest,
    input           [ 4: 0]         ID_EX_raddr1,
    input           [ 4: 0]         ID_EX_raddr2,
    input           [31: 0]         MEM_rf_wd,
    input           [31: 0]         WB_rf_wd,

    output  reg     [ 0: 0]         forwarda_en,
    output  reg     [ 0: 0]         forwardb_en,
    output  reg     [31: 0]         forwarda,
    output  reg     [31: 0]         forwardb
    //output  reg     [ 1: 0]         forward1_sel,
    //output  reg     [ 1: 0]         forward2_sel
);
    always @(*) begin
        if(EX_MEM_dest == ID_EX_raddr1 && EX_MEM_rf_we && EX_MEM_dest) begin
            //forward1_sel = 2'b01;
            forwarda_en = 1;
            forwarda = MEM_rf_wd;
        end
        else if(MEM_WB_dest == ID_EX_raddr1 && MEM_WB_rf_we && MEM_WB_dest) begin
            //forward1_sel = 2'b10;
            forwarda_en = 1;
            forwarda = WB_rf_wd;
        end
        else begin
            //forward1_sel = 2'b00;
            forwarda_en = 0;
            forwarda    = 0;
        end
    end

    always @(*) begin
        if(EX_MEM_dest == ID_EX_raddr2 && EX_MEM_rf_we && EX_MEM_dest) begin
            //forward2_sel = 2'b01;
            forwardb_en = 1;
            forwardb = MEM_rf_wd;
        end
        else if(MEM_WB_dest == ID_EX_raddr2 && MEM_WB_rf_we && MEM_WB_dest) begin
            //forward2_sel = 2'b10;
            forwardb_en = 1;
            forwardb = WB_rf_wd;
        end
        else begin
            //forward2_sel = 2'b00;
            forwardb_en = 0;
            forwardb    = 0;
        end
    end

endmodule

