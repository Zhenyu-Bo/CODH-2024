module Decoder_plus(
    input           [31: 0]         inst,

    output          [18: 0]         alu_op,
    output          [31: 0]         imm,
    output          [ 0: 0]         src1_is_pc,
    output          [ 0: 0]         src2_is_imm,
    output          [ 0: 0]         res_from_mem,
    output          [ 0: 0]         gr_we,
    output          [ 0: 0]         mem_we,
    output          [ 0: 0]         src_reg_is_rd,
    output          [ 4: 0]         dest,
    output          [ 4: 0]         rj,
    output          [ 4: 0]         rk,
    output          [ 4: 0]         rd,
    output          [31: 0]         br_offs,
    output          [31: 0]         jirl_offs,
    output          [ 4: 0]         load_op,
    output          [ 2: 0]         store_op,
    output          [ 8: 0]         branch_op,
    output          [63: 0]         inst_kind
);

wire [ 5:0] op_31_26;
wire [ 3:0] op_25_22;
wire [ 1:0] op_21_20;
wire [ 4:0] op_19_15;
wire [11:0] i12;
wire [19:0] i20;
wire [15:0] i16;
wire [25:0] i26;

wire [63:0] op_31_26_d;
wire [15:0] op_25_22_d;
wire [ 3:0] op_21_20_d;
wire [31:0] op_19_15_d;

wire        inst_add_w;
wire        inst_sub_w;
wire        inst_slt;
wire        inst_sltu;
wire        inst_nor;
wire        inst_and;
wire        inst_or;
wire        inst_xor;
wire        inst_slli_w;
wire        inst_srli_w;
wire        inst_srai_w;
wire        inst_addi_w;
wire        inst_ld_w;
wire        inst_st_w;
wire        inst_jirl;
wire        inst_b;
wire        inst_bl;
wire        inst_beq;
wire        inst_bne;
wire        inst_lu12i_w;
wire        inst_pcaddui;
wire        inst_slti;
wire        inst_sltui;
wire        inst_andi;
wire        inst_ori;
wire        inst_xori;
wire        inst_sll_w;
wire        inst_srl_w;
wire        inst_sra_w;
wire        inst_ld_b;
wire        inst_ld_h;
wire        inst_st_b;
wire        inst_st_h;
wire        inst_ld_bu;
wire        inst_ld_hu;
wire        inst_blt;
wire        inst_bltu;
wire        inst_bge;
wire        inst_bgeu;
wire        inst_mul_w;
wire        inst_mulh_w;
wire        inst_mulh_wu;
wire        inst_div_w;
wire        inst_div_wu;
wire        inst_mod_w;
wire        inst_mod_wu;

wire        need_ui5;
wire        need_ui12;
wire        need_si12;
wire        need_si16;
wire        need_si20;
wire        need_si26;
wire        src2_is_4;
wire        dst_is_r1;


assign op_31_26  = inst[31:26];
assign op_25_22  = inst[25:22];
assign op_21_20  = inst[21:20];
assign op_19_15  = inst[19:15];

assign rd   = inst[ 4: 0];
assign rj   = inst[ 9: 5];
assign rk   = inst[14:10];

assign i12  = inst[21:10];
assign i20  = inst[24: 5];
assign i16  = inst[25:10];
assign i26  = {inst[ 9: 0], inst[25:10]};

decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];
assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
assign inst_jirl   = op_31_26_d[6'h13];
assign inst_b      = op_31_26_d[6'h14];
assign inst_bl     = op_31_26_d[6'h15];
assign inst_beq    = op_31_26_d[6'h16];
assign inst_bne    = op_31_26_d[6'h17];
assign inst_lu12i_w= op_31_26_d[6'h05] & ~inst[25];
assign inst_pcaddui= op_31_26_d[6'h07] & ~inst[25];
assign inst_slti   = op_31_26_d[6'h00] & op_25_22_d[4'h8];
assign inst_sltui  = op_31_26_d[6'h00] & op_25_22_d[4'h9];
assign inst_andi   = op_31_26_d[6'h00] & op_25_22_d[4'hd];
assign inst_ori    = op_31_26_d[6'h00] & op_25_22_d[4'he];
assign inst_xori   = op_31_26_d[6'h00] & op_25_22_d[4'hf];
assign inst_sll_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0e];
assign inst_srl_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0f];
assign inst_sra_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];
assign inst_ld_b   = op_31_26_d[6'h0a] & op_25_22_d[4'h0];
assign inst_ld_h   = op_31_26_d[6'h0a] & op_25_22_d[4'h1];
assign inst_st_b   = op_31_26_d[6'h0a] & op_25_22_d[4'h4];
assign inst_st_h   = op_31_26_d[6'h0a] & op_25_22_d[4'h5];
assign inst_ld_bu  = op_31_26_d[6'h0a] & op_25_22_d[4'h8];
assign inst_ld_hu  = op_31_26_d[6'h0a] & op_25_22_d[4'h9];
assign inst_blt    = op_31_26_d[6'h18];
assign inst_bltu   = op_31_26_d[6'h1a];
assign inst_bge    = op_31_26_d[6'h19];
assign inst_bgeu   = op_31_26_d[6'h1b];
assign inst_mul_w  = ({3'b0,inst[31:15]} == 20'h00038);
assign inst_mulh_w = ({3'b0,inst[31:15]} == 20'h00039);
assign inst_mulh_wu= ({3'b0,inst[31:15]} == 20'h0003a);
assign inst_div_w  = ({3'b0,inst[31:15]} == 20'h00040);
assign inst_div_wu = ({3'b0,inst[31:15]} == 20'h00042);
assign inst_mod_w  = ({3'b0,inst[31:15]} == 20'h00041);
assign inst_mod_wu = ({3'b0,inst[31:15]} == 20'h00043);

assign alu_op[ 0] = inst_add_w  | inst_addi_w | inst_pcaddui |
                    | inst_ld_w | inst_ld_b   | inst_ld_bu   | inst_ld_h | inst_ld_hu |
                    | inst_st_w | inst_st_b   | inst_st_h    |
                    | inst_jirl | inst_bl;
assign alu_op[ 1] = inst_sub_w;
assign alu_op[ 2] = inst_slt  | inst_slti  | inst_blt  | inst_bge ;
assign alu_op[ 3] = inst_sltu | inst_sltui | inst_bltu | inst_bgeu;
assign alu_op[ 4] = inst_and  | inst_andi ;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or   | inst_ori;
assign alu_op[ 7] = inst_xor  | inst_xori;
assign alu_op[ 8] = inst_slli_w | inst_sll_w;
assign alu_op[ 9] = inst_srli_w | inst_srl_w;
assign alu_op[10] = inst_srai_w | inst_sra_w;
assign alu_op[11] = inst_lu12i_w;
assign alu_op[12] = inst_mul_w;
assign alu_op[13] = inst_mulh_w;
assign alu_op[14] = inst_mulh_wu;
assign alu_op[15] = inst_div_w;
assign alu_op[16] = inst_div_wu;
assign alu_op[17] = inst_mod_w;
assign alu_op[18] = inst_mod_wu;

assign need_ui5   =  inst_slli_w| inst_srli_w | inst_srai_w;
assign need_ui12  =  inst_andi  | inst_ori  | inst_xori;
assign need_si12  =  inst_addi_w| inst_ld_w | inst_ld_b | inst_ld_bu | inst_ld_h | inst_ld_hu |
                     inst_st_w | inst_st_b | inst_st_h | inst_slti  | inst_sltui;
assign need_si16  =  inst_jirl  | inst_beq  | inst_bne  | inst_blt   | inst_bge  | inst_bltu | inst_bgeu;
assign need_si20  =  inst_lu12i_w| inst_pcaddui;
assign need_si26  =  inst_b     | inst_bl;
assign src2_is_4  =  inst_jirl  | inst_bl;

assign imm = src2_is_4 ? 32'h4                      :
             need_si20 ? {i20[19:0], 12'b0}         :
             need_si12 ? {{20{i12[11]}}, i12[11:0]} :
             need_ui12 ? {20'b0, i12[11:0]}         :
             /*need_ui5*/{27'b0, rk}                ;

assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0], 2'b0} :
                             {{14{i16[15]}}, i16[15:0], 2'b0} ;

assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

assign src_reg_is_rd = inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu |
                       inst_st_w| inst_st_h|inst_st_b ;

assign src1_is_pc    = inst_jirl | inst_bl | inst_pcaddui;

assign src2_is_imm   = inst_slli_w  |
                       inst_srli_w  |
                       inst_srai_w  |
                       inst_addi_w  |
                       inst_ld_w    |
                       inst_st_w    |
                       inst_lu12i_w |
                       inst_jirl    |
                       inst_bl      |
                       inst_pcaddui |
                       inst_slti    |
                       inst_sltui   |
                       inst_andi    |
                       inst_ori     |
                       inst_xori    |
                       inst_ld_b    |
                       inst_ld_bu   |
                       inst_ld_h    |
                       inst_ld_hu   |
                       inst_st_b    |
                       inst_st_h    ;

assign res_from_mem  = inst_ld_w    | inst_ld_h | inst_ld_b | inst_ld_hu | inst_ld_bu;
assign dst_is_r1     = inst_bl;
assign gr_we         = ~inst_st_w & ~inst_st_b & ~inst_st_h &
                       ~inst_beq  & ~inst_bne  & ~inst_b    & ~inst_blt & ~inst_bge & ~inst_bltu & ~inst_bgeu;
assign mem_we        = inst_st_w  | inst_st_h  | inst_st_b;
assign dest          = dst_is_r1 ? 5'd1 : rd;

assign load_op[0] = inst_ld_w;
assign load_op[1] = inst_ld_h;
assign load_op[2] = inst_ld_b;
assign load_op[3] = inst_ld_hu;
assign load_op[4] = inst_ld_bu;

assign store_op[0] = inst_st_w;
assign store_op[1] = inst_st_h;
assign store_op[2] = inst_st_b;

assign branch_op[ 0] = inst_beq;
assign branch_op[ 1] = inst_bne;
assign branch_op[ 2] = inst_blt;
assign branch_op[ 3] = inst_bltu;
assign branch_op[ 4] = inst_bge;
assign branch_op[ 5] = inst_bgeu;
assign branch_op[ 6] = inst_b;
assign branch_op[ 7] = inst_bl;
assign branch_op[ 8] = inst_jirl;


assign inst_kind[0] = inst_add_w;
assign inst_kind[1] = inst_addi_w;
assign inst_kind[2] = inst_lu12i_w;
assign inst_kind[3] = inst_sub_w;
assign inst_kind[4] = inst_pcaddui;
assign inst_kind[5] = inst_slt;
assign inst_kind[6] = inst_sltu;
assign inst_kind[7] = inst_slti;
assign inst_kind[8] = inst_sltui;
assign inst_kind[9] = inst_and;
assign inst_kind[10] = inst_or;
assign inst_kind[11] = inst_nor;
assign inst_kind[12] = inst_xor;
assign inst_kind[13] = inst_andi;
assign inst_kind[14] = inst_ori;
assign inst_kind[15] = inst_xori;
assign inst_kind[16] = inst_slli_w;
assign inst_kind[17] = inst_srli_w;
assign inst_kind[18] = inst_srai_w;
assign inst_kind[19] = inst_sll_w;
assign inst_kind[20] = inst_srl_w;
assign inst_kind[21] = inst_sra_w;
assign inst_kind[22] = inst_ld_w;
assign inst_kind[23] = inst_ld_h;
assign inst_kind[24] = inst_ld_b;
assign inst_kind[25] = inst_ld_hu;
assign inst_kind[26] = inst_ld_bu;
assign inst_kind[27] = inst_st_w;
assign inst_kind[28] = inst_st_h;
assign inst_kind[29] = inst_st_b;
assign inst_kind[30] = inst_jirl;
assign inst_kind[31] = inst_bl;
assign inst_kind[32] = inst_b;
assign inst_kind[33] = inst_beq;
assign inst_kind[34] = inst_bne;
assign inst_kind[35] = inst_blt;
assign inst_kind[36] = inst_bltu;
assign inst_kind[37] = inst_bge;
assign inst_kind[38] = inst_bgeu;
assign inst_kind[39] = inst_mul_w;
assign inst_kind[40] = inst_mulh_w;
assign inst_kind[41] = inst_mulh_wu;
assign inst_kind[42] = inst_div_w;
assign inst_kind[43] = inst_div_wu;
assign inst_kind[44] = inst_mod_w;
assign inst_kind[45] = inst_mod_wu;
assign inst_kind[63:46] = 18'b0;

endmodule
