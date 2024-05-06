module mycpu_top_plus(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire [ 0:0] inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire [ 0:0] data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

// 级间寄存器设置

// IF/ID段
reg [31:0] IF_ID_pc;
reg [31:0] IF_ID_ir;

// ID/EX段
reg [31: 0] ID_EX_pc;
reg [31: 0] ID_EX_ir;
reg [31: 0] ID_EX_imm;
reg [ 4: 0] ID_EX_dest;
reg [11: 0] ID_EX_alu_op;
reg [ 0: 0] ID_EX_src1_is_pc;
reg [ 0: 0] ID_EX_src2_is_imm;
reg [ 0: 0] ID_EX_res_from_mem;
reg [ 0: 0] ID_EX_gr_we;
reg [ 0: 0] ID_EX_mem_we;
reg [ 4: 0] ID_EX_load_op;
reg [ 2: 0] ID_EX_store_op;
reg [ 8: 0] ID_EX_branch_op;
reg [31: 0] ID_EX_br_offs;
reg [31: 0] ID_EX_jirl_offs;
reg [31: 0] ID_EX_rj_value;
reg [31: 0] ID_EX_rkd_value;
reg [63: 0] ID_EX_inst_kind;
reg [ 4: 0] ID_EX_rf_raddr1;
reg [ 4: 0] ID_EX_rf_raddr2;

// EX/MEM段
reg [31: 0] EX_MEM_pc;
reg [31: 0] EX_MEM_ir;
reg [31: 0] EX_MEM_alu_out;
reg [ 4: 0] EX_MEM_dest;
reg [ 4: 0] EX_MEM_res_from_mem;
reg [ 0: 0] EX_MEM_gr_we;
reg [ 0: 0] EX_MEM_mem_we;
reg [ 4: 0] EX_MEM_load_op;
reg [ 2: 0] EX_MEM_store_op;
reg [31: 0] EX_MEM_rkd_value;

// MEM/WB段
reg [31:0] MEM_WB_pc;
reg [31:0] MEM_WB_ir;
reg [31:0] MEM_WB_alu_out;
reg [31:0] MEM_WB_mem_result;
reg [ 4:0] MEM_WB_dest;
reg [ 4:0] MEM_WB_res_from_mem;
reg [ 0:0] MEM_WB_gr_we;
reg [ 0:0] MEM_WB_mem_we;
reg [ 4:0] MEM_WB_load_op;
reg [31:0] MEM_WB_data_sram_rdata;

// 级间寄存器及PC的控制信号
wire pc_we;
wire IF_ID_we;
wire IF_ID_cl;
wire ID_EX_we;
wire ID_EX_cl;

wire [31:0] inst;

reg         reset;
always @(posedge clk) reset <= ~resetn;

reg         valid;
always @(posedge clk) begin
    if (reset) begin
        valid <= 1'b0;
    end
    else begin
        valid <= 1'b1;
    end
end

wire [31:0] seq_pc;
wire [31:0] nextpc;
wire        br_taken;
wire [31:0] br_target;

wire [18:0] alu_op;
wire [4 :0] load_op;
wire [2 :0] store_op;
wire [8 :0] branch_op;
wire        src1_is_pc;
wire        src2_is_imm;
wire        res_from_mem;
wire        dst_is_r1;
wire        gr_we;
wire        mem_we;
wire        src_reg_is_rd;
wire [4: 0] dest;
wire [31:0] rj_value;
wire [31:0] rkd_value;
wire [31:0] imm;
wire [31:0] br_offs;
wire [31:0] jirl_offs;

wire [ 4:0] rd;
wire [ 4:0] rj;
wire [ 4:0] rk;

wire [63:0] inst_kind;


/************************************* IF段 *************************************/
assign seq_pc = pc + 32'h4;
assign nextpc = br_taken ? br_target : seq_pc;

reg [31:0] pc;
always @(posedge clk) begin
    if (reset) begin
        pc <= 32'h1bfffffc;
    end
    else if (pc_we) begin
        pc <= nextpc;
    end
end

assign inst_sram_we    = 1'b0;
assign inst_sram_addr  = pc;
assign inst_sram_wdata = 32'b0;


/************************************* IF/ID段间寄存器 *************************************/
always @(posedge clk) begin
    if (reset || IF_ID_cl) begin
        IF_ID_pc <= 32'h0;
        IF_ID_ir <= 32'h0;
    end
    else if (IF_ID_we) begin
        IF_ID_pc <= pc;
        IF_ID_ir <= inst_sram_rdata;
    end
end


/******************************************* ID段 *******************************************/
assign inst = IF_ID_ir;
wire mem_we_temp;
Decoder_plus cpu_decoder_plus(
    .inst           (inst          ),
    .alu_op         (alu_op        ),
    .imm            (imm           ),
    .src1_is_pc     (src1_is_pc    ),
    .src2_is_imm    (src2_is_imm   ),
    .res_from_mem   (res_from_mem  ),
    //.dst_is_r1      (dst_is_r1     ),
    .gr_we          (gr_we         ),
    .mem_we         (mem_we_temp   ),
    .src_reg_is_rd  (src_reg_is_rd ),
    .dest           (dest          ),
    .rj             (rj            ),
    .rk             (rk            ),
    .rd             (rd            ),
    .br_offs        (br_offs       ),
    .jirl_offs      (jirl_offs     ),
    .load_op        (load_op       ),
    .store_op       (store_op      ),
    .branch_op      (branch_op     ),
    .inst_kind      (inst_kind     )
);

wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;
wire        rf_we   ;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;

assign mem_we = mem_we_temp & valid;

assign rj_value  = rf_rdata1;
assign rkd_value = rf_rdata2;

assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd : rk;

assign rf_we    = gr_we & valid;
//assign rf_waddr = MEM_WB_dest;
//assign rf_wdata = final_result;

regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (MEM_WB_gr_we),
    .waddr  (MEM_WB_dest ),
    .wdata  (final_result)
);


/******************************* ID/EX段间寄存器 *******************************/
always @(posedge clk) begin
    if(reset || ID_EX_cl) begin
        ID_EX_pc            <= 32'h0;
        ID_EX_ir            <= 32'h0;
        ID_EX_imm           <= 32'h0;
        ID_EX_dest          <=  5'h0;
        ID_EX_alu_op        <= 12'h0;
        ID_EX_src1_is_pc    <=  1'h0;
        ID_EX_src2_is_imm   <=  1'h0;
        ID_EX_res_from_mem  <=  1'h0;
        ID_EX_gr_we         <=  1'h0;
        ID_EX_mem_we        <=  1'h0;
        ID_EX_load_op       <=  5'h0;
        ID_EX_store_op      <=  3'h0;
        ID_EX_branch_op     <=  9'h0;
        ID_EX_br_offs       <= 32'h0;
        ID_EX_jirl_offs     <= 32'h0;
        ID_EX_rj_value      <= 32'h0;
        ID_EX_rkd_value     <= 32'h0;
        ID_EX_inst_kind     <= 64'h0;
        ID_EX_rf_raddr1     <= 32'h0;
        ID_EX_rf_raddr2     <= 32'h0;
    end
    else if(ID_EX_we) begin
        ID_EX_pc            <= IF_ID_pc;
        ID_EX_ir            <= IF_ID_ir;
        ID_EX_imm           <= imm;
        ID_EX_dest          <= dest;
        ID_EX_alu_op        <= alu_op;
        ID_EX_src1_is_pc    <= src1_is_pc;
        ID_EX_src2_is_imm   <= src2_is_imm;
        ID_EX_res_from_mem  <= res_from_mem;
        ID_EX_gr_we         <= rf_we;
        ID_EX_mem_we        <= mem_we;
        ID_EX_load_op       <= load_op;
        ID_EX_store_op      <= store_op;
        ID_EX_branch_op     <= branch_op;
        ID_EX_br_offs       <= br_offs;
        ID_EX_jirl_offs     <= jirl_offs;
        ID_EX_rj_value      <= rj_value;
        ID_EX_rkd_value     <= rkd_value;
        ID_EX_inst_kind     <= inst_kind;
        ID_EX_rf_raddr1     <= rf_raddr1;
        ID_EX_rf_raddr2     <= rf_raddr2;
    end
end


/******************************* EX段 *******************************/
/******************************* forwarding unit ***************************************/
reg  [31:0] forwarda;
reg  [31:0] forwardb;

always @(*) begin
    if(EX_MEM_dest == ID_EX_rf_raddr1 && EX_MEM_gr_we && EX_MEM_dest) begin
        forwarda = EX_MEM_alu_out;
    end
    else if(MEM_WB_dest == ID_EX_rf_raddr1 && MEM_WB_gr_we && MEM_WB_dest) begin
        forwarda = final_result;
    end
    else begin
        forwarda = ID_EX_rj_value;
    end
end

always @(*) begin
    if(EX_MEM_dest == ID_EX_rf_raddr2 && EX_MEM_gr_we && EX_MEM_dest) begin
        forwardb = EX_MEM_alu_out;
    end
    else if(MEM_WB_dest == ID_EX_rf_raddr2 && MEM_WB_gr_we && MEM_WB_dest) begin
        forwardb = final_result;
    end
    else begin
        forwardb = ID_EX_rkd_value;
    end
end

wire [31:0] alu_src1   ;
wire [31:0] alu_src2   ;
wire [31:0] alu_result ;

assign alu_src1 = ID_EX_src1_is_pc  ? ID_EX_pc  : forwarda;
assign alu_src2 = ID_EX_src2_is_imm ? ID_EX_imm : forwardb;

alu_plus u_alu_plus(
    .alu_op     (ID_EX_alu_op    ),
    .alu_src1   (alu_src1        ),
    .alu_src2   (alu_src2        ),
    .alu_result (alu_result      )
);

assign rj_eq_rd = (forwarda == forwardb);
assign br_taken = (   ID_EX_branch_op[0]  &&  rj_eq_rd
                   || ID_EX_branch_op[1]  && !rj_eq_rd
                   || ID_EX_branch_op[2]  &&  alu_result[0]
                   || ID_EX_branch_op[3]  &&  alu_result[0]
                   || ID_EX_branch_op[4]  && !alu_result[0]
                   || ID_EX_branch_op[5]  && !alu_result[0]
                   || ID_EX_branch_op[6]
                   || ID_EX_branch_op[7]
                   || ID_EX_branch_op[8]
                  ) && valid;
assign br_target = ID_EX_branch_op[7:0] ? (ID_EX_pc + ID_EX_br_offs) : /*inst_jirl*/  (ID_EX_rj_value + ID_EX_jirl_offs);

/************************************* Hazard Detection Unit *******************************************/
wire fStall;
wire dStall;
wire dFlush;
wire eStall;
wire eFlush;

Hazard u_hazard(
    .ID_raddr1      (rf_raddr1      ),
    .ID_raddr2      (rf_raddr2      ),
    .EX_dest        (ID_EX_dest     ),
    .EX_mem_read    (ID_EX_res_from_mem),
    .EX_rf_we       (ID_EX_gr_we    ),
    .br_taken       (br_taken       ),
    .dStall         (dStall         ),
    .dFlush         (dFlush         ),
    .eStall         (eStall         ),
    .eFlush         (eFlush         ),
    .fStall         (fStall         )
);

assign pc_we    = ~fStall;
assign IF_ID_we = ~dStall;
assign IF_ID_cl = dFlush;
assign ID_EX_we = ~eStall;
assign ID_EX_cl = eFlush;

/************************************* EX/MEM段间寄存器 *******************************************/

always @(posedge clk) begin
    if(reset) begin
        EX_MEM_pc            <= 32'h0;
        EX_MEM_ir            <= 32'h0;
        EX_MEM_alu_out       <= 32'h0;
        EX_MEM_dest          <=  5'h0;
        EX_MEM_res_from_mem  <=  1'h0;
        EX_MEM_gr_we         <=  1'h0;
        EX_MEM_mem_we        <=  1'h0;
        EX_MEM_load_op       <=  5'h0;
        EX_MEM_store_op      <=  3'h0;
        EX_MEM_rkd_value     <= 32'h0;
    end
    else begin
        EX_MEM_pc            <= ID_EX_pc;
        EX_MEM_ir            <= ID_EX_ir;
        EX_MEM_alu_out       <= alu_result;
        EX_MEM_dest          <= ID_EX_dest;
        EX_MEM_res_from_mem  <= ID_EX_res_from_mem;
        EX_MEM_gr_we         <= ID_EX_gr_we;
        EX_MEM_mem_we        <= ID_EX_mem_we;
        EX_MEM_load_op       <= ID_EX_load_op;
        EX_MEM_store_op      <= ID_EX_store_op;
        EX_MEM_rkd_value     <= forwardb;
    end
end


/************************************* MEM段 *************************************/

// 由于ld/st命令需要读取/存储1个字/半字/字节，所以需要根据data_sram_addr来处理mem_result和data_sram_wdata
reg  [31:0] data_sram_wdata_temp;

always @(*) begin
    if(EX_MEM_store_op[2]) begin
        case (data_sram_addr[1:0])
            2'b00: data_sram_wdata_temp = {data_sram_rdata[31: 8], EX_MEM_rkd_value[7:0]};
            2'b01: data_sram_wdata_temp = {data_sram_rdata[31:16], EX_MEM_rkd_value[7:0], data_sram_rdata[7:0]};
            2'b10: data_sram_wdata_temp = {data_sram_rdata[31:24], EX_MEM_rkd_value[7:0], data_sram_rdata[15:0]};
            2'b11: data_sram_wdata_temp = {EX_MEM_rkd_value[7:0], data_sram_rdata[23:0]};
        endcase
    end
    else if(EX_MEM_store_op[1])
        data_sram_wdata_temp = data_sram_addr[1] ? {EX_MEM_rkd_value[15:0], data_sram_rdata[15:0]}
                                                 : {data_sram_rdata[31:16], EX_MEM_rkd_value[15:0]};
    else
        data_sram_wdata_temp = EX_MEM_rkd_value;
end

assign data_sram_wdata = data_sram_wdata_temp;
assign data_sram_we    = EX_MEM_mem_we && valid;
assign data_sram_addr  = EX_MEM_alu_out;
//assign data_sram_en    = 1'b1;

wire [31:0] mem_result;
reg  [31:0] data_sram_rdata_temp;
always @(*) begin
    case (EX_MEM_alu_out[1:0])
        2'b00: data_sram_rdata_temp = data_sram_rdata;
        2'b01: data_sram_rdata_temp = {8'b0,  data_sram_rdata[31: 8]};
        2'b10: data_sram_rdata_temp = {16'b0, data_sram_rdata[31:16]};
        2'b11: data_sram_rdata_temp = {24'b0, data_sram_rdata[31:24]};
    endcase
end

assign mem_result = EX_MEM_load_op[0] ?                                 data_sram_rdata_temp        :
                    EX_MEM_load_op[1] ? {{16{data_sram_rdata_temp[15]}},data_sram_rdata_temp[15:0]} :
                    EX_MEM_load_op[2] ? {{24{data_sram_rdata_temp[7]}} ,data_sram_rdata_temp[ 7:0]} :
                    EX_MEM_load_op[3] ? { 16'b0                        ,data_sram_rdata_temp[15:0]} :
                    EX_MEM_load_op[4] ? { 24'b0                        ,data_sram_rdata_temp[ 7:0]} :
                    32'h0                                                                           ;


/************************************* MEM/WB段 *************************************/
always @(posedge clk) begin
    if(reset) begin
        MEM_WB_pc            <= 32'h0;
        MEM_WB_ir            <= 32'h0;
        MEM_WB_alu_out       <= 32'h0;
        MEM_WB_dest          <=  5'h0;
        MEM_WB_res_from_mem  <=  1'h0;
        MEM_WB_gr_we         <=  1'h0;
        MEM_WB_mem_we        <=  1'h0;
        MEM_WB_load_op       <=  5'h0;
        MEM_WB_data_sram_rdata <= 32'h0;
        MEM_WB_mem_result    <= 32'h0;
    end
    else begin
        MEM_WB_pc            <= EX_MEM_pc;
        MEM_WB_ir            <= EX_MEM_ir;
        MEM_WB_alu_out       <= EX_MEM_alu_out;
        MEM_WB_dest          <= EX_MEM_dest;
        MEM_WB_res_from_mem  <= EX_MEM_res_from_mem;
        MEM_WB_gr_we         <= EX_MEM_gr_we;
        MEM_WB_mem_we        <= EX_MEM_mem_we;
        MEM_WB_load_op       <= EX_MEM_load_op;
        MEM_WB_data_sram_rdata <= data_sram_rdata;
        MEM_WB_mem_result    <= mem_result;
    end
end

/************************************* WB段 *************************************/
wire [31:0] final_result;
assign final_result = MEM_WB_res_from_mem ? MEM_WB_mem_result : MEM_WB_alu_out;

// debug info generate
assign debug_wb_pc       = MEM_WB_pc;
assign debug_wb_rf_we    = {4{MEM_WB_gr_we}};
assign debug_wb_rf_wnum  = MEM_WB_dest;
assign debug_wb_rf_wdata = final_result;

endmodule