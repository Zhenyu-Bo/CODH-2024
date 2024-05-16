`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/16 20:14:27
// Design Name: 
// Module Name: i_cache
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


module i_cache(
    input                       clk,
    input                       resetn,
    input           [31: 0]     raddr,
    input           [ 0: 0]     addr_valid, // 握手信号，CPU发送地址
    input           [ 0: 0]     inst_ready, // 握手信号，CPU接收数据
    input           [31: 0]     inst_mem_rdata, // 与主存的接口

    output	        [31: 0]     rdata,
    output  reg     [ 0: 0]     addr_ready, // 握手信号，ICache接收地址 
    output          [ 0: 0]     inst_valid, // 握手信号，ICache发送指令
    output  reg     [31: 0]     inst_mem_raddr // 与主存的接口
);
    // 后续要使用的各种信号
    // Request Buffer,存储访存的地址，用于后续比较和写操作
    reg     [31: 0]  request_buffer;
    reg     [ 0: 0]  rbuf_we;
    reg     [31: 0]  addr;

    // Return Buffer,移位寄存器，拼接从主存返回的数据成一个Cache行
    reg     [31: 0]  i_rdata;
    reg     [ 0: 0]  i_rready;
    reg     [ 0: 0]  i_rrvaild;
    wire    [31: 0]  inst_from_retbuf;
    wire    [127:0]  wdata;
    reg     [127:0]  return_buffer;

    // Data Memory
    reg     [ 1: 0]  mem_we;
    wire    [ 7: 0]  r_index;
    wire    [ 7: 0]  w_index;
    wire    [127:0]  r_data1;
    wire    [127:0]  r_data2;
    
    // TagV Memory
    reg     [ 1: 0]  tagv_we;
    reg     [19: 0]  w_tag;
    wire    [19: 0]  r_tag1;
    wire    [19: 0]  r_tag2;
    wire    [ 1: 0]  tagv_valid;

    // Read Mange
    wire    [ 0: 0]  inst_from_mem;
    wire    [127:0] rdata_mem;

    // FSM
    wire    [ 1: 0]  hit;
    reg     [ 0: 0]  r_valid;
    wire    [ 0: 0]  i_rlast;
    wire    [ 1: 0]  way_sel;
    wire    [ 0: 0]  i_rvalid;
    wire    [31: 0]  i_raddr;
    wire    [ 0: 0]  rready;
    wire    [ 0: 0]  LRU_update;
    wire    [ 0: 0]  data_from_mem;

    // 各个部件的实现

    // Request buffer
    always @(posedge clk) begin
        if(!resetn) begin
            addr <= 32'b0;
        end
        else if(addr_valid && rbuf_we) begin
            addr <= raddr;
        end
    end

    // Data Memory及TagV Memory
    assign tag      = raddr[31:12];
    assign r_index  = raddr[11: 4];
    assign offset   = raddr[ 3: 2];
    Data_Mem data_mem_1(
        .clk(clk),
        .resetn(resetn),
        .we(mem_we[0]),
        .rindex(r_index),
        .windex(w_index),
        .wdata(wdata),
        .rdata(r_data1)
    );
    Data_Mem data_mem_2(
        .clk(clk),
        .resetn(resetn),
        .we(mem_we[1]),
        .rindex(r_index),
        .windex(w_index),
        .wdata(wdata),
        .rdata(r_data2)
    );
    TagV_Mem tagv_mem_1(
        .clk(clk),
        .resetn(resetn),
        .we(tagv_we[0]),
        .rindex(r_index),
        .windex(w_index),
        .wtag(w_tag),
        .rtag(r_tag1),
        .rvalid(tagv_valid[0])
    );
    TagV_Mem tagv_mem_2(
        .clk(clk),
        .resetn(resetn),
        .we(tagv_we[1]),
        .rindex(r_index),
        .windex(w_index),
        .wtag(w_tag),
        .rtag(r_tag2),
        .rvalid(tagv_valid[1])
    );

    // Hit
    assign hit[0] = tagv_valid[0] && r_tag1 == tag;
    assign hit[1] = tagv_valid[1] && r_tag2 == tag;
    wire   miss   = ~hit && current_state == LOOKUP;

    localparam LOOKUP = 2'b00;
    localparam MISS   = 2'b01;
    localparam REFILL = 2'b10;

    //reg valid;
    always @(posedge clk) begin
        if(!resetn) begin
            r_valid <= 1'b0;
        end
        else begin
            r_valid <= 1'b1;
        end
    end

    // FSM
    reg [1:0] current_state, next_state;
    always @(posedge clk) begin
        if(!resetn) begin
            current_state <= LOOKUP;
        end 
        else begin
            current_state <= next_state;
        end
    end

    always @(posedge clk) begin
        case (current_state)
            LOOKUP: next_state = r_valid && miss ? MISS : LOOKUP;
            MISS:   next_state = i_rlast ? REFILL : MISS;
            REFILL: next_state = LOOKUP;
            default: next_state = LOOKUP;
        endcase
    end


endmodule
