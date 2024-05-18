module i_cache(
    input                       clk,
    input                       resetn,
    input           [31: 0]     raddr,
    input           [ 0: 0]     addr_valid, // 握手信号，CPU发送地址
    input           [ 0: 0]     inst_ready, // 握手信号，CPU接收数据
    input           [31: 0]     inst_mem_rdata, // 与主存的接口

    output	        [31: 0]     rdata,
    output          [ 0: 0]     addr_ready, // 握手信号，ICache接收地址 
    output          [ 0: 0]     inst_valid, // 握手信号，ICache发送指令
    output  reg     [31: 0]     inst_mem_raddr // 与主存的接口
);
    localparam LOOKUP = 2'b00;
    localparam MISS   = 2'b01;
    localparam REFILL = 2'b10;

    reg [1:0] current_state, next_state;

    localparam DATA_WIDTH = 128;
    localparam TAG_WIDTH  = 21;
    localparam ADDR_WIDTH = 7;
    localparam MEM_SIZE   = 128;

	reg r_valid;
    always @(posedge clk) begin
        if(!resetn) begin
            r_valid <= 1'b0;
        end
        else begin
            r_valid <= 1'b1;
        end
    end

    // 后续要使用的各种信号
    // Request Buffer,存储访存的地址，用于后续比较和写操作
    reg     [31: 0]  request_buffer;
    reg     [31: 0]  addr;
    wire    [ 0: 0]  rbuf_we;

    // Return Buffer,移位寄存器，拼接从主存返回的数据成一个Cache行
    wire    [ 0: 0]  retbuf_we;
    reg     [31: 0]  inst_from_retbuf;
    reg     [127:0]  return_buffer;

    // Data Memory 和 TagV Memory
    wire    [ 1: 0]  offset;
    wire    [ADDR_WIDTH-1:0] r_index;
    wire    [ADDR_WIDTH-1:0] w_index;
    wire    [ TAG_WIDTH-1:0] tag;

    // Data Memory
    wire    [ 1: 0]  mem_we;
    wire    [127:0]  r_data1;
    wire    [127:0]  r_data2;
    wire    [127:0]  w_data;
    
    // TagV Memory
    wire    [ 1: 0]  tagv_we;
    wire    [ 1: 0]  tagv_valid;
    wire    [TAG_WIDTH-1:0] w_tag;
    wire    [TAG_WIDTH-1:0] r_tag1;
    wire    [TAG_WIDTH-1:0] r_tag2;

    // Read Mange
    reg     [31: 0]  inst_from_mem;
    wire    [127:0]  rdata_mem;

    // FSM
    wire    [ 1: 0]  hit;
    wire    [ 0: 0]  i_rlast;
    wire    [ 0: 0]  data_from_mem;

    // LRU
    reg     [MEM_SIZE-1:0]  recently_used; // 为每一组维护一个寄存器，表示最近使用的路

    // 各个部件的实现

    // Request buffer
    always @(posedge clk) begin
        if(!resetn) begin
            addr <= 32'h0;
        end
        else if(addr_valid && rbuf_we) begin
            addr <= raddr;
        end
    end

    // Data Memory及TagV Memory
    assign tag      = raddr[31:ADDR_WIDTH+4];
    assign r_index  = raddr[ADDR_WIDTH+3: 4];
    assign offset   = raddr[ 3: 2];
    assign w_index  =  addr[ADDR_WIDTH+3: 4];
    assign w_tag    =  addr[31:ADDR_WIDTH+4];
    assign w_data   = return_buffer;

    Data_Mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_SIZE(MEM_SIZE)
    ) data_mem_1(
        .clk(clk),
        .resetn(resetn),
        .we(mem_we[0]),
        .rindex(r_index),
        .windex(w_index),
        .wdata(w_data),
        .rdata(r_data1)
    );
    Data_Mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_SIZE(MEM_SIZE)
    ) data_mem_2(
        .clk(clk),
        .resetn(resetn),
        .we(mem_we[1]),
        .rindex(r_index),
        .windex(w_index),
        .wdata(w_data),
        .rdata(r_data2)
    );
    
    TagV_Mem #(
        .TAG_WIDTH(TAG_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_SIZE(MEM_SIZE)
    ) tagv_mem_1(
        .clk(clk),
        .resetn(resetn),
        .we(tagv_we[0]),
        .rindex(r_index),
        .windex(w_index),
        .wtag(w_tag),
        .rtag(r_tag1),
        .rvalid(tagv_valid[0])
    );
    TagV_Mem #(
        .TAG_WIDTH(TAG_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_SIZE(MEM_SIZE)
    ) tagv_mem_2(
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
    assign hit[0] = tagv_valid[0] && (r_tag1 == tag);
    assign hit[1] = tagv_valid[1] && (r_tag2 == tag);
    wire   miss   = (hit == 2'b0) && (current_state == LOOKUP);

    // Read Manage
    assign rdata_mem = hit[0] ? r_data1 : (hit[1] ? r_data2 : 128'b0);
    always @(*) begin
        case (offset)
            2'b00: inst_from_mem = rdata_mem[31: 0];
            2'b01: inst_from_mem = rdata_mem[63:32];
            2'b10: inst_from_mem = rdata_mem[95:64];
            default: inst_from_mem = rdata_mem[127:96];
        endcase
    end

    // FSM
    always @(posedge clk) begin
        if(!resetn) begin
            current_state <= LOOKUP;
        end 
        else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case (current_state)
            LOOKUP: next_state = (r_valid && miss) ? MISS : LOOKUP;
            MISS:   next_state = i_rlast ? REFILL : MISS;
            REFILL: next_state = LOOKUP;
            default: next_state = LOOKUP;
        endcase
    end

    wire   inst_mem_raddr_we = (current_state == REFILL) ? 0 : 1;
    always @(posedge clk) begin
        if(!resetn) begin
            inst_mem_raddr <= 0;
        end
        else if(inst_mem_raddr_we) begin
            if(current_state == LOOKUP) begin
                inst_mem_raddr <= {2'b0, raddr[31:4], 2'b0};
            end
            else if(current_state == MISS) begin
                inst_mem_raddr <= inst_mem_raddr + 1;
            end
        end
        else if(next_state == REFILL) begin
            inst_mem_raddr <= 0;
        end
    end

    // 控制信号
    assign  addr_ready  = (current_state == LOOKUP) ? resetn : 0;
    assign  retbuf_we   = (current_state == MISS) ? 1 : 0;
    assign  i_rlast     = (inst_mem_raddr == {2'b00,addr[31:4],2'b11}) && (current_state == MISS);
    assign  inst_valid  = inst_ready && (((current_state == LOOKUP) && !miss) || (current_state == REFILL));
    assign  rbuf_we     = miss;
    assign  tagv_we[0]  = (current_state == REFILL) &&  recently_used[w_index];
    assign  tagv_we[1]  = (current_state == REFILL) && !recently_used[w_index];
    assign  mem_we[0]   = (current_state == REFILL) &&  recently_used[w_index];
    assign  mem_we[1]   = (current_state == REFILL) && !recently_used[w_index];
    assign  data_from_mem = (current_state == LOOKUP) && !miss;

    // LRU
    always @(posedge clk) begin
        if(!resetn)
            recently_used <= 0;
        else if((current_state == LOOKUP) && !miss)
            recently_used[r_index] <= hit[1];
    end

    // Return Buffer
    always @(posedge clk) begin
        if(!resetn || current_state == LOOKUP) begin
            return_buffer <= 0;
        end
        else if(retbuf_we) begin
            return_buffer <= {inst_mem_rdata, return_buffer[127:32]};
        end
    end

    always @(posedge clk) begin
		if(!resetn)
			inst_from_retbuf <= 0;
        else if(retbuf_we && inst_mem_raddr == {2'b0,addr[31:2]})
            inst_from_retbuf <= inst_mem_rdata;
    end

    assign rdata = data_from_mem ? inst_from_mem : inst_from_retbuf;

endmodule