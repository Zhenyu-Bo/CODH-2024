`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/19 21:22:44
// Design Name: 
// Module Name: Segment
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


module Segment(
    input                       clk,
    input                       rst,
    input       [31:0]          output_data,
    input       [ 7:0]          output_valid,

    //output reg  [ 3:0]          seg_data,
    //output reg  [ 2:0]          seg_an
    output  reg [ 7:0]          an,
    output  reg [ 6:0]          seg
);

reg [31:0]  counter;
parameter TIME_CNT = 250_000;
always @(posedge clk) begin
    if (rst)
        counter <= 0;
    else if(counter >= TIME_CNT)
        counter <= 0;
    else
        counter <= counter + 1;
end

reg [2:0] seg_id;
always @(posedge clk) begin
    if(rst || seg_id >= 8)
        seg_id <= 0;
    else if(counter == 1)
        seg_id <= seg_id + 1;
end

reg [ 2: 0] seg_an;
reg [ 3: 0] seg_data;

always @(*) begin
    seg_data = 0;
    seg_an = seg_id;
    case (seg_id)
        3'b000: seg_data = output_data[ 3: 0];
        3'b001: seg_data = output_data[ 7: 4];
        3'b010: seg_data = output_data[11: 8];
        3'b011: seg_data = output_data[15:12];
        3'b100: seg_data = output_data[19:16];
        3'b101: seg_data = output_data[23:20];
        3'b110: seg_data = output_data[27:24];
        3'b111: seg_data = output_data[31:28];
        //default: seg_data = output_data[31:28];
    endcase
    //output_valid[seg_id] = 0时，显示0号数码管的值，seg_id对应的数码管不显示 
    if(output_valid[seg_id] == 0) begin
        seg_an = 0;
        seg_data = output_data[3:0];
    end
end

always @(*) begin
    case (seg_an)
        3'b000: an = 8'b11111110;
        3'b001: an = 8'b11111101;
        3'b010: an = 8'b11111011;
        3'b011: an = 8'b11110111;
        3'b100: an = 8'b11101111;
        3'b101: an = 8'b11011111;
        3'b110: an = 8'b10111111;
        3'b111: an = 8'b01111111;
        default: an = 8'b11111111;
    endcase
end

always @(*) begin
    case (seg_data)
        4'b0000: seg = 7'b0000001;
        4'b0001: seg = 7'b1001111;
        4'b0010: seg = 7'b0010010;
        4'b0011: seg = 7'b0000110;
        4'b0100: seg = 7'b1001100;
        4'b0101: seg = 7'b0100100;
        4'b0110: seg = 7'b0100000;
        4'b0111: seg = 7'b0001111;
        4'b1000: seg = 7'b0000000;
        4'b1001: seg = 7'b0001100;
        4'b1010: seg = 7'b0001000;
        4'b1011: seg = 7'b1100000;
        4'b1100: seg = 7'b0110001;
        4'b1101: seg = 7'b1000010;
        4'b1110: seg = 7'b0110000;
        4'b1111: seg = 7'b0111000;
        default: seg = 7'b1111111;
    endcase
end

endmodule