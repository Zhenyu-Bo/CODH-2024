`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/25 10:49:08
// Design Name: 
// Module Name: Top_blk
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

module Top_blk(
    input                           clk,
    input                           rstn,  // cpu_resetn
    input                           start, // btnc
    input                           prior, // btnl
    input                           next,  // btnr
    input                           up,    // sw15
    input                           choice, // sw0，选择显示data还是count
    output                          done,  // led15
    output          [ 9: 0]         index, // led9-0
    output          [ 7: 0]         an,
    output          [ 6: 0]         seg,
    output                          up_sort,
    output                          show
    //output          [ 2: 0]         seg_an,
    //output          [ 3: 0]         seg_data,
    //output                          doing
);
    
    wire            pos_prior;
    wire            pos_next;
    /*wire            pos_choice;
    wire            neg_choice;

    Edge_capture edge_capture_choice(
        .clk(clk),
        .rstn(rstn),
        .sig_in(choice),
        .pos_edge(pos_choice),
        .neg_edge(neg_choice)
    );*/

    Edge_capture edge_capture_prior(
        .clk(clk),
        .rstn(rstn),
        .sig_in(prior),
        .pos_edge(pos_prior),
        .neg_edge()
    );

    Edge_capture edge_capture_next(
        .clk(clk),
        .rstn(rstn),
        .sig_in(next),
        .pos_edge(pos_next),
        .neg_edge()
    );

    wire [31: 0]    data;
    wire [31: 0]    count;

    SRT_blk mysrt(
        .clk(clk),
        .rstn(rstn),
        .next(pos_next),
        .prior(pos_prior),
        .start(start),
        .up(up),
        .done(done),
        .index(index),
        .data(data),
        .count(count)
    );

    //wire [ 2: 0] seg_an;
    //wire [ 3: 0] seg_data;
    wire    [31: 0]     output_data;
    assign  output_data = choice ? count : data;

    Segment segment(
        .clk(clk),
        .rst(~rstn),
        .output_data(output_data),
        .output_valid(8'hff),        
        .an(an),
        .seg(seg)
    );

    assign up_sort = up; // 显示是升序还是降序排列
    assign show = choice; // show为1时显示count，为0时显示data

endmodule
