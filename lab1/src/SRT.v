`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/19 21:21:39
// Design Name: 
// Module Name: SRT
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


module SRT(
    input                           clk,
    input                           rstn,
    input                           next,
    input                           prior,
    input                           start,
    input                           up,
    output                          done,
    output  reg     [ 9: 0]         index,
    output  reg     [31: 0]         data,
    output  reg     [31: 0]         count
);
    localparam INIT   = 3'b000;
    localparam READ0  = 3'b001;
    localparam READ1  = 3'b010;
    localparam COMP   = 3'b011;
    localparam WRITE0 = 3'b100;
    localparam WRITE1 = 3'b101;
    localparam DONE   = 3'b110;

    localparam LASTINDEX  = 1023;// LASTINDEX为序列的最后一个元素的下标

    reg     [ 2: 0]     current_state, next_state;
    reg                 swapped;
    reg     [ 9: 0]     lastIndex;
    reg     [ 9: 0]     temp_lastIndex;
    reg     [ 9: 0]     a;
    reg     [31: 0]     d;
    reg     [ 0: 0]     we;
    reg     [31: 0]     src0, src1;
    //reg                 res; // res返回src0，src1比较的结果，表示是否需要交换
    wire                comp_res;
    wire    [31: 0]     spo;

    wire new_cycle = ((current_state == COMP || current_state == WRITE1) && next_state == READ0 && index + 1 == lastIndex);


    // current_state
    always @(posedge clk) begin
        if(!rstn)
            current_state <= INIT;
        else
            current_state <= next_state;
    end

    always @(posedge clk) begin
        if(!rstn)
            temp_lastIndex <= LASTINDEX;
        else if(current_state == COMP && comp_res)
            temp_lastIndex <= index;
        else
            temp_lastIndex <= temp_lastIndex;
    end

    // lastIndex表示上一趟排序最后一次交换的两个元素的下标的最小值

    always @(posedge clk) begin
        if(!rstn)
            lastIndex <= LASTINDEX;
        else if (new_cycle)
            lastIndex <= temp_lastIndex;
        else
            lastIndex <= lastIndex;
    end

    // swapped用于判断一趟排序中是否发生了交换，若swapped = 0，则说明序列已经排好了序
    always @(posedge clk) begin
        if(!rstn)
            swapped = 0;
        else if(current_state == WRITE0)
            swapped = 1;
        else if(index == 0)
            swapped = 0; // 一趟排序完成后swapped清零
    end

    // comp_res表示是否需要交换src0，src1的值
    wire [31: 0]    res;
    ALU myalu(
        .src0(src0),
        .src1(src1),
        .op(4'b0011),
        .res(res)
    );

    reg up_temp;
    always @(posedge clk) begin
        if(current_state == INIT)
            up_temp <= up;
        else
            up_temp <= up;
    end
    assign comp_res = up_temp ? ~res[0] : res[0];

    always @(posedge clk) begin
        if(!rstn || (current_state != DONE && next_state == DONE))
            index <= 0;
        else if(current_state == DONE && prior)
            index <= index - 1; // 在排序完成后按下prior键，index减1以读取前一位数据
        else if(current_state == DONE && next)
            index <= index + 1; // 在排序完成后按下next键，index加1以读取后一位数据
        else if((current_state == COMP || current_state == WRITE1) && next_state == READ0 && index + 1 == lastIndex)
            index <= 0; // 一趟排序完成后，index归零
        else if((current_state == COMP || current_state == WRITE1) && next_state == READ0 && index + 1 < lastIndex)
            index <= index + 1; // 在比较完两个数发现不需要交换或是交换并写回后，index加1以继续往后读取
        else
            index <= index;
    end

    // next_state
    always @(*) begin
        next_state = current_state;
        case (current_state)
            INIT  : next_state = start ? READ0 : INIT; 
            READ0 : next_state = READ1;
            READ1 : next_state = COMP;
            COMP  : next_state = comp_res ? WRITE0 : ((index + 1 < lastIndex || swapped) ? READ0 : DONE);
            WRITE0: next_state = WRITE1;
            WRITE1: next_state = (index + 1 < lastIndex || swapped) ? READ0 : DONE;
            DONE  : next_state = rstn ? DONE : INIT;
        endcase
    end

    // 其他变量

    always @(posedge clk) begin
        if(current_state == READ0)
            src0 <= spo;
        else
            src0 <= src0;
    end
    always @(posedge clk) begin
        if(current_state == READ1)
            src1 <= spo;
        else
            src1 <= src1;
    end

    // we为写使能，有效时写入数据
    always @(*) begin
        if(!rstn)
            we = 0;
        else if(current_state == WRITE0 || current_state == WRITE1)
            we = 1;
        else
            we = 0;
    end

    // 调用存储器模块实现读写操作
    dist_mem_gen_0 my_dist_mem(
        .a(a),
        .d(d),
        .we(we),
        .clk(clk),
        .spo(spo)
    );

    // 读取或写入时的地址
    always @(*) begin
        if(!rstn)
            a = 0;
        else if(current_state == READ0 || current_state == WRITE0 || current_state == DONE)
            a = index;
        else if(current_state == READ1 || current_state == WRITE1)
            a = index + 1;
        else
            a = 0;
    end

    // 写入时的数据
    always @(*) begin
        if(!rstn)
            d = 0;
        else if(current_state == WRITE0)
            d = src1;
        else if(current_state == WRITE1)
            d = src0;
        else
            d = 0;
    end

    // count记录排序时间
    always @(posedge clk) begin
        if(!rstn)
            count <= 0;
        else if(current_state != INIT && current_state != DONE)
            count <= count + 1;
    end

    // done表示排序是否完成（是否正在进行）
    assign done = (current_state == INIT || current_state == DONE) ? 1 : 0;

    // 排序完成后，data显示数据
    always @(*) begin
        if(done)
            data = spo;
        else
            data = 0;
    end

endmodule
