`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/16 18:26:17
// Design Name: 
// Module Name: Mul_33
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


module Mul_33(
    input       [32: 0]     a,
    input       [32: 0]     b,
    output      [65: 0]     res
);
    // 构造booth编码
    // booth[i] = 3'd0对应0,3'd1时对应x,3'd2时对应2x,3'd7时对应-x,3'd6时对应-2x
    wire [2:0]  booth[16:0];
    assign booth[16] =  (  b[31] == 1'b0 ) ? 
                        ( (b[30] == 1'b0) ? ((b[29] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[29] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[30] == 1'b0) ? ((b[29] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[29] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[15] =  (  b[31] == 1'b0 ) ? 
                        ( (b[30] == 1'b0) ? ((b[29] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[29] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[30] == 1'b0) ? ((b[29] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[29] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[14] =  (  b[29] == 1'b0 ) ? 
                        ( (b[28] == 1'b0) ? ((b[27] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[27] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[28] == 1'b0) ? ((b[27] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[27] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[13] =  (  b[27] == 1'b0 ) ? 
                        ( (b[26] == 1'b0) ? ((b[25] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[25] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[26] == 1'b0) ? ((b[25] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[25] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[12] =  (  b[25] == 1'b0 ) ? 
                        ( (b[24] == 1'b0) ? ((b[23] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[23] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[24] == 1'b0) ? ((b[23] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[23] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[11] =  (  b[23] == 1'b0 ) ? 
                        ( (b[22] == 1'b0) ? ((b[21] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[21] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[22] == 1'b0) ? ((b[21] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[21] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[10] =  (  b[21] == 1'b0 ) ? 
                        ( (b[20] == 1'b0) ? ((b[19] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[19] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[20] == 1'b0) ? ((b[19] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[19] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 9] =  (  b[19] == 1'b0 ) ? 
                        ( (b[18] == 1'b0) ? ((b[17] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[17] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[18] == 1'b0) ? ((b[17] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[17] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 8] =  (  b[17] == 1'b0 ) ? 
                        ( (b[16] == 1'b0) ? ((b[15] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[15] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[16] == 1'b0) ? ((b[15] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[15] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 7] =  (  b[15] == 1'b0 ) ? 
                        ( (b[14] == 1'b0) ? ((b[13] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[13] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[14] == 1'b0) ? ((b[13] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[13] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 6] =  (  b[13] == 1'b0 ) ? 
                        ( (b[12] == 1'b0) ? ((b[11] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[11] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[12] == 1'b0) ? ((b[11] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[11] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 5] =  (  b[11] == 1'b0 ) ? 
                        ( (b[10] == 1'b0) ? ((b[ 9] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[ 9] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[10] == 1'b0) ? ((b[ 9] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[ 9] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 4] =  (  b[ 9] == 1'b0 ) ? 
                        ( (b[ 8] == 1'b0) ? ((b[ 7] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[ 7] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[ 8] == 1'b0) ? ((b[ 7] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[ 7] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 3] =  (  b[ 7] == 1'b0 ) ? 
                        ( (b[ 6] == 1'b0) ? ((b[ 5] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[ 5] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[ 6] == 1'b0) ? ((b[ 5] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[ 5] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 2] =  (  b[ 5] == 1'b0 ) ? 
                        ( (b[ 4] == 1'b0) ? ((b[ 3] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[ 3] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[ 4] == 1'b0) ? ((b[ 3] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[ 3] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 1] =  (  b[ 3] == 1'b0 ) ? 
                        ( (b[ 2] == 1'b0) ? ((b[ 1] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[ 1] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[ 2] == 1'b0) ? ((b[ 1] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[ 1] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 0] =  (  b[ 1] == 1'b0 ) ? 
                        ( (b[ 0] == 1'b0) ? ((1'b0  == 1'b0) ? 3'd0 : 3'd1 ) :   ((1'b0  == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[ 0] == 1'b0) ? ((1'b0  == 1'b0) ? 3'd6 : 3'd7 ) :   ((1'b0  == 1'b0) ? 3'd7 : 3'd0) ) ;

    // 由booth编码构造16个相加项
    wire [65:0] add [16:0];
    wire [65:0] temp_a = {33'd0, a};
    wire [65:0] temp_not = ~temp_a + 1; 
    assign add[16] = ((booth[16] == 3'd0) ? 64'd0 : ((booth[16] == 3'd1) ? temp_a  : ((booth[16] == 3'd2) ? temp_a << 1 : ((booth[16] == 3'd7) ? temp_not  : temp_not << 1 )))) << 32;         
    assign add[15] = ((booth[15] == 3'd0) ? 64'd0 : ((booth[15] == 3'd1) ? temp_a  : ((booth[15] == 3'd2) ? temp_a << 1 : ((booth[15] == 3'd7) ? temp_not  : temp_not << 1 )))) << 30;
    assign add[14] = ((booth[14] == 3'd0) ? 64'd0 : ((booth[14] == 3'd1) ? temp_a  : ((booth[14] == 3'd2) ? temp_a << 1 : ((booth[14] == 3'd7) ? temp_not  : temp_not << 1 )))) << 28;
    assign add[13] = ((booth[13] == 3'd0) ? 64'd0 : ((booth[13] == 3'd1) ? temp_a  : ((booth[13] == 3'd2) ? temp_a << 1 : ((booth[13] == 3'd7) ? temp_not  : temp_not << 1 )))) << 26;
    assign add[12] = ((booth[12] == 3'd0) ? 64'd0 : ((booth[12] == 3'd1) ? temp_a  : ((booth[12] == 3'd2) ? temp_a << 1 : ((booth[12] == 3'd7) ? temp_not  : temp_not << 1 )))) << 24;
    assign add[11] = ((booth[11] == 3'd0) ? 64'd0 : ((booth[11] == 3'd1) ? temp_a  : ((booth[11] == 3'd2) ? temp_a << 1 : ((booth[11] == 3'd7) ? temp_not  : temp_not << 1 )))) << 22;
    assign add[10] = ((booth[10] == 3'd0) ? 64'd0 : ((booth[10] == 3'd1) ? temp_a  : ((booth[10] == 3'd2) ? temp_a << 1 : ((booth[10] == 3'd7) ? temp_not  : temp_not << 1 )))) << 20;
    assign add[ 9] = ((booth[ 9] == 3'd0) ? 64'd0 : ((booth[ 9] == 3'd1) ? temp_a  : ((booth[ 9] == 3'd2) ? temp_a << 1 : ((booth[ 9] == 3'd7) ? temp_not  : temp_not << 1 )))) << 18;
    assign add[ 8] = ((booth[ 8] == 3'd0) ? 64'd0 : ((booth[ 8] == 3'd1) ? temp_a  : ((booth[ 8] == 3'd2) ? temp_a << 1 : ((booth[ 8] == 3'd7) ? temp_not  : temp_not << 1 )))) << 16;
    assign add[ 7] = ((booth[ 7] == 3'd0) ? 64'd0 : ((booth[ 7] == 3'd1) ? temp_a  : ((booth[ 7] == 3'd2) ? temp_a << 1 : ((booth[ 7] == 3'd7) ? temp_not  : temp_not << 1 )))) << 14;
    assign add[ 6] = ((booth[ 6] == 3'd0) ? 64'd0 : ((booth[ 6] == 3'd1) ? temp_a  : ((booth[ 6] == 3'd2) ? temp_a << 1 : ((booth[ 6] == 3'd7) ? temp_not  : temp_not << 1 )))) << 12;
    assign add[ 5] = ((booth[ 5] == 3'd0) ? 64'd0 : ((booth[ 5] == 3'd1) ? temp_a  : ((booth[ 5] == 3'd2) ? temp_a << 1 : ((booth[ 5] == 3'd7) ? temp_not  : temp_not << 1 )))) << 10;
    assign add[ 4] = ((booth[ 4] == 3'd0) ? 64'd0 : ((booth[ 4] == 3'd1) ? temp_a  : ((booth[ 4] == 3'd2) ? temp_a << 1 : ((booth[ 4] == 3'd7) ? temp_not  : temp_not << 1 )))) <<  8;
    assign add[ 3] = ((booth[ 3] == 3'd0) ? 64'd0 : ((booth[ 3] == 3'd1) ? temp_a  : ((booth[ 3] == 3'd2) ? temp_a << 1 : ((booth[ 3] == 3'd7) ? temp_not  : temp_not << 1 )))) <<  6;
    assign add[ 2] = ((booth[ 2] == 3'd0) ? 64'd0 : ((booth[ 2] == 3'd1) ? temp_a  : ((booth[ 2] == 3'd2) ? temp_a << 1 : ((booth[ 2] == 3'd7) ? temp_not  : temp_not << 1 )))) <<  4;
    assign add[ 1] = ((booth[ 1] == 3'd0) ? 64'd0 : ((booth[ 1] == 3'd1) ? temp_a  : ((booth[ 1] == 3'd2) ? temp_a << 1 : ((booth[ 1] == 3'd7) ? temp_not  : temp_not << 1 )))) <<  2;
    assign add[ 0] = ((booth[ 0] == 3'd0) ? 64'd0 : ((booth[ 0] == 3'd1) ? temp_a  : ((booth[ 0] == 3'd2) ? temp_a << 1 : ((booth[ 0] == 3'd7) ? temp_not  : temp_not << 1 ))));

    // 使用全加器逐层累加
    //CSA中间量保存
    wire [65:0] temp_add [28:0];
    //例化CSA
    CSA #(66) csa_1(
        .a   (add[ 2]) ,
        .b   (add[ 1]),
        .c   (add[ 0]),
        .y1  (temp_add[ 1]),
        .y2  (temp_add[ 0])
    );
    CSA #(66) csa_2(
        .a   (add[ 5]) ,
        .b   (add[ 4]),
        .c   (add[ 3]),
        .y1  (temp_add[ 3]),
        .y2  (temp_add[ 2])
    ); 
    CSA #(66) csa_3(
        .a   (add[ 8]) ,
        .b   (add[ 7]),
        .c   (add[ 6]),
        .y1  (temp_add[ 5]),
        .y2  (temp_add[ 4])
    ); 
    CSA #(66) csa_4(
        .a   (add[11]) ,
        .b   (add[10]),
        .c   (add[ 9]),
        .y1  (temp_add[ 7]),
        .y2  (temp_add[ 6])
    ); 
    CSA #(66) csa_5(
        .a   (add[14]) ,
        .b   (add[13]),
        .c   (add[12]),
        .y1  (temp_add[ 9]),
        .y2  (temp_add[ 8])
    ); 
    CSA #(66) csa_6(
        .a   (add[15]) ,
        .b   (add[16]) ,
        .c   (temp_add[ 0]),
        .y1  (temp_add[11]),
        .y2  (temp_add[10])
    ); 
    CSA #(66) csa_7(
        .a   (temp_add[ 3]),
        .b   (temp_add[ 2]),
        .c   (temp_add[ 1]),
        .y1  (temp_add[13]),
        .y2  (temp_add[12])
    ); 
    CSA #(66) csa_8(
        .a   (temp_add[ 6]),
        .b   (temp_add[ 5]),
        .c   (temp_add[ 4]),
        .y1  (temp_add[15]),
        .y2  (temp_add[14])
    ); 
    CSA #(66) csa_9(
        .a   (temp_add[ 9]),
        .b   (temp_add[ 8]),
        .c   (temp_add[ 7]),
        .y1  (temp_add[17]),
        .y2  (temp_add[16])
    ); 
    CSA #(66) csa_10(
        .a   (temp_add[12]),
        .b   (temp_add[11]),
        .c   (temp_add[10]),
        .y1  (temp_add[19]),
        .y2  (temp_add[18])
    ); 
    CSA #(66) csa_11(
        .a   (temp_add[15]),
        .b   (temp_add[14]),
        .c   (temp_add[13]),
        .y1  (temp_add[21]),
        .y2  (temp_add[20])
    ); 
    CSA #(66) csa_12(
        .a   (temp_add[18]),
        .b   (temp_add[17]),
        .c   (temp_add[16]),
        .y1  (temp_add[23]),
        .y2  (temp_add[22])
    ); 
    CSA #(66) csa_13(
        .a   (temp_add[21]),
        .b   (temp_add[20]),
        .c   (temp_add[19]),
        .y1  (temp_add[25]),
        .y2  (temp_add[24])
    ); 
    CSA #(66) csa_14(
        .a   (temp_add[22]),
        .b   (temp_add[23]),
        .c   (temp_add[24]),
        .y1  (temp_add[27]),
        .y2  (temp_add[26])
    ); 

    wire [65:0] temp_res;
    CSA #(66) csa_15(
        .a(temp_add[25]),
        .b(temp_add[26]),
        .c(temp_add[27]),
        .y1(res),
        .y2()
    );

    //assign res = temp_res[63:0];
endmodule


