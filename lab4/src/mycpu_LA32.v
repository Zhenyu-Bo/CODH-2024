module mycpu_LA32 (
    input           clk,
    input           rstn,

    output          inst_sram_we,
    output  [31:0]  inst_sram_addr,
    output  [31:0]  inst_sram_wdata,
    input   [31:0]  inst_sram_rdata,

    output          data_sram_we_out,
    output  [31:0]  data_sram_addr,
    output  [31:0]  data_sram_wdata,
    input   [31:0]  data_sram_rdata,

    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

reg         valid;
always @(posedge clk) begin
    if (!rstn) begin
        valid <= 1'b0;
    end
    else begin
        valid <= 1'b1;
    end
end

reg     [31:0]      pc;
wire    [31:0]      seqpc;
wire    [31:0]      nextpc;

wire    [31:0]      inst;

wire    [4:0]       rk;
wire    [4:0]       rj;
wire    [4:0]       rd;
wire    [11:0]      i_12;
wire    [19:0]      i_20;
wire    [25:0]      offs_26;
wire    [15:0]      offs_16;
wire    [31:0]      jirl_offs;
wire    [31:0]      br_offs  ;

wire    [5:0]       op_31_26;
wire    [3:0]       op_25_22;
wire    [1:0]       op_21_20;
wire    [4:0]       op_19_15;
wire    [63:0]      op_31_26_d;
wire    [16:0]      op_25_22_d;
wire    [4:0]       op_21_20_d;
wire    [32:0]      op_19_15_d;

wire inst_add_w;
wire inst_sub_w;
wire inst_slt;
wire inst_sltu;
wire inst_nor;
wire inst_and;
wire inst_or;
wire inst_xor;
wire inst_slli_w;
wire inst_srli_w;
wire inst_srai_w;
wire inst_addi_w;
wire inst_ld_w;
wire inst_st_w;
wire inst_jirl;
wire inst_b;
wire inst_bl;
wire inst_beq;
wire inst_bne;
wire inst_lu12i_w;
wire inst_pcaddu12i;
wire inst_mul_w;
wire inst_slti;
wire inst_sltui;
wire inst_andi;
wire inst_ori;
wire inst_xori;
wire inst_sll_w;
wire inst_srl_w;
wire inst_sra_w;
wire inst_st_h;
wire inst_st_b;
wire inst_ld_h;
wire inst_ld_b;
wire inst_ld_hu;
wire inst_ld_bu;
wire inst_blt;
wire inst_bge;
wire inst_bltu;
wire inst_bgeu;
    
wire alu_src1_sel;
wire alu_src2_sel;
wire [12:0] alu_op;       
wire rf_we;        
wire rf_raddr2_sel;
wire src2_is_4;
wire need_offs_26;
wire need_ui_12;
wire imm_sel;      
wire wb_sel;       
wire dst_is_r1;
wire [4:0] wb_dest;

wire [4:0] rf_raddr1;
wire [4:0] rf_raddr2;

wire [31:0] br_target;
wire rj_eq_rd;
wire rj_lt_rd;
wire rj_ltu_rd;
wire rj_ge_rd;
wire rj_geu_rd;
wire br_en;

wire [31:0] ui_12_to_32;
wire [31:0] si_12_to_32;
wire [31:0] si_20_to_32;
wire [31:0] imm;

wire [31:0] alu_src1;     
wire [31:0] alu_src2; 
wire [31:0] alu_result;

reg  [31:0] ld_data;
reg  [31:0] st_data;
wire [31:0] wb_data;
wire [31:0] rf_rdata1;
wire [31:0] rf_rdata2;

//Registers For Pipeline
reg [31:0] IR;//IR
reg [31:0] IFID_pc;

reg [31:0] IDEX_inst;
reg IDEX_inst_add_w;
reg IDEX_inst_sub_w;
reg IDEX_inst_slt;
reg IDEX_inst_sltu;
reg IDEX_inst_nor;
reg IDEX_inst_and;
reg IDEX_inst_or;
reg IDEX_inst_xor;
reg IDEX_inst_slli_w;
reg IDEX_inst_srli_w;
reg IDEX_inst_srai_w;
reg IDEX_inst_addi_w;
reg IDEX_inst_ld_w;
reg IDEX_inst_st_w;
reg IDEX_inst_jirl;
reg IDEX_inst_b;
reg IDEX_inst_bl;
reg IDEX_inst_beq;
reg IDEX_inst_bne;
reg IDEX_inst_lu12i_w;
reg IDEX_inst_pcaddu12i;
reg IDEX_inst_mul_w;
reg IDEX_inst_slti;
reg IDEX_inst_sltui;
reg IDEX_inst_andi;
reg IDEX_inst_ori;
reg IDEX_inst_xori;
reg IDEX_inst_sll_w;
reg IDEX_inst_srl_w;
reg IDEX_inst_sra_w;
reg IDEX_inst_st_h;
reg IDEX_inst_st_b;
reg IDEX_inst_ld_h;
reg IDEX_inst_ld_b;
reg IDEX_inst_ld_hu;
reg IDEX_inst_ld_bu;
reg IDEX_inst_blt;
reg IDEX_inst_bge;
reg IDEX_inst_bltu;
reg IDEX_inst_bgeu;
reg [31:0] IDEX_br_offs;
reg [31:0] IDEX_jirl_offs;
reg [31:0] IDEX_pc;
reg [31:0] IDEX_rf_raddr2;
reg [31:0] IDEX_rf_raddr1;
reg [31:0] IDEX_rf_rdata1;
reg [31:0] IDEX_rf_rdata2;
reg [31:0] IDEX_imm;
reg [4:0]  IDEX_wb_dest;
reg ctr_EX_alu_src1_sel;
reg ctr_EX_alu_src2_sel;
reg [12:0] ctr_EX_alu_op;
reg ctr_MEM_data_sram_we;
reg ctr_WB_rf_we;
reg ctr_WB_wb_sel;

reg [31:0] EXMEM_inst;
reg [31:0] EXMEM_pc;
reg EXMEM_inst_st_w;
reg EXMEM_inst_st_h;
reg EXMEM_inst_st_b;
reg EXMEM_inst_ld_w;
reg EXMEM_inst_ld_h;
reg EXMEM_inst_ld_b;
reg EXMEM_inst_ld_hu;
reg EXMEM_inst_ld_bu;
reg [31:0] EXMEM_alu_result;
reg [31:0] EXMEM_rf_rdata2;
reg [4:0]  EXMEM_wb_dest;
reg ctrm_MEM_data_sram_we;
reg ctrm_WB_rf_we;
reg ctrm_WB_wb_sel;

reg [31:0] MEMWB_inst;
reg [31:0] MEMWB_pc;
reg MEMWB_inst_ld_w;
reg MEMWB_inst_ld_h;
reg MEMWB_inst_ld_b;
reg MEMWB_inst_ld_hu;
reg MEMWB_inst_ld_bu;
reg [31:0] MEMWB_rf_rdata2;
reg [31:0] MEMWB_alu_result;
reg [31:0] MEMWB_data_sram_rdata;
reg [4:0]  MEMWB_wb_dest;
reg ctrw_WB_rf_we;
reg ctrw_WB_wb_sel;

//流水线产生的控制信号
wire pc_we;
wire IFID_we;
wire IFID_cl;
wire IDEX_we;
wire IDEX_cl;

//forwarding unit
reg  [31:0] forward1;//转发合并后的信号
reg  [31:0] forward2;
reg  [1:0] forward1_sel;//00：不转发，01：转发EXMEM_alu_result，10：转发MEMWB_alu_result
reg  [1:0] forward2_sel;//00：不转发，01：转发EXMEM_alu_result，10：转发MEMWB_alu_result
wire forward1_en1;
wire forward1_en2;
wire forward2_en1;
wire forward2_en2;

//hazard detection unit
wire ld_hazard_rj_en;
wire ld_hazard_rk_en;
wire ld_hazard_rd_en;
wire br_hazard_en;
reg fStall;
reg dStall;
reg dFlush;
reg eFlush;

/*//debug端口赋值
assign npc = nextpc;
assign pc_out = pc;
assign ir = inst_sram_rdata;
assign pc_id = IFID_pc;
assign ir_id = IR;
assign pc_ex = IDEX_pc;
assign ir_ex = IDEX_inst;
assign rrd1 = rf_rdata1;
assign rrd2 = rf_raddr2;
assign imm_out = imm;
assign ir_mem = EXMEM_inst;
assign res = EXMEM_alu_result;
assign dwd = wb_data;
assign ir_wb = MEMWB_inst;
assign drd = data_sram_rdata;
assign res_wb = MEMWB_alu_result;
assign rwd = wb_data;*/

/*********************  IF  **********************/
assign inst_sram_we     = 1'b0;
assign inst_sram_addr   = pc[31:2];
assign inst_sram_wdata  = 32'b0;
//IR   <= inst_sram_rdata;已在IF/ID给出

always@(posedge clk) begin
    if(!rstn)begin
        pc <= 32'h1c000000;
    end
    else if(pc_we)begin
        pc <= nextpc;
    end
end

assign seqpc        = pc + 3'h4;
assign nextpc       = br_en ? br_target : seqpc;

//IF/ID
always@(posedge clk) begin
    if(!rstn || IFID_cl)begin
        IR          <= 32'h00000000;
        IFID_pc     <= 32'h00000000;
    end else if(IFID_we)begin
        IR          <= inst_sram_rdata;
        IFID_pc     <= pc;
    end
end

/*********************  ID  **********************/
assign inst             = IR;
assign op_31_26 = inst[31:26];
assign op_25_22 = inst[25:22];
assign op_21_20 = inst[21:20];
assign op_19_15 = inst[19:15];

assign rk       = inst[14:10];
assign rj       = inst[9:5];
assign rd       = inst[4:0];

assign i_12    = inst[21:10];
assign i_20    = inst[24:5];

assign offs_16  = inst[25:10];
assign offs_26  = {inst[ 9: 0], inst[25:10]};

decoder_6_64 u_dec0(.in(op_31_26),  .co(op_31_26_d));
decoder_4_16 u_dec1(.in(op_25_22),  .co(op_25_22_d));
decoder_2_4  u_dec2(.in(op_21_20),  .co(op_21_20_d));
decoder_5_32 u_dec3(.in(op_19_15),  .co(op_19_15_d));

assign inst_add_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_sub_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_slt         = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_sltu        = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
assign inst_nor         = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_and         = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_or          = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_xor         = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
assign inst_slli_w      = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
assign inst_srli_w      = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
assign inst_srai_w      = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
assign inst_addi_w      = op_31_26_d[6'h00] & op_25_22_d[4'ha];
assign inst_ld_w        = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
assign inst_st_w        = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
assign inst_jirl        = op_31_26_d[6'h13];
assign inst_b           = op_31_26_d[6'h14];
assign inst_bl          = op_31_26_d[6'h15];
assign inst_beq         = op_31_26_d[6'h16];
assign inst_bne         = op_31_26_d[6'h17];
assign inst_lu12i_w     = op_31_26_d[6'h05] & ~inst[25];
assign inst_pcaddu12i   = op_31_26_d[6'h07] & ~inst[25];
assign inst_mul_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h18];
assign inst_slti        = op_31_26_d[6'h00] & op_25_22_d[4'h8];
assign inst_sltui       = op_31_26_d[6'h00] & op_25_22_d[4'h9];
assign inst_andi        = op_31_26_d[6'h00] & op_25_22_d[4'hd];
assign inst_ori         = op_31_26_d[6'h00] & op_25_22_d[4'he];
assign inst_xori        = op_31_26_d[6'h00] & op_25_22_d[4'hf];
assign inst_sll_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0e];
assign inst_srl_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0f];
assign inst_sra_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];
assign inst_st_h        = op_31_26_d[6'h0a] & op_25_22_d[4'h5];
assign inst_st_b        = op_31_26_d[6'h0a] & op_25_22_d[4'h4];
assign inst_ld_h        = op_31_26_d[6'h0a] & op_25_22_d[4'h1];
assign inst_ld_b        = op_31_26_d[6'h0a] & op_25_22_d[4'h0];
assign inst_ld_hu       = op_31_26_d[6'h0a] & op_25_22_d[4'h9];
assign inst_ld_bu       = op_31_26_d[6'h0a] & op_25_22_d[4'h8];
assign inst_blt         = op_31_26_d[6'h18];
assign inst_bge         = op_31_26_d[6'h19];
assign inst_bltu        = op_31_26_d[6'h1a];
assign inst_bgeu        = op_31_26_d[6'h1b];

assign alu_op[ 0] = inst_add_w  | inst_addi_w   | inst_ld_w     | inst_st_w
                  | inst_jirl   | inst_bl       | inst_pcaddu12i| inst_ld_h
                  | inst_ld_b   | inst_ld_hu    | inst_ld_bu    | inst_st_b
                  | inst_st_h;
assign alu_op[ 1] = inst_sub_w;
assign alu_op[ 2] = inst_slt    | inst_slti     | inst_blt      |inst_bge;
assign alu_op[ 3] = inst_sltu   | inst_sltui    | inst_bltu     |inst_bgeu;
assign alu_op[ 4] = inst_and    | inst_andi;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or     | inst_ori;
assign alu_op[ 7] = inst_xor    | inst_xori;
assign alu_op[ 8] = inst_slli_w | inst_sll_w;
assign alu_op[ 9] = inst_srli_w | inst_srl_w;
assign alu_op[10] = inst_srai_w | inst_sra_w;
assign alu_op[11] = inst_lu12i_w;
assign alu_op[12] = inst_mul_w;

assign imm_sel      = inst_lu12i_w | inst_pcaddu12i;//值为1时，选择{si_20,12{0}};0时imm选择si12
assign need_offs_26 =  inst_b       | inst_bl;
assign need_ui_12   =  inst_andi    | inst_ori  | inst_xori;
assign src2_is_4    =  inst_jirl    | inst_bl;

//控制信号的生成
assign alu_src1_sel =   inst_jirl | inst_bl | inst_pcaddu12i;//ALU源操作数1的选择逻辑
                                             //1:PC
                                             //0:rf_rdata1(rj)
assign alu_src2_sel =   inst_slli_w     |
                        inst_srli_w     |
                        inst_srai_w     |
                        inst_addi_w     |
                        inst_ld_w       |
                        inst_ld_h       |
                        inst_ld_b       |
                        inst_ld_hu      |
                        inst_ld_bu      |
                        inst_st_w       |
                        inst_st_b       |
                        inst_st_h       |
                        inst_lu12i_w    |
                        inst_pcaddu12i  |
                        inst_jirl       |
                        inst_bl         |
                        inst_slti       |
                        inst_sltui      |
                        inst_andi       |
                        inst_ori        |
                        inst_xori       ;//ALU源操作数2的选择逻辑
                                         //1:imm(4/imm)
                                         //0:rf_rdata2(rkd)
assign data_sram_we = (inst_st_w | inst_st_b | inst_st_h) & valid;
assign rf_we        = (~inst_st_w & ~inst_st_b & ~inst_st_h & ~inst_beq & ~inst_bne & ~inst_b & ~inst_blt & ~inst_bltu & ~inst_bge & ~inst_bgeu) & valid;
assign rf_raddr2_sel= inst_st_w | inst_st_b | inst_st_h | inst_bne | inst_beq 
                    | inst_blt  | inst_bge  | inst_bltu | inst_bgeu;//1:rd，0:rk
assign dst_is_r1    = inst_bl;
assign wb_sel       = inst_ld_w | inst_ld_h | inst_ld_b | inst_ld_hu | inst_ld_bu;//值为1时，写回DR中的值; 值为0时，写回ALU_result
assign wb_dest      = dst_is_r1 ? 5'd1 : rd;

assign rf_raddr1    = rj;
assign rf_raddr2    = rf_raddr2_sel ? rd : rk;
regfile u_regfile(
    .clk    (clk            ),
    .rstn   (rstn           ),
    .raddr1 (rf_raddr1      ),
    .raddr2 (rf_raddr2      ),
    .rdata1 (rf_rdata1      ),
    .rdata2 (rf_rdata2      ),
    .we     (ctrw_WB_rf_we  ),
    .waddr  (MEMWB_wb_dest  ),
    .wdata  (wb_data        )
    ,.rdata0(drd0           )
    ,.raddr0(dra0           )
);

assign ui_12_to_32  = {{20{1'b0}}       , i_12[11:0]};

assign si_12_to_32  = {{20{i_12[11]}}   , i_12[11:0]};

assign si_20_to_32  = {i_20[19:0]      , 12'b0};

assign imm = src2_is_4  ? 32'h4                     :
             imm_sel    ? si_20_to_32               :
             need_ui_12 ? ui_12_to_32               :
/*need_ui5 || need_si12*/si_12_to_32                ;

assign br_offs = need_offs_26 ? {{ 4{offs_26[25]}}, offs_26[25:0], 2'b0} :
                                {{14{offs_16[15]}}, offs_16[15:0], 2'b0} ;

assign jirl_offs = {{14{offs_16[15]}}, offs_16[15:0], 2'b0};


//ID/EX
always@(posedge clk) begin
    if(!rstn || IDEX_cl)begin
        //data
        IDEX_inst           <= 0;
        IDEX_pc             <= 0;
        IDEX_inst_add_w     <= 0;
        IDEX_inst_sub_w     <= 0;
        IDEX_inst_slt       <= 0;
        IDEX_inst_sltu      <= 0;
        IDEX_inst_nor       <= 0;
        IDEX_inst_and       <= 0;
        IDEX_inst_or        <= 0;
        IDEX_inst_xor       <= 0;
        IDEX_inst_slli_w    <= 0;
        IDEX_inst_srli_w    <= 0;
        IDEX_inst_srai_w    <= 0;
        IDEX_inst_addi_w    <= 0;
        IDEX_inst_ld_w      <= 0;
        IDEX_inst_st_w      <= 0;
        IDEX_inst_jirl      <= 0;
        IDEX_inst_b         <= 0;
        IDEX_inst_bl        <= 0;
        IDEX_inst_beq       <= 0;
        IDEX_inst_bne       <= 0;
        IDEX_inst_lu12i_w   <= 0;
        IDEX_inst_pcaddu12i <= 0;
        IDEX_inst_mul_w     <= 0;
        IDEX_inst_slti      <= 0;
        IDEX_inst_sltui     <= 0;
        IDEX_inst_andi      <= 0;
        IDEX_inst_ori       <= 0;
        IDEX_inst_xori      <= 0;
        IDEX_inst_sll_w     <= 0;
        IDEX_inst_srl_w     <= 0;
        IDEX_inst_sra_w     <= 0;
        IDEX_inst_st_h      <= 0;
        IDEX_inst_st_b      <= 0;
        IDEX_inst_ld_h      <= 0;
        IDEX_inst_ld_b      <= 0;
        IDEX_inst_ld_hu     <= 0;
        IDEX_inst_ld_bu     <= 0;
        IDEX_inst_blt       <= 0;
        IDEX_inst_bge       <= 0;
        IDEX_inst_bltu      <= 0;
        IDEX_inst_bgeu      <= 0;
        IDEX_wb_dest        <= 0;
        IDEX_br_offs        <= 0;
        IDEX_jirl_offs      <= 0;
        IDEX_rf_raddr1      <= 0;
        IDEX_rf_raddr2      <= 0;
        IDEX_rf_rdata1      <= 0;
        IDEX_rf_rdata2      <= 0;
        IDEX_imm            <= 0;
        //control signal
        ctr_EX_alu_src1_sel <= 0;
        ctr_EX_alu_src2_sel <= 0;
        ctr_EX_alu_op       <= 0;
        ctr_MEM_data_sram_we<= 0;
        ctr_WB_rf_we        <= 0;
        ctr_WB_wb_sel       <= 0;
    end
    else if(IDEX_we)begin
        //data
        IDEX_inst           <= IR;
        IDEX_pc             <= IFID_pc;
        IDEX_inst_add_w     <= inst_add_w;
        IDEX_inst_sub_w     <= inst_sub_w;
        IDEX_inst_slt       <= inst_slt;
        IDEX_inst_sltu      <= inst_sltu;
        IDEX_inst_nor       <= inst_nor;
        IDEX_inst_and       <= inst_and;
        IDEX_inst_or        <= inst_or;
        IDEX_inst_xor       <= inst_xor;
        IDEX_inst_slli_w    <= inst_slli_w;
        IDEX_inst_srli_w    <= inst_srli_w;
        IDEX_inst_srai_w    <= inst_srai_w;
        IDEX_inst_addi_w    <= inst_addi_w;
        IDEX_inst_ld_w      <= inst_ld_w;
        IDEX_inst_st_w      <= inst_st_w;
        IDEX_inst_jirl      <= inst_jirl;
        IDEX_inst_b         <= inst_b;
        IDEX_inst_bl        <= inst_bl;
        IDEX_inst_beq       <= inst_beq;
        IDEX_inst_bne       <= inst_bne;
        IDEX_inst_lu12i_w   <= inst_lu12i_w;
        IDEX_inst_pcaddu12i <= inst_pcaddu12i;
        IDEX_inst_mul_w     <= inst_mul_w    ;
        IDEX_inst_slti      <= inst_slti     ;
        IDEX_inst_sltui     <= inst_sltui    ;
        IDEX_inst_andi      <= inst_andi     ;
        IDEX_inst_ori       <= inst_ori      ;
        IDEX_inst_xori      <= inst_xori     ;
        IDEX_inst_sll_w     <= inst_sll_w    ;
        IDEX_inst_srl_w     <= inst_srl_w    ;
        IDEX_inst_sra_w     <= inst_sra_w    ;
        IDEX_inst_st_h      <= inst_st_h     ;
        IDEX_inst_st_b      <= inst_st_b     ;
        IDEX_inst_ld_h      <= inst_ld_h     ;
        IDEX_inst_ld_b      <= inst_ld_b     ;
        IDEX_inst_ld_hu     <= inst_ld_hu    ;
        IDEX_inst_ld_bu     <= inst_ld_bu    ;
        IDEX_inst_blt       <= inst_blt      ;
        IDEX_inst_bge       <= inst_bge      ;
        IDEX_inst_bltu      <= inst_bltu     ;
        IDEX_inst_bgeu      <= inst_bgeu     ;
        IDEX_wb_dest        <= wb_dest;
        IDEX_br_offs        <= br_offs;
        IDEX_jirl_offs      <= jirl_offs;
        IDEX_rf_rdata1      <= rf_rdata1;
        IDEX_rf_rdata2      <= rf_rdata2;
        IDEX_rf_raddr2      <= rf_raddr2;
        IDEX_rf_raddr1      <= rf_raddr1;
        IDEX_imm            <= imm;
        //control signal
        ctr_EX_alu_src1_sel <= alu_src1_sel;
        ctr_EX_alu_src2_sel <= alu_src2_sel;
        ctr_EX_alu_op       <= alu_op;
        ctr_MEM_data_sram_we<= data_sram_we;
        ctr_WB_rf_we        <= rf_we;
        ctr_WB_wb_sel       <= wb_sel;
    end
end

/*********************  EX  **********************/
assign rj_eq_rd     = (forward1 == forward2);
assign br_en        = (    IDEX_inst_beq    &  rj_eq_rd
                        || IDEX_inst_bne    & !rj_eq_rd
                        || IDEX_inst_jirl
                        || IDEX_inst_bl
                        || IDEX_inst_b
                        || IDEX_inst_blt    & alu_result[0]
                        || IDEX_inst_bltu   & alu_result[0]
                        || IDEX_inst_bge    & ~alu_result[0]
                        || IDEX_inst_bgeu   & ~alu_result[0]
                        ) && valid;
assign br_target =  IDEX_inst_jirl ?    (forward1 + IDEX_jirl_offs) :
                                        (IDEX_pc + IDEX_br_offs);

/*******************************forwarding unit***************************************/

//forward1管先指令(EX/MEM级或MEM/WB级)的写回寄存器号wb_dest(rd)与后指令(ID/EX级)的读寄存器号rf_raddr1(rj)的冲突。
//对先指令，需要排除不含rd，或尽管含rd，但不写回rd的指令(如st)
//对后指令，需要排除不含rj的指令
//foward1_en1管EX/MEM的rd与ID/EX的rj的冲突，为1时，有可能发生冲突，产生前递
//foward1_en2管MEM/WB的rd与ID/EX的rj的冲突，为1时，有可能发生冲突，产生前递
assign forward1_en1 = ctrm_WB_rf_we
                    & (!IDEX_inst_lu12i_w    & !IDEX_inst_pcaddu12i  & !IDEX_inst_b      & !IDEX_inst_bl); 

assign forward1_en2 = ctrw_WB_rf_we
                    & (!IDEX_inst_lu12i_w    & !IDEX_inst_pcaddu12i  & !IDEX_inst_b      & !IDEX_inst_bl);

//forward1管先指令(EX/MEM级或MEM/WB级)的写回寄存器号wb_dest(rd)与后指令(ID/EX级)的读寄存器号rf_raddr2(rk/rd)的冲突。
//对先指令，需要排除不含rd，或尽管含rd，但不写回rd的指令(如st)
//对后指令，需要找出含rk/rd，且rk/rd要做操作数的指令
//foward2_en1管EX/MEM的rd与ID/EX的rk/rd(读端口2)的冲突，为1时，有可能发生冲突，产生前递
//foward2_en2管MEM/WB的rd与ID/EX的rk/rd(读端口2)的冲突，为1时，有可能发生冲突，产生前递
assign forward2_en1 = ctrm_WB_rf_we
                    & ( IDEX_inst_add_w      | IDEX_inst_sub_w       | IDEX_inst_slt     | IDEX_inst_sltu        | IDEX_inst_nor 
                      | IDEX_inst_and        | IDEX_inst_or          | IDEX_inst_xor     | IDEX_inst_mul_w       | IDEX_inst_sll_w 
                      | IDEX_inst_srl_w      | IDEX_inst_sra_w       | IDEX_inst_beq     | IDEX_inst_bne         | IDEX_inst_blt 
                      | IDEX_inst_bge        | IDEX_inst_bltu        | IDEX_inst_bgeu);

assign forward2_en2 = ctrw_WB_rf_we
                    & ( IDEX_inst_add_w      | IDEX_inst_sub_w       | IDEX_inst_slt     | IDEX_inst_sltu        | IDEX_inst_nor 
                      | IDEX_inst_and        | IDEX_inst_or          | IDEX_inst_xor     | IDEX_inst_mul_w       | IDEX_inst_sll_w 
                      | IDEX_inst_srl_w      | IDEX_inst_sra_w       | IDEX_inst_beq     | IDEX_inst_bne         | IDEX_inst_blt 
                      | IDEX_inst_bge        | IDEX_inst_bltu        | IDEX_inst_bgeu); 

//forward1和forward2的选择
always @(*) begin
    if ((EXMEM_wb_dest == IDEX_rf_raddr1)      && forward1_en1  && EXMEM_wb_dest)//EXMEM_wb_dest不得为0
        forward1_sel = 2'b01;
    else if((MEMWB_wb_dest == IDEX_rf_raddr1)  && forward1_en2  && EXMEM_wb_dest)//上下两个条件不得调换，if后的条件优先级高，else if后的条件优先级低
        forward1_sel = 2'b10;
    else
        forward1_sel = 2'b00;

    if ((EXMEM_wb_dest == IDEX_rf_raddr2)    && forward2_en1  && EXMEM_wb_dest)
        forward2_sel = 2'b01;
    else if((MEMWB_wb_dest == IDEX_rf_raddr2)    && forward2_en2  && MEMWB_wb_dest)
        forward2_sel = 2'b10;
    else
        forward2_sel = 2'b00;

    case (forward1_sel)
        2'b00:
            forward1 = IDEX_rf_rdata1;
        2'b01:
            forward1 = EXMEM_alu_result;
        2'b10:
            forward1 = wb_data;
        default: 
            forward1 = IDEX_rf_rdata1;
    endcase


    case (forward2_sel)
        2'b00:
            forward2 = IDEX_rf_rdata2;
        2'b01:
            forward2 = EXMEM_alu_result;
        2'b10:
            forward2 = wb_data;
        default: 
            forward2 = IDEX_rf_rdata2;
    endcase
end

//alu_src的选择，此时经过forward unit的筛选，forward信号已经完全替代了rf_rdata1和rf_rdata2
assign alu_src1     = ctr_EX_alu_src1_sel ? IDEX_pc : forward1;
assign alu_src2     = ctr_EX_alu_src2_sel ? IDEX_imm : forward2;

alu u_alu(
    .alu_op     (ctr_EX_alu_op),
    .alu_src1   (alu_src1  ),
    .alu_src2   (alu_src2  ),
    .alu_result (alu_result)
    );

/*************************************Hazard Detection Unit*******************************************/
assign ld_hazard_rj_en = ctrm_WB_wb_sel
                       & ( !IDEX_inst_lu12i_w & !IDEX_inst_pcaddu12i & !IDEX_inst_b & !IDEX_inst_bl);

assign ld_hazard_rk_en = ctrm_WB_wb_sel
                       & ( IDEX_inst_add_w  | IDEX_inst_sub_w   | IDEX_inst_slt     | IDEX_inst_sltu        | IDEX_inst_nor     | IDEX_inst_and 
                         | IDEX_inst_or     | IDEX_inst_xor     | IDEX_inst_mul_w   | IDEX_inst_sll_w       | IDEX_inst_srl_w   | IDEX_inst_sra_w);

assign ld_hazard_rd_en = ctrm_WB_wb_sel
                       & ( IDEX_inst_beq    | IDEX_inst_bne     | IDEX_inst_blt     | IDEX_inst_bge         | IDEX_inst_bltu    | IDEX_inst_bgeu
                         | IDEX_inst_st_w   | IDEX_inst_st_h    | IDEX_inst_st_b);

always @(*) begin
    if(ld_hazard_rj_en && (EXMEM_wb_dest == IDEX_rf_raddr1)
    || ld_hazard_rk_en && (EXMEM_wb_dest == IDEX_rf_raddr2)
    || ld_hazard_rd_en && (EXMEM_wb_dest == IDEX_rf_raddr2))begin
        fStall = 1;
        dStall = 1;
        eFlush = 1;
    end
    else begin
        fStall = 0;
        dStall = 0;
        eFlush = 0;
    end
end

assign br_hazard_en = br_en;

always @(*) begin
    if(br_hazard_en)begin
        dFlush = 1;
        eFlush = 1;
    end
    else begin
        dFlush = 0;
        eFlush = 0;
    end
end

assign pc_we    = !fStall;
assign IFID_we  = !dStall;
assign IFID_cl  = dFlush;
assign IDEX_we  = 1;
assign IDEX_cl  = eFlush;

//EX/MEM
always@(posedge clk) begin
    if(!rstn)begin
        //data
        EXMEM_inst              <= 0;
        EXMEM_pc                <= 0;
        EXMEM_alu_result        <= 0;
        EXMEM_rf_rdata2         <= 0;
        EXMEM_inst_st_w         <= 0;
        EXMEM_inst_st_h         <= 0;
        EXMEM_inst_st_b         <= 0;
        EXMEM_inst_ld_w         <= 0;
        EXMEM_inst_ld_h         <= 0;
        EXMEM_inst_ld_b         <= 0;
        EXMEM_inst_ld_hu        <= 0;
        EXMEM_inst_ld_bu        <= 0;
        EXMEM_wb_dest           <= 0;
        //control signal
        ctrm_MEM_data_sram_we   <= 0;
        ctrm_WB_rf_we           <= 0;
        ctrm_WB_wb_sel          <= 0;
    end
    else begin
        //data
        EXMEM_inst              <= IDEX_inst;
        EXMEM_pc                <= IDEX_pc;
        EXMEM_alu_result        <= alu_result;
        EXMEM_rf_rdata2         <= IDEX_rf_rdata2;
        EXMEM_inst_st_w         <= IDEX_inst_st_w     ;
        EXMEM_inst_st_h         <= IDEX_inst_st_h     ;
        EXMEM_inst_st_b         <= IDEX_inst_st_b     ;
        EXMEM_inst_ld_w         <= IDEX_inst_ld_w     ;
        EXMEM_inst_ld_h         <= IDEX_inst_ld_h     ;
        EXMEM_inst_ld_b         <= IDEX_inst_ld_b     ;
        EXMEM_inst_ld_hu        <= IDEX_inst_ld_hu    ;
        EXMEM_inst_ld_bu        <= IDEX_inst_ld_bu    ;
        EXMEM_wb_dest           <= IDEX_wb_dest;
        //control signal
        ctrm_MEM_data_sram_we   <= ctr_MEM_data_sram_we;
        ctrm_WB_rf_we           <= ctr_WB_rf_we;
        ctrm_WB_wb_sel          <= ctr_WB_wb_sel;
    end
end

/*********************  MEM  **********************/
assign data_sram_addr   = EXMEM_alu_result[31:2];
always @(*) begin
    case({EXMEM_inst_st_w,EXMEM_inst_st_h,EXMEM_inst_st_b})
        3'b100://st.w
            st_data = EXMEM_rf_rdata2[31:0];
        3'b010://st.h
            case(EXMEM_alu_result[1])
                1'b0:
                    st_data = {data_sram_rdata[31:16], EXMEM_rf_rdata2[15:0]};
                1'b1:
                    st_data = {EXMEM_rf_rdata2[15:0], data_sram_rdata[15:0]};
            endcase
        3'b001://st.b
            case(EXMEM_alu_result[1:0])
                2'b00:
                    st_data = {data_sram_rdata[31:8], EXMEM_rf_rdata2[7:0]};
                2'b01:
                    st_data = {data_sram_rdata[31:16], EXMEM_rf_rdata2[7:0], data_sram_rdata[7:0]};
                2'b10:
                    st_data = {data_sram_rdata[31:24], EXMEM_rf_rdata2[7:0], data_sram_rdata[15:0]};
                2'b11:
                    st_data = {EXMEM_rf_rdata2[7:0], data_sram_rdata[23:0]};
            endcase
    endcase
end

assign data_sram_wdata  = st_data;
assign data_sram_we_out = ctrm_MEM_data_sram_we;

//MEM/WB
always@(posedge clk) begin
    if(!rstn)begin
        //data
        MEMWB_inst              <= 0;
        MEMWB_pc                <= 0;
        MEMWB_data_sram_rdata   <= 0;
        MEMWB_alu_result        <= 0;
        MEMWB_inst_ld_w         <= 0;
        MEMWB_inst_ld_h         <= 0;
        MEMWB_inst_ld_b         <= 0;
        MEMWB_inst_ld_hu        <= 0;
        MEMWB_inst_ld_bu        <= 0;
        MEMWB_wb_dest           <= 0;
        //control signal
        ctrw_WB_rf_we           <= 0;
        ctrw_WB_wb_sel          <= 0;
    end
    else begin
        //data
        MEMWB_inst              <= EXMEM_inst;
        MEMWB_pc                <= EXMEM_pc;
        MEMWB_data_sram_rdata   <= data_sram_rdata;
        MEMWB_alu_result        <= EXMEM_alu_result;
        MEMWB_inst_ld_w         <= EXMEM_inst_ld_w     ;
        MEMWB_inst_ld_h         <= EXMEM_inst_ld_h     ;
        MEMWB_inst_ld_b         <= EXMEM_inst_ld_b     ;
        MEMWB_inst_ld_hu        <= EXMEM_inst_ld_hu    ;
        MEMWB_inst_ld_bu        <= EXMEM_inst_ld_bu    ;
        MEMWB_wb_dest           <= EXMEM_wb_dest;
        //control signal
        ctrw_WB_rf_we           <= ctrm_WB_rf_we;
        ctrw_WB_wb_sel          <= ctrm_WB_wb_sel;
    end
end

/*********************  WB  **********************/
always @(*) begin
    case({MEMWB_inst_ld_w, MEMWB_inst_ld_h, MEMWB_inst_ld_b, MEMWB_inst_ld_hu, MEMWB_inst_ld_bu})
        5'b00001://ld.bu
            case(MEMWB_alu_result[1:0])
            //LA32小端存储,00为低位
                2'b00:
                    ld_data = {24'b0, MEMWB_data_sram_rdata[7:0]};
                2'b01:
                    ld_data = {24'b0, MEMWB_data_sram_rdata[15:8]};
                2'b10:
                    ld_data = {24'b0, MEMWB_data_sram_rdata[23:16]};
                2'b11:
                    ld_data = {24'b0, MEMWB_data_sram_rdata[31:24]};
            endcase
        5'b00010://ld.hu
            case(MEMWB_alu_result[1])
                1'b0:
                    ld_data = {16'b0, MEMWB_data_sram_rdata[15:0]};
                1'b1:
                    ld_data = {16'b0, MEMWB_data_sram_rdata[31:16]};
            endcase
        5'b00100://ld.b
            case(MEMWB_alu_result[1:0])
                2'b00:
                    ld_data = {{24{MEMWB_data_sram_rdata[7]}}, MEMWB_data_sram_rdata[7:0]};
                2'b01:
                    ld_data = {{24{MEMWB_data_sram_rdata[15]}}, MEMWB_data_sram_rdata[15:8]};
                2'b10:
                    ld_data = {{24{MEMWB_data_sram_rdata[23]}}, MEMWB_data_sram_rdata[23:16]};
                2'b11:
                    ld_data = {{24{MEMWB_data_sram_rdata[31]}}, MEMWB_data_sram_rdata[31:24]};
            endcase
        5'b01000://ld.h
            case(MEMWB_alu_result[1])
                1'b0:
                    ld_data = {{16{MEMWB_data_sram_rdata[15]}}, MEMWB_data_sram_rdata[15:0]};
                1'b1:
                    ld_data = {{16{MEMWB_data_sram_rdata[31]}}, MEMWB_data_sram_rdata[31:16]};
            endcase
        5'b10000://ld.w
            ld_data = MEMWB_data_sram_rdata;
        default:
            ld_data = MEMWB_alu_result;
    endcase
end

assign wb_data      = ctrw_WB_wb_sel ? ld_data : MEMWB_alu_result;

// debug info generate
assign debug_wb_pc       = MEMWB_pc;
assign debug_wb_rf_we    = {4{ctrw_WB_rf_we}};
assign debug_wb_rf_wnum  = MEMWB_wb_dest;
assign debug_wb_rf_wdata = wb_data;


endmodule