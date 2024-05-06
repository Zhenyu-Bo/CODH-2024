`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/16 18:19:04
// Design Name: 
// Module Name: mycpu_top_plus
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



module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_en,
    output wire [ 3:0] inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_en,
    output wire [ 3:0] data_sram_we,
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
//reg [31: 0] ID_EX_alu_src1;
//reg [31: 0] ID_EX_alu_src2;
reg [31: 0] ID_EX_imm;
reg [ 4: 0] ID_EX_rj;
reg [ 4: 0] ID_EX_rk;
reg [ 4: 0] ID_EX_rd;
reg [ 4: 0] ID_EX_dest;
reg [11: 0] ID_EX_alu_op;
reg [ 0: 0] ID_EX_src1_is_pc;
reg [ 0: 0] ID_EX_src2_is_imm;
reg [ 0: 0] ID_EX_res_from_mem;
reg [ 0: 0] ID_EX_gr_we;
reg [ 0: 0] ID_EX_mem_we;
reg [ 0: 0] ID_EX_src_reg_is_rd;
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
reg [31: 0] EX_MEM_alu_src2;
reg [ 0: 0] EX_MEM_rj;
reg [ 0: 0] EX_MEM_rk;
reg [ 0: 0] EX_MEM_rd;
reg [ 4: 0] EX_MEM_dest;
reg [ 4: 0] EX_MEM_res_from_mem;
reg [ 0: 0] EX_MEM_gr_we;
reg [ 0: 0] EX_MEM_mem_we;
reg [ 0: 0] EX_MEM_load_op;
reg [ 0: 0] EX_MEM_store_op;
reg [ 8: 0] EX_MEM_branch_op;
reg [31: 0] EX_MEM_br_offs;
reg [31: 0] EX_MEM_jirl_offs;
reg [31: 0] EX_MEM_rj_value;
reg [31: 0] EX_MEM_rkd_value;
reg [63: 0] EX_MEM_inst_kind;
reg [ 4: 0] EX_MEM_rf_raddr1;
reg [ 4: 0] EX_MEM_rf_raddr2;

// MEM/WB段
reg [31:0] MEM_WB_pc;
reg [31:0] MEM_WB_ir;
reg [31:0] MEM_WB_alu_out;
reg [31:0] MEM_WB_mem_result;
reg [ 0:0] MEM_WB_rj;
reg [ 0:0] MEM_WB_rk;
reg [ 0:0] MEM_WB_rd;
reg [ 4:0] MEM_WB_dest;
reg [ 4:0] MEM_WB_res_from_mem;
reg [ 0:0] MEM_WB_gr_we;
reg [ 0:0] MEM_WB_mem_we;
reg [ 4:0] MEM_WB_load_op;
reg [ 2:0] MEM_WB_store_op;
reg [ 8:0] MEM_WB_branch_op;
reg [31:0] MEM_WB_br_offs;
reg [31:0] MEM_WB_jirl_offs;
reg [31:0] MEM_WB_data_sram_rdata;
reg [63:0] MEM_WB_inst_kind;
reg [ 4:0] MEM_WB_rf_raddr1;
reg [ 4:0] MEM_WB_rf_raddr2;

// 级间寄存器及PC的控制信号
wire pc_we;
wire IF_ID_we;
wire IF_ID_cl;
wire ID_EX_we;
wire ID_EX_cl;

wire        inst_add_w;
wire        inst_sub_w;
wire        inst_slt;
wire        inst_sltu;
wire        inst_nor;
wire        inst_and;
wire        inst_or;
wire        inst_xor;
wire        inst_sll_w;
wire        inst_srl_w;
wire        inst_sra_w;
wire        inst_slli_w;
wire        inst_srli_w;
wire        inst_srai_w;
wire        inst_addi_w;
wire        inst_slti;
wire        inst_sltui;
wire        inst_andi;
wire        inst_ori;
wire        inst_xori;
wire        inst_ld_w;
wire        inst_ld_h;
wire        inst_ld_b;
wire        inst_ld_hu;
wire        inst_ld_bu;
wire        inst_st_w;
wire        inst_st_h;
wire        inst_st_b;
wire        inst_jirl;
wire        inst_b;
wire        inst_bl;
wire        inst_beq;
wire        inst_bne;
wire        inst_blt;
wire        inst_bge;
wire        inst_bltu;
wire        inst_bgeu;
wire        inst_lu12i_w;
wire        inst_pcaddu12i;

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
//wire [31:0] inst;
//wire [31:0] pc;

wire [11:0] alu_op;
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


/****** IF段 ******/
assign seq_pc = pc + 32'h4;
assign nextpc = br_taken ? br_target : seq_pc;

wire [31: 0] pc;
PC mypc(
    .clk     (clk     ),
    .rst     (reset   ),
    .PCWrite (pc_we   ),
    .npc     (nextpc  ),
    .pc      (pc      )
);
/*reg [31:0] pc;
always @(posedge clk) begin
    if (reset) begin
        pc <= 32'h1c000000;
    end
    else if (pc_we) begin
        pc <= nextpc;
    end
end*/

assign inst_sram_we    = 4'b0;
assign inst_sram_addr  = pc;
assign inst_sram_wdata = 32'b0;
assign inst_sram_en    = 1'b1;
//assign inst            = inst_sram_rdata;


/****** IF/ID段间寄存器 ******/
reg IR_we;
always @(posedge clk) begin
    if (reset || IF_ID_cl) begin
        IR_we    <= 0;
        IF_ID_pc <= 32'h0;
        IF_ID_ir <= 32'h0;
    end
    else if (IF_ID_we) begin
        IR_we    <= 1;
        IF_ID_pc <= pc;
        IF_ID_ir <= inst_sram_rdata;
    end
end


/****** ID段 ******/
assign inst = IR_we ? inst_sram_rdata : 0;
Decoder cpu_decoder(
    .inst           (inst          ),
    .alu_op         (alu_op        ),
    .imm            (imm           ),
    .src1_is_pc     (src1_is_pc    ),
    .src2_is_imm    (src2_is_imm   ),
    .res_from_mem   (res_from_mem  ),
    //.dst_is_r1      (dst_is_r1     ),
    .gr_we          (gr_we         ),
    .mem_we         (mem_we        ),
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

assign rj_value  = rf_rdata1;
assign rkd_value = rf_rdata2;

assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd : rk;

assign rf_we    = gr_we;
assign rf_waddr = MEM_WB_dest;
assign rf_wdata = final_result;

regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (MEM_WB_gr_we),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
);


/****** ID/EX段间寄存器 ******/
always @(posedge clk) begin
    if(reset || ID_EX_cl) begin
        ID_EX_pc            <= 32'h0;
        ID_EX_ir            <= 32'h0;
        ID_EX_imm           <= 32'h0;
        ID_EX_rj            <=  5'h0;
        ID_EX_rk            <=  5'h0;
        ID_EX_rd            <=  5'h0;
        ID_EX_dest          <=  5'h0;
        ID_EX_alu_op        <= 12'h0;
        ID_EX_src1_is_pc    <=  1'h0;
        ID_EX_src2_is_imm   <=  1'h0;
        ID_EX_res_from_mem  <=  1'h0;
        ID_EX_gr_we         <=  1'h0;
        ID_EX_mem_we        <=  1'h0;
        ID_EX_src_reg_is_rd <=  1'h0;
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
        ID_EX_ir            <= inst;
        ID_EX_imm           <= imm;
        ID_EX_rj            <= rj;
        ID_EX_rk            <= rk;
        ID_EX_rd            <= rd;
        ID_EX_dest          <= dest;
        ID_EX_alu_op        <= alu_op;
        ID_EX_src1_is_pc    <= src1_is_pc;
        ID_EX_src2_is_imm   <= src2_is_imm;
        ID_EX_res_from_mem  <= res_from_mem;
        ID_EX_gr_we         <= gr_we;
        ID_EX_mem_we        <= mem_we;
        ID_EX_src_reg_is_rd <= src_reg_is_rd;
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


/****** EX段 ******/
assign inst_add_w   = ID_EX_inst_kind[0];
assign inst_addi_w  = ID_EX_inst_kind[1];
assign inst_lu12i_w = ID_EX_inst_kind[2];
assign inst_sub_w   = ID_EX_inst_kind[3];
assign inst_pcaddu12i = ID_EX_inst_kind[4];
assign inst_slt     = ID_EX_inst_kind[5];
assign inst_sltu    = ID_EX_inst_kind[6];
assign inst_slti    = ID_EX_inst_kind[7];
assign inst_sltui   = ID_EX_inst_kind[8];
assign inst_and     = ID_EX_inst_kind[9];
assign inst_or      = ID_EX_inst_kind[10];
assign inst_nor     = ID_EX_inst_kind[11];
assign inst_xor     = ID_EX_inst_kind[12];
assign inst_andi    = ID_EX_inst_kind[13];
assign inst_ori     = ID_EX_inst_kind[14];
assign inst_xori    = ID_EX_inst_kind[15];
assign inst_slli_w  = ID_EX_inst_kind[16];
assign inst_srli_w  = ID_EX_inst_kind[17];
assign inst_srai_w  = ID_EX_inst_kind[18];
assign inst_sll_w   = ID_EX_inst_kind[19];
assign inst_srl_w   = ID_EX_inst_kind[20];
assign inst_sra_w   = ID_EX_inst_kind[21];
assign inst_ld_w    = ID_EX_inst_kind[22];
assign inst_ld_h    = ID_EX_inst_kind[23];
assign inst_ld_b    = ID_EX_inst_kind[24];
assign inst_ld_hu   = ID_EX_inst_kind[25];
assign inst_ld_bu   = ID_EX_inst_kind[26];
assign inst_st_w    = ID_EX_inst_kind[27];
assign inst_st_h    = ID_EX_inst_kind[28];
assign inst_st_b    = ID_EX_inst_kind[29];
assign inst_jirl    = ID_EX_inst_kind[30];
assign inst_bl      = ID_EX_inst_kind[31];
assign inst_b       = ID_EX_inst_kind[32];
assign inst_beq     = ID_EX_inst_kind[33];
assign inst_bne     = ID_EX_inst_kind[34];
assign inst_blt     = ID_EX_inst_kind[35];
assign inst_bltu    = ID_EX_inst_kind[36];
assign inst_bge     = ID_EX_inst_kind[37];
assign inst_bgeu    = ID_EX_inst_kind[38];


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

wire [31:0] alu_src1   ;
wire [31:0] alu_src2   ;
wire [31:0] alu_result ;

/*******************************forwarding unit***************************************/
reg [31:0] forwarda;
reg [31:0] forwardb;
wire forwarda_en1;
wire forwarda_en2;
wire forwardb_en1;
wire forwardb_en2;


assign forwarda_en1 = EX_MEM_gr_we & (!inst_lu12i_w & !inst_pcaddu12i & !inst_b & !inst_bl);
assign forwarda_en2 = MEM_WB_gr_we & (!inst_lu12i_w & !inst_pcaddu12i & !inst_b & !inst_bl);

assign forwardb_en1 = EX_MEM_gr_we 
                    & (inst_add_w      | inst_sub_w       | inst_slt     | inst_sltu        | inst_nor 
                    |  inst_and        | inst_or          | inst_xor     | inst_sll_w 
                    |  inst_srl_w      | inst_sra_w       | inst_beq     | inst_bne         | inst_blt 
                    |  inst_bge        | inst_bltu        | inst_bgeu);
assign forwardb_en2 = MEM_WB_gr_we 
                    & (inst_add_w      | inst_sub_w       | inst_slt     | inst_sltu        | inst_nor 
                    |  inst_and        | inst_or          | inst_xor     | inst_sll_w 
                    |  inst_srl_w      | inst_sra_w       | inst_beq     | inst_bne         | inst_blt 
                    |  inst_bge        | inst_bltu        | inst_bgeu);

always @(*) begin
    if(EX_MEM_dest == ID_EX_rf_raddr1 && forwarda_en1 && EX_MEM_dest)
        forwarda = EX_MEM_alu_out;
    else if(MEM_WB_dest == ID_EX_rf_raddr1 && forwarda_en2 && MEM_WB_dest)
        forwarda = final_result;
    else
        forwarda = ID_EX_rj_value;
end

always @(*) begin
    if(EX_MEM_dest == ID_EX_rf_raddr2 && forwardb_en1)
        forwardb = EX_MEM_alu_out;
    else if(MEM_WB_dest == ID_EX_rf_raddr2 && forwardb_en2)
        forwardb = final_result;
    else
        forwardb = ID_EX_rkd_value;
end

assign alu_src1 = ID_EX_src1_is_pc  ? ID_EX_pc  : forwarda;
assign alu_src2 = ID_EX_src2_is_imm ? ID_EX_imm : forwardb;

alu u_alu(
    .alu_op     (ID_EX_alu_op    ),
    .alu_src1   (alu_src1        ),
    .alu_src2   (alu_src2        ),
    .alu_result (alu_result      )
);

/*************************************Hazard Detection Unit*******************************************/
wire ld_hazard_rj_en;
wire ld_hazard_rk_en;
wire ld_hazard_rd_en;
wire br_hazard_en;
wire fstall;
wire dstall;
wire dflush;
wire eflush;

assign ld_hazard_rj_en = MEM_WB_res_from_mem
                       & ( !inst_lu12i_w & !inst_pcaddu12i & !inst_b & !inst_bl);

assign ld_hazard_rk_en = MEM_WB_res_from_mem
                       & ( inst_add_w  | inst_sub_w   | inst_slt     | inst_sltu        | inst_nor     | inst_and 
                         | inst_or     | inst_xor     | inst_sll_w   | inst_srl_w   | inst_sra_w);

assign ld_hazard_rd_en = MEM_WB_res_from_mem
                       & ( inst_beq    | inst_bne     | inst_blt     | inst_bge         | inst_bltu    | inst_bgeu
                         | inst_st_w   | inst_st_h    | inst_st_b);

assign br_hazard_en = br_taken;

assign hazard_r = ((ld_hazard_rj_en && (MEM_WB_dest == ID_EX_rf_raddr1))
                || (ld_hazard_rk_en && (MEM_WB_dest == ID_EX_rf_raddr2))
                || (ld_hazard_rd_en && (MEM_WB_dest == ID_EX_rf_raddr2)));

assign fstall = hazard_r;
assign dstall = hazard_r;
assign eflush = br_hazard_en;
assign dflush = br_hazard_en | hazard_r;

assign pc_we    = ~fstall;
assign IF_ID_we  = ~dstall;
assign IF_ID_cl  = dflush;
assign ID_EX_we  = 1;
assign ID_EX_cl  = eflush;


/****** EX/MEM段间寄存器 ******/
always @(posedge clk) begin
    if(reset) begin
        EX_MEM_pc            <= 32'h0;
        EX_MEM_ir            <= 32'h0;
        EX_MEM_alu_out       <= 32'h0;
        EX_MEM_alu_src2      <= 32'h0;
        EX_MEM_rj            <=  5'h0;
        EX_MEM_rk            <=  5'h0;
        EX_MEM_rd            <=  5'h0;
        EX_MEM_dest          <=  5'h0;
        EX_MEM_res_from_mem  <=  1'h0;
        EX_MEM_gr_we         <=  1'h0;
        EX_MEM_mem_we        <=  1'h0;
        EX_MEM_load_op       <=  5'h0;
        EX_MEM_store_op      <=  3'h0;
        EX_MEM_branch_op     <=  9'h0;
        EX_MEM_br_offs       <= 32'h0;
        EX_MEM_jirl_offs     <= 32'h0;
        EX_MEM_rj_value      <= 32'h0;
        EX_MEM_rkd_value     <= 32'h0;
        EX_MEM_inst_kind     <= 64'h0;
    end
    else begin
        EX_MEM_pc            <= ID_EX_pc;
        EX_MEM_ir            <= ID_EX_ir;
        EX_MEM_alu_out       <= alu_result;
        EX_MEM_alu_src2      <= alu_src2;
        EX_MEM_rj            <= ID_EX_rj;
        EX_MEM_rk            <= ID_EX_rk;
        EX_MEM_rd            <= ID_EX_rd;
        EX_MEM_dest          <= ID_EX_dest;
        EX_MEM_res_from_mem  <= ID_EX_res_from_mem;
        EX_MEM_gr_we         <= ID_EX_gr_we;
        EX_MEM_mem_we        <= ID_EX_mem_we;
        EX_MEM_load_op       <= ID_EX_load_op;
        EX_MEM_store_op      <= ID_EX_store_op;
        EX_MEM_branch_op     <= ID_EX_branch_op;
        EX_MEM_br_offs       <= ID_EX_br_offs;
        EX_MEM_jirl_offs     <= ID_EX_jirl_offs;
        EX_MEM_rj_value      <= ID_EX_rj_value;
        EX_MEM_rkd_value     <= ID_EX_rkd_value;
        EX_MEM_inst_kind     <= ID_EX_inst_kind;
    end
end


/****** MEM段 ******/

// 由于ld/st命令需要读取/存储1个字/半字/字节，所以需要根据data_sram_addr来处理mem_result和data_sram_wdata
reg  [31:0] data_sram_wdata_temp;

always @(*) begin
    if(store_op[2]) begin
        case (data_sram_addr[1:0])
            2'b00: data_sram_wdata_temp = {data_sram_rdata[31: 8], EX_MEM_rkd_value[7:0]};
            2'b01: data_sram_wdata_temp = {data_sram_rdata[31:16], EX_MEM_rkd_value[7:0], data_sram_rdata[7:0]};
            2'b10: data_sram_wdata_temp = {data_sram_rdata[31:24], EX_MEM_rkd_value[7:0], data_sram_rdata[15:0]};
            2'b11: data_sram_wdata_temp = {EX_MEM_rkd_value[7:0], data_sram_rdata[23:0]};
        endcase
    end
    else if(store_op[1])
        data_sram_wdata_temp = data_sram_addr[1] ? {EX_MEM_rkd_value[15:0], data_sram_rdata[15:0]}
                                                 : {data_sram_rdata[31:16], EX_MEM_rkd_value[15:0]};
    else
        data_sram_wdata_temp = EX_MEM_rkd_value;
end

assign data_sram_wdata = data_sram_wdata_temp;
assign data_sram_we    = EX_MEM_mem_we ? 4'hf : 4'h0;
assign data_sram_addr  = EX_MEM_alu_out;
assign data_sram_en    = 1'b1;


/****** MEM/WB段 ******/
always @(posedge clk) begin
    if(reset) begin
        MEM_WB_pc            <= 32'h0;
        MEM_WB_ir            <= 32'h0;
        MEM_WB_alu_out       <= 32'h0;
        //MEM_WB_mem_result    <= 32'h0;
        MEM_WB_rj            <=  5'h0;
        MEM_WB_rk            <=  5'h0;
        MEM_WB_rd            <=  5'h0;
        MEM_WB_dest          <=  5'h0;
        MEM_WB_res_from_mem  <=  1'h0;
        MEM_WB_gr_we         <=  1'h0;
        MEM_WB_mem_we        <=  1'h0;
        MEM_WB_load_op       <=  5'h0;
        MEM_WB_store_op      <=  3'h0;
        MEM_WB_branch_op     <=  9'h0;
        MEM_WB_br_offs       <= 32'h0;
        MEM_WB_jirl_offs     <= 32'h0;
        MEM_WB_data_sram_rdata <= 32'h0;
        MEM_WB_inst_kind     <= 64'h0; 
    end
    else begin
        MEM_WB_pc            <= EX_MEM_pc;
        MEM_WB_ir            <= EX_MEM_ir;
        MEM_WB_alu_out       <= EX_MEM_alu_out;
        //MEM_WB_mem_result    <= mem_result;
        MEM_WB_rj            <= EX_MEM_rj;
        MEM_WB_rk            <= EX_MEM_rk;
        MEM_WB_rd            <= EX_MEM_rd;
        MEM_WB_dest          <= EX_MEM_dest;
        MEM_WB_res_from_mem  <= EX_MEM_res_from_mem;
        MEM_WB_gr_we         <= EX_MEM_gr_we;
        MEM_WB_mem_we        <= EX_MEM_mem_we;
        MEM_WB_load_op       <= EX_MEM_load_op;
        MEM_WB_store_op      <= EX_MEM_store_op;
        MEM_WB_branch_op     <= EX_MEM_branch_op;
        MEM_WB_br_offs       <= EX_MEM_br_offs;
        MEM_WB_jirl_offs     <= EX_MEM_jirl_offs;
        MEM_WB_data_sram_rdata <= data_sram_rdata;
        MEM_WB_inst_kind     <= EX_MEM_inst_kind;
    end
end

/****** WB段 ******/
wire [31:0] mem_result;
wire [31:0] final_result;
reg  [31:0] data_sram_rdata_temp;

always @(*) begin
    case (MEM_WB_alu_out[1:0])
        2'b00: data_sram_rdata_temp = data_sram_rdata;
        2'b01: data_sram_rdata_temp = {8'b0,  data_sram_rdata[31: 8]};
        2'b10: data_sram_rdata_temp = {16'b0, data_sram_rdata[31:16]};
        2'b11: data_sram_rdata_temp = {24'b0, data_sram_rdata[31:24]};
    endcase
end

assign mem_result = MEM_WB_load_op[0] ?                                 data_sram_rdata_temp        :
                    MEM_WB_load_op[1] ? {{16{data_sram_rdata_temp[15]}},data_sram_rdata_temp[15:0]} :
                    MEM_WB_load_op[2] ? {{24{data_sram_rdata_temp[7]}} ,data_sram_rdata_temp[ 7:0]} :
                    MEM_WB_load_op[3] ? { 16'b0                        ,data_sram_rdata_temp[15:0]} :
                  /*inst_ld_bu*/{24'b0, data_sram_rdata_temp[ 7:0]}                                 ;

assign final_result = MEM_WB_res_from_mem ? mem_result : MEM_WB_alu_out;


// debug info generate
assign debug_wb_pc       = MEM_WB_pc;
assign debug_wb_rf_we    = {4{MEM_WB_gr_we}};
assign debug_wb_rf_wnum  = MEM_WB_dest;
assign debug_wb_rf_wdata = final_result;

endmodule
