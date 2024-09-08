# Lab 3

## 数据通路

### 算术逻辑指令

算术逻辑指令是利用ALU来进行计算的指令。由于源操作数的选择会影响到数据通路，所以这里分为以下几种情况：

#### 寄存器+寄存器型

这种类型的指令根据指令中的源寄存器号从寄存器堆中读取源操作数并传递给ALU，最后根据指令中指示的目标寄存器号将ALU的计算结果写回目标寄存器。

在要实现的39条指令中，这种类型的指令包括`add.w`，`sub.w`，`sltu`，`sltu`，`and`，`or`，`nor`，`xor`，`sll.w`，`srl.w`，`sra.w`。数据通路如下：

![add_w](figs\add_w.png)

#### 寄存器+立即数型

这种类型的指令根据指令中的源寄存器号从寄存器堆中读取第一个源操作数并传递给ALU，还将指令中立即数的相应部分进行扩展后传递给ALU，最后根据指令中指示的目标寄存器号将ALU的计算结果写回目标寄存器。

在要实现的39条指令中，这种类型的指令包括`addi.w`，`slti`，`sltui`，`andi`，`ori`，`xori`，`slli.w`，`srl.w`，`srai.w`。其中只有`andi`，`ori`，`xori`需要进行零符号扩展，其余指令都需要进行有符号扩展。

`andi`，`ori`，`xori`的数据通路如下：
![andi](figs\andi.png)

其余指令的数据通路如下：

![addi](figs\addi_w.png)



#### PC+立即数型

这种类型的指令是以`PC`为第一个源操作数，扩展后的立即数为第二个源操作数，最后将ALU的计算结果写回目标寄存器中。

在要实现的39条指令中，这种类型的指令只有`lu12i.w`和`pcaddu12i`。

其中`lu12i.w`是要将立即数进行有符号扩展，而`pcaddu12i`是要 20 比特立即数 si20 最低位连接上 12 比特 0 之后符号扩展，但总的来说二者的数据通路相同，如下：

![lu12i_w](figs\lu12i_w.png)

### 访存指令

访存指令包括`ld`和`st`类型的指令，这类指令需要访问数据内存，读取或写入数据，以此可分为以下两类：

#### 取数指令

在要实现的39条指令中，取数指令包括`ld.w`，`ld.h`，`ld.b`，`ld.hu`，`ld.bu`，它们都是从寄存器堆中读取第一个源操作数，将立即数扩展得到第二个立即数，经ALU相加后得到访存地址，取出数据后写回目标寄存器中。其中`ld.w`指令是要取得的一整个字写回，`ld.h`，`ld.b`分别取出半个字和一个字节后进行有符号扩展再写回，`ld.hu`，`ld.bu`则是分别取出半个字和一个字节后进行无符号扩展再写回。因此它们的数据通路有所不同。

`ld.w`：

![ld_w](figs\ld_w.png)

`ld.h`：

![ld_h](figs\ld_h.png)



`ld_b`：

![ld_b](figs\ld_b.png)

`ld_hu`：

![ld_hu](figs\ld_hu.png)

`ld_bu`:

![ld_bu](figs\ld_bu.png)

#### 存数指令

在要实现的39条指令中，这种类型的指令包括`st.w`，`st.h`，`st.b`三条，这三条指令分别表示将取得源操作数的整个字/半个字/一个字节写入数据寄存器中。因此它们的数据通路也会有所不同。

`st.w`：

![st_w](figs\st_w.png)

`st.b/st.h`：

由于这两条指令在数据的扩展上有点复杂，所以这里用一个`EX`来统一表示，具体实现用语言描述。

![st_b](figs\st_b.png)

#### 访存指令详解

因为访存指令在只读取或存储半个字/一个字节时，需要特殊处理，所以这里再额外解释。

设`addr`为数据存储器的地址，读到的数据为`rdata`，寄存器堆读到的数据为`wdata`，最终写入的数据为`wdata_temp`。另设一个变量`rdata_temp`。

首先根据`addr[1:0]`的不同，处理`rdata_temp`，先放出代码如下：

```verilog
always @(*) begin
    case (data_sram_addr[1:0])
        2'b00: data_sram_rdata_temp = data_sram_rdata;
        2'b01: data_sram_rdata_temp = {8'b0,  data_sram_rdata[31: 8]};
        2'b10: data_sram_rdata_temp = {16'b0, data_sram_rdata[31:16]};
        2'b11: data_sram_rdata_temp = {24'b0, data_sram_rdata[31:24]};
    endcase
end
```

以`data_sram_addr[1:0] == 2'b01`为例，此时读到的数据为当前字的后三个字节和下一个字的第一个字节，所以取`data_sram_rdata`的前三个字节为`data_sram_rdata_temp`的后三个字节，高位补0。具体情况如图示：![示例](figs\示例.jpg)



我们想要的是{1,2,3,4}，而读取到的数据是{2,3,4,5}，最终得到的`rdata_temp`为{0000,2,3,4}。

所以还需要下面这段代码来得到最终的`ld`结果：

```verilog
assign mem_result = inst_ld_w ? data_sram_rdata_temp :
                    inst_ld_h ? {{16{data_sram_rdata_temp[15]}}, data_sram_rdata_temp[15:0]} :
                    inst_ld_b ? {{24{data_sram_rdata_temp[7]}}, data_sram_rdata_temp[ 7:0]}  :
                    inst_ld_hu? {16'b0, data_sram_rdata_temp[15:0]}     :
                  /*inst_ld_bu*/{24'b0, data_sram_rdata_temp[ 7:0]}     ;
```

对于`st.h/st.b`，需要注意不能覆盖原始数据，因此需要将`data_sram_rdata`与`data_sram_wdata`进行拼接，具体情况如下：

* `st.h`：这条指令要写入`wtemp`的后半个字，所以需要考虑要写入的半个字是位于其所在的那个字的上半部分还是下半部分。这就需要考虑`addr[1]`的值，如果为1，则说明为下半部分，需要将`wtemp = {rdata[31:16], wdata[15:0]}`；反之，如果为0，则`wtemp = {wdata[15：0],rdata[15:0]}`。
* `st.b`：类似于`st.h`，将一个字从上到下分为4个部分，这条指令需要考虑要写入的字节位于哪个部分，这就需要考虑`addr[1:0]`，如果`addr[1:0] == 2'b00`，就说明位于第一个部分，需要将`wdata = {rdata[31:8],wdata[7:0]}`；如果`addr[1:0]== 2'b01`，就说明位于第二个部分，就需要将`wdata = rdata[31:16],wdata[7:0],rdata[7:0]`，剩下两种情况同理。

最终可得代码应如下：

```verilog
always @(*) begin
    if(inst_st_b) begin
        case (data_sram_addr[1:0])
            2'b00: data_sram_wdata_temp = {data_sram_rdata[31: 8], rkd_value[7:0]};
            2'b01: data_sram_wdata_temp = {data_sram_rdata[31:16], rkd_value[7:0], data_sram_rdata[7:0]};
            2'b10: data_sram_wdata_temp = {data_sram_rdata[31:24], rkd_value[7:0], data_sram_rdata[15:0]};
            2'b11: data_sram_wdata_temp = {rkd_value[7:0], data_sram_rdata[23:0]};
        endcase
    end
    else if(inst_st_h)
        data_sram_wdata_temp = data_sram_addr[1] ? {rkd_value[15:0], data_sram_rdata[15:0]}
                                                 : {data_sram_rdata[31:16], rkd_value[15:0]};
    else
        data_sram_wdata_temp = rkd_value;
end
```

### 转移指令

转移指令需要根据条件判断是否需要跳转，如果需要跳转，就需要将`PC`赋值为基址加偏移量的值。

在要实现的39条指令中，这种类型的指令有`bne`,` beq`,` b`, `bl`,` jirl`,`blt`,`bge`,` bltu`,`bgeu`。其中`b`，`bl`，`jirl`三条指令无条件跳转，并且`bl`指令还要将`pc+4`的值写入寄存器`r1`中，`jirl`指令需要将`pc+4`的值写入指令中指示的目标寄存器中。

`bne`，`beq`，`blt`，`bge`，`bltu`，`bgeu`的数据通路如下：

![bne](figs\bne.jpg)

其中蓝线部分为跳转时的通路，不跳转时则这条指令只执行了`pc=pc+4`。

`b`，`jirl`指令的数据通路如下：

![b](figs\b.png)

需要说明的是，这里采取的数据通路和PPT上的并不一样，PPT上是用ALU来计算跳转后的`pc`，而这里用来计算`pc+4`以方便`b`和`jirl`指令写回寄存器，由于ALU被占用了，所以增加了一个加法器来计算`pc+offset`，最后再用一个选择器选择`pc+4`和`pc+offset`（因为在`verilog`中一个加法器可以简单的用一个加号来实现，所以这里选择了直接增加加法器）。



## 核心代码

### 完整代码

核心代码主要为`my_cpu_top.v`，如下：

```verilog
module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
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
wire [31:0] inst;
reg  [31:0] pc;

wire [11:0] alu_op;
wire        load_op;
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

wire [ 5:0] op_31_26;
wire [ 3:0] op_25_22;
wire [ 1:0] op_21_20;
wire [ 4:0] op_19_15;
wire [ 4:0] rd;
wire [ 4:0] rj;
wire [ 4:0] rk;
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


wire        need_ui5;
wire        need_ui12;
wire        need_si12;
wire        need_si16;
wire        need_si20;
wire        need_si26;
wire        src2_is_4;

wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;
wire        rf_we   ;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;

wire [31:0] alu_src1   ;
wire [31:0] alu_src2   ;
wire [31:0] alu_result ;

wire [31:0] mem_result;
wire [31:0] final_result;

assign seq_pc       = pc + 32'h4;
assign nextpc       = br_taken ? br_target : seq_pc;

always @(posedge clk) begin
    if (reset) begin
        pc <= 32'h1bfffffc;     //trick: to make nextpc be 0x1c000000 during reset 
    end
    else begin
        pc <= nextpc;
    end
end

assign inst_sram_we    = 1'b0;
assign inst_sram_addr  = pc;
assign inst_sram_wdata = 32'b0;
assign inst            = inst_sram_rdata;

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

assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd : rk;
regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
    );

assign rj_value  = rf_rdata1;
assign rkd_value = rf_rdata2;

assign rj_eq_rd = (rj_value == rkd_value);
assign br_taken = (   inst_beq  &&  rj_eq_rd
                   || inst_bne  && !rj_eq_rd
                   || inst_blt  && alu_result[0]
                   || inst_bltu && alu_result[0]
                   || inst_bge  && !alu_result[0]
                   || inst_bgeu && !alu_result[0]
                   || inst_jirl
                   || inst_bl
                   || inst_b
                  ) && valid;
assign br_target = (inst_beq || inst_bne || inst_bl || inst_b || inst_blt || inst_bge || inst_bltu || inst_bgeu) 
                                                                ? (pc + br_offs)        :
                                                   /*inst_jirl*/  (rj_value + jirl_offs);

assign alu_src1 = src1_is_pc  ? pc[31:0] : rj_value;
assign alu_src2 = src2_is_imm ? imm : rkd_value;

alu u_alu(
    .alu_op     (alu_op    ),
    .alu_src1   (alu_src1  ),
    .alu_src2   (alu_src2  ),
    .alu_result (alu_result)
    );

// 由于ld/st命令需要读取/存储1个字/半字/字节，所以需要根据data_sram_addr来处理mem_result和data_sram_wdata
reg [31:0]  data_sram_rdata_temp;
reg [31:0]  data_sram_wdata_temp;

always @(*) begin
    case (data_sram_addr[1:0])
        2'b00: data_sram_rdata_temp = data_sram_rdata;
        2'b01: data_sram_rdata_temp = {8'b0,  data_sram_rdata[31: 8]};
        2'b10: data_sram_rdata_temp = {16'b0, data_sram_rdata[31:16]};
        2'b11: data_sram_rdata_temp = {24'b0, data_sram_rdata[31:24]};
    endcase
end

always @(*) begin
    if(inst_st_b) begin
        case (data_sram_addr[1:0])
            2'b00: data_sram_wdata_temp = {data_sram_rdata[31: 8], rkd_value[7:0]};
            2'b01: data_sram_wdata_temp = {data_sram_rdata[31:16], rkd_value[7:0], data_sram_rdata[7:0]};
            2'b10: data_sram_wdata_temp = {data_sram_rdata[31:24], rkd_value[7:0], data_sram_rdata[15:0]};
            2'b11: data_sram_wdata_temp = {rkd_value[7:0], data_sram_rdata[23:0]};
        endcase
    end
    else if(inst_st_h)
        data_sram_wdata_temp = data_sram_addr[1] ? {rkd_value[15:0], data_sram_rdata[15:0]}
                                                 : {data_sram_rdata[31:16], rkd_value[15:0]};
    else
        data_sram_wdata_temp = rkd_value;
end
/*always @(*) begin
    if(inst_st_w)
        data_sram_wdata_temp = rkd_value;
    else if(inst_st_h)
        data_sram_wdata_temp = {data_sram_rdata[31:16], rkd_value[15:0]};
    else if(inst_st_b)
        data_sram_wdata_temp = {data_sram_rdata[31: 8], rkd_value[7:0]};
end*/

assign data_sram_wdata = data_sram_wdata_temp;
assign data_sram_we    = mem_we && valid;
assign data_sram_addr  = alu_result;
//assign data_sram_wdata = rkd_value;

assign mem_result = inst_ld_w ? data_sram_rdata_temp :
                    inst_ld_h ? {{16{data_sram_rdata_temp[15]}}, data_sram_rdata_temp[15:0]} :
                    inst_ld_b ? {{24{data_sram_rdata_temp[7]}}, data_sram_rdata_temp[ 7:0]}  :
                    inst_ld_hu? {16'b0, data_sram_rdata_temp[15:0]}     :
                  /*inst_ld_bu*/{24'b0, data_sram_rdata_temp[ 7:0]}     ;

assign final_result = res_from_mem ? mem_result : alu_result;

assign rf_we    = gr_we && valid;
assign rf_waddr = dest;
assign rf_wdata = final_result;

// debug info generate
assign debug_wb_pc       = pc;
assign debug_wb_rf_we    = {4{rf_we}};
assign debug_wb_rf_wnum  = dest;
assign debug_wb_rf_wdata = final_result;

endmodule
```



### 代码分析

下面分析代码中的各控制信号：

* 指令类型：根据指令的机器码可以得到各种类型指令的取指如下：

  ```verilog
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
  ```

  其中`op_31_26_d`是有指令的31-26位译码得到，`op_31_26_d[i] == 1`表示`op_31_26 == i`，`op_25_22_d`，`op_21_20_d`，`op_19_15_d`均类似。

* `nextpc`：`nextpc`的取指有两种可能`br_target`和`seq_pc`，前者表示跳转指令发生的`nextpc`，后者表示正常按顺序执行时的`nextpc`，即为`pc+4`。当执行的指令为跳转指令且跳转条件成立时`nextpc`才等于`br_target`，`br_target`由`pc`加上偏移量得到。于是可得以下代码：

  ```verilog
  assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0], 2'b0} :
                               {{14{i16[15]}}, i16[15:0], 2'b0} ;
  assign br_taken = (   inst_beq  &&  rj_eq_rd
                     || inst_bne  && !rj_eq_rd
                     || inst_blt  && alu_result[0]
                     || inst_bltu && alu_result[0]
                     || inst_bge  && !alu_result[0]
                     || inst_bgeu && !alu_result[0]
                     || inst_jirl
                     || inst_bl
                     || inst_b
                    ) && valid;
  assign seq_pc       = pc + 32'h4;
  assign nextpc       = br_taken ? br_target : seq_pc;
  
  always @(posedge clk) begin
      if (reset) begin
          pc <= 32'h1bfffffc;     //trick: to make nextpc be 0x1c000000 during reset 
      end
      else begin
          pc <= nextpc;
      end
  end
  ```

* `alu_op`：根据指令的类型及数据通路可以确定ALU需要执行的操作，于是可得源码如下：

  ```verilog
  assign alu_op[ 0] = inst_add_w  | inst_addi_w | inst_pcaddui |
                      | inst_ld_w | inst_ld_b   | inst_ld_bu   | inst_ld_h | inst_ld_hu |
                      | inst_st_w | inst_st_b   | inst_st_h    |
                      | inst_jirl | inst_bl;// 加法
  assign alu_op[ 1] = inst_sub_w;// 减法
  assign alu_op[ 2] = inst_slt  | inst_slti  | inst_blt  | inst_bge ; // 有符号小于
  assign alu_op[ 3] = inst_sltu | inst_sltui | inst_bltu | inst_bgeu; // 无符号小于
  assign alu_op[ 4] = inst_and  | inst_andi ; // 与
  assign alu_op[ 5] = inst_nor; // 或非
  assign alu_op[ 6] = inst_or   | inst_ori; // 或
  assign alu_op[ 7] = inst_xor  | inst_xori; // 异或
  assign alu_op[ 8] = inst_slli_w | inst_sll_w; // 左移
  assign alu_op[ 9] = inst_srli_w | inst_srl_w; // 逻辑右移
  assign alu_op[10] = inst_srai_w | inst_sra_w; // 算术右移
  assign alu_op[11] = inst_lu12i_w;// src2
  ```

* 立即数选择，根据指令的类型可以确定它需要什么样的立即数，代码如下：

  ```verilog
  assign need_ui5   =  inst_slli_w| inst_srli_w | inst_srai_w;// 5位数无符号扩展
  assign need_ui12  =  inst_andi  | inst_ori  | inst_xori; //12位数无符号扩展
  assign need_si12  =  inst_addi_w| inst_ld_w | inst_ld_b | inst_ld_bu | inst_ld_h | inst_ld_hu | inst_st_w | inst_st_b | inst_st_h | inst_slti  | inst_sltui; // 12位数有符号扩展
  assign need_si16  =  inst_jirl  | inst_beq  | inst_bne  | inst_blt   | inst_bge  | inst_bltu | inst_bgeu; // 16位数有符号扩展
  assign need_si20  =  inst_lu12i_w| inst_pcaddui; // 20位数有符号扩展
  assign need_si26  =  inst_b     | inst_bl; // 26位数有符号扩展
  assign src2_is_4  =  inst_jirl  | inst_bl;
  
  // 根据信号生成立即数
  assign imm = src2_is_4 ? 32'h4                      :
               need_si20 ? {i20[19:0], 12'b0}         :
               need_si12 ? {{20{i12[11]}}, i12[11:0]} :
               need_ui12 ? {20'b0, i12[11:0]}         :
               /*need_ui5*/{27'b0, rk}                ;
  ```

* 选择ALU的两个源操作数，ALU的第一个源操作数可能是寄存器堆读出的第一个数，也有可能是`pc`，第二个源操作数可能是寄存器堆读出的第二个数也可能是立即数，这就需要根据指令类型进行选择，选择信号代码如下：

  ```verilog
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
  ```

  此外读寄存器堆的第二个源寄存器号也需要进行选择，因为存数和跳转指令有特殊，代码如下：

  ```verilog
  assign src_reg_is_rd = inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu | inst_st_w| inst_st_h|inst_st_b ;
  ```

* 写回寄存器的数值选择：因为取数指令需要将从数据存储器中读出的数写回，而其余指令通过ALU计算后将结果写回或是不需要写回，所以可得代码如下：

  ```verilog
  assign res_from_mem  = inst_ld_w    | inst_ld_h | inst_ld_b | inst_ld_hu | inst_ld_bu;
  ```

* 目标寄存器选择：绝大部分指令的目标寄存器都有机器码中的`rd`指定，但`bl`指令的目标寄存器为`r1`，所以可得代码如下：

  ```verilog
  assign dst_is_r1     = inst_bl;
  ```

* 寄存器堆写使能：除了存数指令和部分跳转指令（除`bl`和`jirl`的跳转指令）外，其余指令都需要写回寄存器，所以可得代码如下：

  ```verilog
  assign gr_we         = ~inst_st_w & ~inst_st_b & ~inst_st_h &
                         ~inst_beq  & ~inst_bne  & ~inst_b    & ~inst_blt & ~inst_bge & ~inst_bltu & ~inst_bgeu;
  ```

* 数据寄存器写使能：只有存数指令需要写数据寄存器，所以可得代码如下：
  ```verilog
  assign mem_we        = inst_st_w  | inst_st_h  | inst_st_b;
  ```

确定了控制信号，根据这些控制信号选择或生成需要的操作数即可。

## 电路资源和性能

### 电路资源

如图：

![资源](F:\CSClasses\CODH\Lab\mycpu_env\figs\电路资源.png)

由表可见，该电路大量使用了`LUT`（查找表）和`LUTRAM`（分布式存储器）。

因为代码中实现了ALU的大部分功能，也即实现了很多逻辑函数，所以`LUT`的大量使用是必然的。而指令和数据存储均使用的分布式存储器，所以`LUTRAM`的大量使用也是合乎情理的。其中`LUTRAM`的资源利用率最高，可能是因为指令存储器中存储的指令条数多（存储了32267条指令，几乎达到了设置的容量32768），`LUT`的资源利用率并不是太高可能是因为一些逻辑函数的查找表使用的次数并不多。

### 性能

`cpu_clk = 10ns`时，`timing report`如下：

![10](F:\CSClasses\CODH\Lab\mycpu_env\figs\10ns.png)

此时WNS为负且绝对值较大，可见此时电路延迟严重。而10ns是一般情况下都会有富余的一个选择，可见设计的CPU性能较差。

由于此时`WNS`约为-4ns，所以设置`cpu_clk = 14ns`，`timing report`如下：

![14](F:\CSClasses\CODH\Lab\mycpu_env\figs\14ns.png)

可以看到此时WNS仍为负，但是已经接近于0

再略微增大时钟周期至15ns，`timing report`如下：

![15](F:\CSClasses\CODH\Lab\mycpu_env\figs\15ns.png)

此时WNS已经为正，所以可以得出此CPU的工作时钟周期在14-15ns之间，工作频率在66.7-71.4MHz之间。



## 测试结果

### 仿真结果

运行测试程序，测试结果如下：

20条指令：

![res_20](figs\res_20.png)

39条指令：

![res](figs\result.png)

可以看到，设计的CPU正确执行了39条指令，但是图中报出了`warning`。我在网上查询这个错误，发现龙芯

的`gitee`上有这个问题：

![warning1](figs\warning1.png)

上面说是版本的问题，也有评论说需要修改`data_sram`的Synthesis Options为Global：

![warning2](figs\warning2.png)

但是照做后也无法解决问题。

由于上板时却也都正常运行了，所以可以确定代码设计正确，应是vivado版本的问题。

### 上板结果

#### 指令测试结果

使用提供的环境生成的比特流上板时数码管一直在闪烁，所以只能尽量拍到下图的结果。可以看到首尾都是`14`，说明20条指令均正确（受存储器大小限制，无法上板39条指令的）

![test](figs\test_result.jpg)

#### 运行排序程序

运行排序程序，开关输入数据的下标，数码管显示数据

值得一提的是，为了实现这个效果，我对`soc_lite_top`文件做了相应的修改，以使开关控制数据的下标，数码管显示数据寄存器中的位数，具体实现方式如下：

1. 增加数码管显示模块并且修改`num_a_gn`，`num_csn`使他们显示数据寄存器读出的数据而不显示`num_data`

2. 增加排序结束标志指令，也即增加死循环，当执行到这条指令时，说明排序已经完成，此时将访问数据存储器的地址设置为开关输入的地址，在此之前访问数据存储器的地址由`mycpu_top.v`的输出决定。代码如下：

   ```verilog
   wire done = (cpu_inst_rdata == 32'h58000000);
   wire [15:0] addr_chk;
   assign addr_chk = done ? {switch[13:0],2'b0} : data_sram_addr[17:2];
   ```

   其中`{switch[13:0],2'b0}`是为了因为存储器的地址按字节编号，而一个字占4个字节，所以想要显示第`i`个数据时地址应为`4i`。

完整代码附文末。

上板结果如下：

![res1](figs\sort1.jpg)

![res2](figs\sort2.jpg)

![res3](figs\sort3.jpg)

![res4](figs\sort4.jpg)

可以看到数据按降序排序，排序指令运行正确。



## 结果分析

结合仿真及上板结果可得，设计的CPU正确，能正确执行指令。



## 选做部分

### 华莱士树乘法器

选做部分需要增加乘，除和取模的几条指令。以现有的知识，除法和取模都只能利用`verilog`自带的运算符进行计算，乘法则可以利用华莱士树乘法器。具体设计如下：

首先根据以下原理将32位部分积转换为16位部分积：

![booth](figs\booth.png)

根据以上公式可可以使用乘数b来对输入的被乘数a进行编码：

| $b_{i+1}$ | $b$  | $b_{i-1}$ | 编码 |
| :-------: | :--: | :-------: | :--: |
|     0     |  0   |     0     |  0   |
|     0     |  0   |     1     |  a   |
|     0     |  1   |     0     |  a   |
|     0     |  1   |     1     |  2a  |
|     1     |  0   |     0     | -2a  |
|     1     |  0   |     1     |  -a  |
|     1     |  1   |     0     |  -a  |
|     1     |  1   |     1     |  0   |

于是可以写出以下代码：

```verilog
// 构造booth编码
    // booth[i] = 3'd0对应0,3'd1时对应x,3'd2时对应2x,3'd7时对应-x,3'd6时对应-2x
    wire [2:0]  booth[15:0];
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
```

其中`booth[i] == 3'd0`时表示0，`booth[i] == 3'd1`时表示a，`booth[i] == 3'd2`时表示2a，`booth[i] == 3'd6`时表示-2a，`booth[i] == 3'd7`时表示-a。于是可得下列部分积：

```verilog
// 由booth编码构造16个相加项
    wire [63:0] add [15:0];
    wire [63:0] temp_a = {32'd0, a};
    wire [63:0] temp_not = ~temp_a + 1;          
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
```

然后使用全加器将这16位部分积不断相加，最终得到两位部分积，这两位部分积相加即得最终结果：

```verilog
// 使用全加器逐层累加
    //CSA中间量保存
    wire [63:0] temp_add [27:0];
    //例化CSA
    CSA csa_1(
        .a   (add[ 2]) ,
        .b   (add[ 1]),
        .c   (add[ 0]),
        .y1  (temp_add[ 1]),
        .y2  (temp_add[ 0])
    );
    CSA csa_2(
        .a   (add[ 5]) ,
        .b   (add[ 4]),
        .c   (add[ 3]),
        .y1  (temp_add[ 3]),
        .y2  (temp_add[ 2])
    ); 
    CSA csa_3(
        .a   (add[ 8]) ,
        .b   (add[ 7]),
        .c   (add[ 6]),
        .y1  (temp_add[ 5]),
        .y2  (temp_add[ 4])
    ); 
    CSA csa_4(
        .a   (add[11]) ,
        .b   (add[10]),
        .c   (add[ 9]),
        .y1  (temp_add[ 7]),
        .y2  (temp_add[ 6])
    ); 
    CSA csa_5(
        .a   (add[14]) ,
        .b   (add[13]),
        .c   (add[12]),
        .y1  (temp_add[ 9]),
        .y2  (temp_add[ 8])
    ); 
    CSA csa_6(
        .a   (add[15]) ,
        .b   (temp_add[ 1]),
        .c   (temp_add[ 0]),
        .y1  (temp_add[11]),
        .y2  (temp_add[10])
    ); 
    CSA csa_7(
        .a   (temp_add[ 4]),
        .b   (temp_add[ 3]),
        .c   (temp_add[ 2]),
        .y1  (temp_add[13]),
        .y2  (temp_add[12])
    ); 
    CSA csa_8(
        .a   (temp_add[ 7]),
        .b   (temp_add[ 6]),
        .c   (temp_add[ 5]),
        .y1  (temp_add[15]),
        .y2  (temp_add[14])
    ); 
    CSA csa_9(
        .a   (temp_add[ 9]),
        .b   (temp_add[ 8]),
        .c   (temp_add[10]),
        .y1  (temp_add[17]),
        .y2  (temp_add[16])
    ); 
    CSA csa_10(
        .a   (temp_add[13]),
        .b   (temp_add[12]),
        .c   (temp_add[11]),
        .y1  (temp_add[19]),
        .y2  (temp_add[18])
    ); 
    CSA csa_11(
        .a   (temp_add[15]),
        .b   (temp_add[14]),
        .c   (temp_add[16]),
        .y1  (temp_add[21]),
        .y2  (temp_add[20])
    ); 
    CSA csa_12(
        .a   (temp_add[19]),
        .b   (temp_add[18]),
        .c   (temp_add[17]),
        .y1  (temp_add[23]),
        .y2  (temp_add[22])
    ); 
    CSA csa_13(
        .a   (temp_add[22]),
        .b   (temp_add[21]),
        .c   (temp_add[20]),
        .y1  (temp_add[25]),
        .y2  (temp_add[24])
    ); 
    CSA csa_14(
        .a   (temp_add[25]),
        .b   (temp_add[24]),
        .c   (temp_add[23]),
        .y1  (temp_add[27]),
        .y2  (temp_add[26])
    ); 

    //最后一层全加器
    assign res = temp_add[27] + temp_add[26];
```

全加器代码如下：

```verilog
module CSA #(
    parameter WIDTH = 64
)(
    input       [WIDTH-1: 0]     a,
    input       [WIDTH-1: 0]     b,
    input       [WIDTH-1: 0]     c,
    output      [WIDTH-1: 0]     y1,
    output      [WIDTH-1: 0]     y2
);
    assign y1 = a ^ b ^ c;
    assign y2 = (a & b) | (b & c) | (c & a);
endmodule
```

### 无符号乘法

无符号乘法只需要将上面乘法器改为33位乘法器，将32位的乘数和被乘数高位补0后传递给33位乘法器，最后取乘法结果的低64位即可。

### 增加指令后的ALU

增加了这几条指令后，需要在ALU中增加相应的运算，最后结果的输出也需要修改。如下：

```verilog
// MUL result
wire [63:0] res;
wire [65:0] resu;
Mul_wallace mymul(
  .a(alu_src1),
  .b(alu_src2),
  .res(res)
);
Mul_33 mymul_u(
  .a({1'b0,alu_src1}),
  .b({1'b0,alu_src2}),
  .res(resu)
);
assign mul_result   = res[31:0];
assign mulh_result  = res[63:32];
assign mulhu_result = resu[63:32];

// DIV result
assign div_result  = alu_src1/alu_src2;
assign divu_result = $unsigned(alu_src1)/$unsigned(alu_src2);

// MOD result
assign mod_result  = alu_src1 % alu_src2;
assign modu_result = $unsigned(alu_src1) % $unsigned(alu_src2);

// final result mux
assign alu_result = ({32{op_add|op_sub}} & add_sub_result)
                  | ({32{op_slt       }} & slt_result)
                  | ({32{op_sltu      }} & sltu_result)
                  | ({32{op_and       }} & and_result)
                  | ({32{op_nor       }} & nor_result)
                  | ({32{op_or        }} & or_result)
                  | ({32{op_xor       }} & xor_result)
                  | ({32{op_lui       }} & lui_result)
                  | ({32{op_sll       }} & sll_result)
                  | ({32{op_srl|op_sra}} & sr_result)
                  | ({32{op_mul       }} & mul_result)
                  | ({32{op_mul_h     }} & mulh_result)
                  | ({32{op_mul_hu    }} & mulhu_result)
                  | ({32{op_div       }} & div_result)
                  | ({32{op_divu      }} & divu_result)
                  | ({32{op_mod       }} & mod_result)
                  | ({32{op_modu      }} & modu_result);
```

其中对于无符号除法和取模的计算，这里直接使用了`$unsigned`来进行无符号数运算。

### 增加指令后的mycpu_top

增加指令后也需要对`mycpu_top.v`作相应的修改，这几条指令的数据通路都和`add.w`等两个源操作数均取自寄存器堆的指令一样，所以这里不再重复。此外需要对`alu_op`和源操作数的选择信号做相应的修改，完整代码附文末。

### 测试

由于未找到对应的指令测试程序，所以未进行测试。

### 电路资源和性能

#### 电路资源

如图：

![电路资源_mul](figs\电路资源summary.png)

与没有增加乘，除，取模指令的资源使用相比，这里增加了大量`LUT`（查找表）的使用。由于我的乘法器的代码中大量使用了`assign booth[15] =  (  b[31] == 1'b0 ) ? ( (b[30] == 1'b0) ? ((b[29] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[29] == 1'b0) ? 3'd1 : 3'd2) ) :( (b[30] == 1'b0) ? ((b[29] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[29] == 1'b0) ? 3'd7 : 3'd0) ) ;`和`assign add[15] = ((booth[15] == 3'd0) ? 64'd0 : ((booth[15] == 3'd1) ? temp_a  : ((booth[15] == 3'd2) ? temp_a << 1 : ((booth[15] == 3'd7) ? temp_not  : temp_not << 1 )))) << 30;`这样的代码，所以这是正常的。

`IO`和`PLL`的使用量未发生改变，这也是正常的，因为我添加指令并没有增加输入输出端口，使用的`PLL`也都来源于`clk_pll`。

但是没有增加指令的CPU中大量使用`LUTRAM`这里却没有显示，是不是说明没有使用或是使用量很少，还有`FF`(触发器)的使用量也有所减少（按理来说应该不变或增加），对于这两点我不是很理解。

#### 性能

`cpu_clk == 20ns`时，`timing report`如下：

![20](figs\mul_20ns.png)

此时`WNS == -54.907ns`，时序严重违例。可见增加的指令对于时序的影响很大。因为乘法器是利用华莱士树算法写的，而除法和取模运算却是使用`verilog`自带的运算符，所以我猜测这主要是由于除法和取模运算导致的。

`cpu_clk == 20ns`时，`timing report`如下：
![mul_50](figs\mul_50.png)

此时的`WNS`已经为正，但是绝对值还是稍大，说明`cpu_clk == 20ns`也即频率为500MHz还不是此CPU的最佳性能，但是已经较为接近。

再略微增加`cpu_clk`至20.833ns，此时频率为48MHz，`timing report`如下：

![mul_48](figs\mul_48.png)

可以看到，此时的`WNS`已经很小，说明该CPU的工作频率约为48MHz。

再增加`cpu_clk`至`21.277ns`，此时频率为47MHz，`timing report`如下：
![mul_47](figs\mul_47ns.png)

此时的`WNS`已经为`-1.175ns`，已经造成了较小的时序违例。

终上，增加了乘，除，取模后的`CPU`的工作频率约为**48MHz**，工作周期约为**20.833ns**，与增加指令之前的CPU相比，时间性能减弱很多。

## 实验总结

本次顺利完成，但过程较为曲折。代码的设计，龙芯环境的使用已经最后的上板都较为复杂，好在最后助教发了上板流程，解决了上板方面的难题。



## 源码

由于代码环境都是龙芯环境里自带的或是助教提供的，所以这里只提供有所不同的模块代码：

### my_cpu_top.v

```verilog
module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
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
wire [31:0] inst;
reg  [31:0] pc;

wire [11:0] alu_op;
wire        load_op;
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

wire [ 5:0] op_31_26;
wire [ 3:0] op_25_22;
wire [ 1:0] op_21_20;
wire [ 4:0] op_19_15;
wire [ 4:0] rd;
wire [ 4:0] rj;
wire [ 4:0] rk;
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


wire        need_ui5;
wire        need_ui12;
wire        need_si12;
wire        need_si16;
wire        need_si20;
wire        need_si26;
wire        src2_is_4;

wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;
wire        rf_we   ;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;

wire [31:0] alu_src1   ;
wire [31:0] alu_src2   ;
wire [31:0] alu_result ;

wire [31:0] mem_result;
wire [31:0] final_result;

assign seq_pc       = pc + 32'h4;
assign nextpc       = br_taken ? br_target : seq_pc;

always @(posedge clk) begin
    if (reset) begin
        pc <= 32'h1bfffffc;     //trick: to make nextpc be 0x1c000000 during reset 
    end
    else begin
        pc <= nextpc;
    end
end

assign inst_sram_we    = 1'b0;
assign inst_sram_addr  = pc;
assign inst_sram_wdata = 32'b0;
assign inst            = inst_sram_rdata;

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

assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd : rk;
regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
    );

assign rj_value  = rf_rdata1;
assign rkd_value = rf_rdata2;

assign rj_eq_rd = (rj_value == rkd_value);
assign br_taken = (   inst_beq  &&  rj_eq_rd
                   || inst_bne  && !rj_eq_rd
                   || inst_blt  && alu_result[0]
                   || inst_bltu && alu_result[0]
                   || inst_bge  && !alu_result[0]
                   || inst_bgeu && !alu_result[0]
                   || inst_jirl
                   || inst_bl
                   || inst_b
                  ) && valid;
assign br_target = (inst_beq || inst_bne || inst_bl || inst_b || inst_blt || inst_bge || inst_bltu || inst_bgeu) 
                                                                ? (pc + br_offs)        :
                                                   /*inst_jirl*/  (rj_value + jirl_offs);

assign alu_src1 = src1_is_pc  ? pc[31:0] : rj_value;
assign alu_src2 = src2_is_imm ? imm : rkd_value;

alu u_alu(
    .alu_op     (alu_op    ),
    .alu_src1   (alu_src1  ),
    .alu_src2   (alu_src2  ),
    .alu_result (alu_result)
    );

// 由于ld/st命令需要读取/存储1个字/半字/字节，所以需要根据data_sram_addr来处理mem_result和data_sram_wdata
reg [31:0]  data_sram_rdata_temp;
reg [31:0]  data_sram_wdata_temp;

always @(*) begin
    case (data_sram_addr[1:0])
        2'b00: data_sram_rdata_temp = data_sram_rdata;
        2'b01: data_sram_rdata_temp = {8'b0,  data_sram_rdata[31: 8]};
        2'b10: data_sram_rdata_temp = {16'b0, data_sram_rdata[31:16]};
        2'b11: data_sram_rdata_temp = {24'b0, data_sram_rdata[31:24]};
    endcase
end

always @(*) begin
    if(inst_st_b) begin
        case (data_sram_addr[1:0])
            2'b00: data_sram_wdata_temp = {data_sram_rdata[31: 8], rkd_value[7:0]};
            2'b01: data_sram_wdata_temp = {data_sram_rdata[31:16], rkd_value[7:0], data_sram_rdata[7:0]};
            2'b10: data_sram_wdata_temp = {data_sram_rdata[31:24], rkd_value[7:0], data_sram_rdata[15:0]};
            2'b11: data_sram_wdata_temp = {rkd_value[7:0], data_sram_rdata[23:0]};
        endcase
    end
    else if(inst_st_h)
        data_sram_wdata_temp = data_sram_addr[1] ? {rkd_value[15:0], data_sram_rdata[15:0]}
                                                 : {data_sram_rdata[31:16], rkd_value[15:0]};
    else
        data_sram_wdata_temp = rkd_value;
end
/*always @(*) begin
    if(inst_st_w)
        data_sram_wdata_temp = rkd_value;
    else if(inst_st_h)
        data_sram_wdata_temp = {data_sram_rdata[31:16], rkd_value[15:0]};
    else if(inst_st_b)
        data_sram_wdata_temp = {data_sram_rdata[31: 8], rkd_value[7:0]};
end*/

assign data_sram_wdata = data_sram_wdata_temp;
assign data_sram_we    = mem_we && valid;
assign data_sram_addr  = alu_result;
//assign data_sram_wdata = rkd_value;

assign mem_result = inst_ld_w ? data_sram_rdata_temp :
                    inst_ld_h ? {{16{data_sram_rdata_temp[15]}}, data_sram_rdata_temp[15:0]} :
                    inst_ld_b ? {{24{data_sram_rdata_temp[7]}}, data_sram_rdata_temp[ 7:0]}  :
                    inst_ld_hu? {16'b0, data_sram_rdata_temp[15:0]}     :
                  /*inst_ld_bu*/{24'b0, data_sram_rdata_temp[ 7:0]}     ;

assign final_result = res_from_mem ? mem_result : alu_result;

assign rf_we    = gr_we && valid;
assign rf_waddr = dest;
assign rf_wdata = final_result;

// debug info generate
assign debug_wb_pc       = pc;
assign debug_wb_rf_we    = {4{rf_we}};
assign debug_wb_rf_wnum  = dest;
assign debug_wb_rf_wdata = final_result;

endmodule
```

### alu.v

```verilog
module alu(
  input  wire [11:0] alu_op,
  input  wire [31:0] alu_src1,
  input  wire [31:0] alu_src2,
  output wire [31:0] alu_result
);

wire op_add;   //add operation
wire op_sub;   //sub operation
wire op_slt;   //signed compared and set less than
wire op_sltu;  //unsigned compared and set less than
wire op_and;   //bitwise and
wire op_nor;   //bitwise nor
wire op_or;    //bitwise or
wire op_xor;   //bitwise xor
wire op_sll;   //logic left shift
wire op_srl;   //logic right shift
wire op_sra;   //arithmetic right shift
wire op_lui;   //Load Upper Immediate

// control code decomposition
assign op_add  = alu_op[ 0];
assign op_sub  = alu_op[ 1];
assign op_slt  = alu_op[ 2];
assign op_sltu = alu_op[ 3];
assign op_and  = alu_op[ 4];
assign op_nor  = alu_op[ 5];
assign op_or   = alu_op[ 6];
assign op_xor  = alu_op[ 7];
assign op_sll  = alu_op[ 8];
assign op_srl  = alu_op[ 9];
assign op_sra  = alu_op[10];
assign op_lui  = alu_op[11];

wire [31:0] add_sub_result;
wire [31:0] slt_result;
wire [31:0] sltu_result;
wire [31:0] and_result;
wire [31:0] nor_result;
wire [31:0] or_result;
wire [31:0] xor_result;
wire [31:0] lui_result;
wire [31:0] sll_result;
wire [63:0] sr64_result;
wire [31:0] sr_result;


// 32-bit adder
wire [31:0] adder_a;
wire [31:0] adder_b;
wire        adder_cin;
wire [31:0] adder_result;
wire        adder_cout;

assign adder_a   = alu_src1;
assign adder_b   = (op_sub | op_slt | op_sltu) ? ~alu_src2 : alu_src2;  //src1 - src2 rj-rk
assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0;
assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

// ADD, SUB result
assign add_sub_result = adder_result;

// SLT result
assign slt_result[31:1] = 31'b0;   //rj < rk 1
assign slt_result[0]    = (alu_src1[31] & ~alu_src2[31])
                        | ((alu_src1[31] ~^ alu_src2[31]) & adder_result[31]);

// SLTU result
assign sltu_result[31:1] = 31'b0;
assign sltu_result[0]    = ~adder_cout;

// bitwise operation
assign and_result = alu_src1 & alu_src2;
assign or_result  = alu_src1 | alu_src2;
assign nor_result = ~or_result;
assign xor_result = alu_src1 ^ alu_src2;
assign lui_result = alu_src2;

// SLL result
assign sll_result = alu_src1 << alu_src2[4:0];   //rj << ui5

// SRL, SRA result
assign sr64_result = {{32{op_sra & alu_src1[31]}}, alu_src1[31:0]} >> alu_src2[4:0]; //rj >> i5

assign sr_result   = sr64_result[31:0];

// final result mux
assign alu_result = ({32{op_add|op_sub}} & add_sub_result)
                  | ({32{op_slt       }} & slt_result)
                  | ({32{op_sltu      }} & sltu_result)
                  | ({32{op_and       }} & and_result)
                  | ({32{op_nor       }} & nor_result)
                  | ({32{op_or        }} & or_result)
                  | ({32{op_xor       }} & xor_result)
                  | ({32{op_lui       }} & lui_result)
                  | ({32{op_sll       }} & sll_result)
                  | ({32{op_srl|op_sra}} & sr_result);

endmodule
```

### soc_top_sort.v(在soc_lite_top.v的基础上修改的用于测试排序程序的顶层模块)

```verilog
`default_nettype none
`define SIMU_USE_PLL 0 //set 0 to speed up simulation
module soc_top_sort #(parameter SIMULATION=1'b0)
(
    input  wire        resetn, 
    input  wire        clk,

    //------gpio-------
    output wire [15:0] led,
    output wire [1 :0] led_rg0,
    output wire [1 :0] led_rg1,
    output wire [7 :0] num_csn,
    output wire [6 :0] num_a_gn,	//changed for N4-DDR
//    output wire [31:0] num_data,	//removed for N4-DDR
    input  wire [15:0] switch, 
//    output wire [3 :0] btn_key_col,	//removed for N4-DDR
//    input  wire [3 :0] btn_key_row,	//removed for N4-DDR
    input  wire [1 :0] btn_step
);

//debug signals
wire [31:0] debug_wb_pc;
wire [3 :0] debug_wb_rf_we;
wire [4 :0] debug_wb_rf_wnum;
wire [31:0] debug_wb_rf_wdata;

//clk and resetn
wire cpu_clk;
wire timer_clk;
reg cpu_resetn;

always @(posedge cpu_clk)
begin
    cpu_resetn <= resetn;
end

generate if(SIMULATION && `SIMU_USE_PLL==0)
begin: speedup_simulation
    assign cpu_clk   = clk;
    assign timer_clk = clk;
end
else
begin: pll
    clk_pll clk_pll
    (
        .clk_in1 (clk),
        .cpu_clk (cpu_clk),
        .timer_clk (timer_clk)
    );
end
endgenerate

//cpu inst sram
wire        cpu_inst_we;
wire [31:0] cpu_inst_addr;
wire [31:0] cpu_inst_wdata;
wire [31:0] cpu_inst_rdata;

//cpu data sram
wire        cpu_data_we;
wire [31:0] cpu_data_addr;
wire [31:0] cpu_data_wdata;
wire [31:0] cpu_data_rdata;

//data sram
wire        data_sram_en;
wire        data_sram_we;
wire [31:0] data_sram_addr;
wire [31:0] data_sram_wdata;
wire [31:0] data_sram_rdata;

//conf
wire        conf_en;
wire        conf_we;
wire [31:0] conf_addr;
wire [31:0] conf_wdata;
wire [31:0] conf_rdata;

//cpu
mycpu_top cpu(
    .clk              (cpu_clk       ),
    .resetn           (cpu_resetn    ),  //low active

    .inst_sram_we     (cpu_inst_we   ),
    .inst_sram_addr   (cpu_inst_addr ),
    .inst_sram_wdata  (cpu_inst_wdata),
    .inst_sram_rdata  (cpu_inst_rdata),
   
    .data_sram_we     (cpu_data_we   ),
    .data_sram_addr   (cpu_data_addr ),
    .data_sram_wdata  (cpu_data_wdata),
    .data_sram_rdata  (cpu_data_rdata),

    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_we   (debug_wb_rf_we   ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
);

wire done = (cpu_inst_rdata == 32'h58000000);
wire [15:0] addr_chk;
assign addr_chk = done ? {switch[13:0],2'b0} : data_sram_addr[17:2];
//inst ram
inst_ram inst_ram
(
    .clk   (cpu_clk            ),   
    .we    (cpu_inst_we        ),   
    .a     (cpu_inst_addr[17:2]),   
    .d     (cpu_inst_wdata     ),   
    .spo   (cpu_inst_rdata     )   
);

bridge_1x2 bridge_1x2(
    .clk             ( cpu_clk         ), // i, 1                 
    .resetn          ( cpu_resetn      ), // i, 1                 
	  
    .cpu_data_we     ( cpu_data_we     ), // i, 4                 
    .cpu_data_addr   ( cpu_data_addr   ), // i, 32                
    .cpu_data_wdata  ( cpu_data_wdata  ), // i, 32                
    .cpu_data_rdata  ( cpu_data_rdata  ), // o, 32                

    .data_sram_en    ( data_sram_en    ),			   
    .data_sram_we    ( data_sram_we    ), // o, 4                 
    .data_sram_addr  ( data_sram_addr  ), // o, `DATA_RAM_ADDR_LEN
    .data_sram_wdata ( data_sram_wdata ), // o, 32                
    .data_sram_rdata ( data_sram_rdata ), // i, 32                

    .conf_en         ( conf_en         ), // o, 1                 
    .conf_we         ( conf_we         ), // o, 4                 
    .conf_addr       ( conf_addr       ), // o, 32                
    .conf_wdata      ( conf_wdata      ), // o, 32                
    .conf_rdata      ( conf_rdata      )  // i, 32                
 );

//data ram
data_ram data_ram
(
    .clk   (cpu_clk            ),   
    .we    (data_sram_we & data_sram_en),   
    //.a     (data_sram_addr[17:2]),   
    .a     (addr_chk           ),
    .d     (data_sram_wdata    ),   
    .spo   (data_sram_rdata    )   
);

//confreg
confreg #(.SIMULATION(SIMULATION)) u_confreg
(
    .clk          ( cpu_clk    ),  // i, 1   
    .timer_clk    ( timer_clk  ),  // i, 1   
    .resetn       ( cpu_resetn ),  // i, 1
    
    .conf_en      ( conf_en    ),  // i, 1      
    .conf_we      ( conf_we    ),  // i, 4      
    .conf_addr    ( conf_addr  ),  // i, 32        
    .conf_wdata   ( conf_wdata ),  // i, 32         
    .conf_rdata   ( conf_rdata ),  // o, 32
         
    .led          ( led        ),  // o, 16   
    .led_rg0      ( led_rg0    ),  // o, 2      
    .led_rg1      ( led_rg1    ),  // o, 2      
    //.num_csn      ( num_csn    ),  // o, 8      
    //.num_a_gn      ( num_a_gn    ),  // o, 7	//changed for N4-DDR
    .num_csn(),
    .num_a_gn(),
//    .num_data     ( num_data   ),  // o, 32	//removed for N4-DDR
    .switch       ( switch     ),  // i, 8     
//    .btn_key_col  ( btn_key_col),  // o, 4	//removed for N4-DDR
//    .btn_key_row  ( btn_key_row),  // i, 4	//removed for N4-DDR
    .btn_step     ( btn_step   )   // i, 2   
);

wire [31:0] output_data = done ? data_sram_rdata : 0;
Segment segment(
    .clk(clk),
    .rst(~cpu_resetn),
    .output_data(output_data),
    .output_valid(8'hff),
    .an(num_csn),
    .seg(num_a_gn)
);

endmodule
```

### segment.v

```verilog
module Segment(
    input                       clk,
    input                       rst,
    input       [31:0]          output_data,
    input       [ 7:0]          output_valid,

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
```

### Mul_wallace.v

```verilog
module Mul_wallace(
    input       [31: 0]     a,
    input       [31: 0]     b,
    output      [63: 0]     res
);
    // 构造booth编码
    // booth[i] = 3'd0对应0,3'd1时对应x,3'd2时对应2x,3'd7时对应-x,3'd6时对应-2x
    wire [2:0]  booth[15:0];
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
    wire [63:0] add [15:0];
    wire [63:0] temp_a = {32'd0, a};
    wire [63:0] temp_not = ~temp_a + 1;          
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
    wire [63:0] temp_add [27:0];
    //例化CSA
    CSA csa_1(
        .a   (add[ 2]) ,
        .b   (add[ 1]),
        .c   (add[ 0]),
        .y1  (temp_add[ 1]),
        .y2  (temp_add[ 0])
    );
    CSA csa_2(
        .a   (add[ 5]) ,
        .b   (add[ 4]),
        .c   (add[ 3]),
        .y1  (temp_add[ 3]),
        .y2  (temp_add[ 2])
    ); 
    CSA csa_3(
        .a   (add[ 8]) ,
        .b   (add[ 7]),
        .c   (add[ 6]),
        .y1  (temp_add[ 5]),
        .y2  (temp_add[ 4])
    ); 
    CSA csa_4(
        .a   (add[11]) ,
        .b   (add[10]),
        .c   (add[ 9]),
        .y1  (temp_add[ 7]),
        .y2  (temp_add[ 6])
    ); 
    CSA csa_5(
        .a   (add[14]) ,
        .b   (add[13]),
        .c   (add[12]),
        .y1  (temp_add[ 9]),
        .y2  (temp_add[ 8])
    ); 
    CSA csa_6(
        .a   (add[15]) ,
        .b   (temp_add[ 1]),
        .c   (temp_add[ 0]),
        .y1  (temp_add[11]),
        .y2  (temp_add[10])
    ); 
    CSA csa_7(
        .a   (temp_add[ 4]),
        .b   (temp_add[ 3]),
        .c   (temp_add[ 2]),
        .y1  (temp_add[13]),
        .y2  (temp_add[12])
    ); 
    CSA csa_8(
        .a   (temp_add[ 7]),
        .b   (temp_add[ 6]),
        .c   (temp_add[ 5]),
        .y1  (temp_add[15]),
        .y2  (temp_add[14])
    ); 
    CSA csa_9(
        .a   (temp_add[ 9]),
        .b   (temp_add[ 8]),
        .c   (temp_add[10]),
        .y1  (temp_add[17]),
        .y2  (temp_add[16])
    ); 
    CSA csa_10(
        .a   (temp_add[13]),
        .b   (temp_add[12]),
        .c   (temp_add[11]),
        .y1  (temp_add[19]),
        .y2  (temp_add[18])
    ); 
    CSA csa_11(
        .a   (temp_add[15]),
        .b   (temp_add[14]),
        .c   (temp_add[16]),
        .y1  (temp_add[21]),
        .y2  (temp_add[20])
    ); 
    CSA csa_12(
        .a   (temp_add[19]),
        .b   (temp_add[18]),
        .c   (temp_add[17]),
        .y1  (temp_add[23]),
        .y2  (temp_add[22])
    ); 
    CSA csa_13(
        .a   (temp_add[22]),
        .b   (temp_add[21]),
        .c   (temp_add[20]),
        .y1  (temp_add[25]),
        .y2  (temp_add[24])
    ); 
    CSA csa_14(
        .a   (temp_add[25]),
        .b   (temp_add[24]),
        .c   (temp_add[23]),
        .y1  (temp_add[27]),
        .y2  (temp_add[26])
    ); 

    //最后一层全加器
    assign res = temp_add[27] + temp_add[26];
endmodule
```

### CSA.v

```verilog
module CSA #(
    parameter WIDTH = 64
)(
    input       [WIDTH-1: 0]     a,
    input       [WIDTH-1: 0]     b,
    input       [WIDTH-1: 0]     c,
    output      [WIDTH-1: 0]     y1,
    output      [WIDTH-1: 0]     y2
);
    assign y1 = a ^ b ^ c;
    assign y2 = (a & b) | (b & c) | (c & a);
endmodule

```

### Mul_33.v

```verilog
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

    //assign res = temp_res[63:0]
endmodule
```

### alu_plus.v

```verilog
module alu_plus(
  input  wire [18:0] alu_op,
  input  wire [31:0] alu_src1,
  input  wire [31:0] alu_src2,
  output wire [31:0] alu_result
);

wire op_add;   //add operation
wire op_sub;   //sub operation
wire op_slt;   //signed compared and set less than
wire op_sltu;  //unsigned compared and set less than
wire op_and;   //bitwise and
wire op_nor;   //bitwise nor
wire op_or;    //bitwise or
wire op_xor;   //bitwise xor
wire op_sll;   //logic left shift
wire op_srl;   //logic right shift
wire op_sra;   //arithmetic right shift
wire op_lui;   //Load Upper Immediate
wire op_mul;
wire op_mul_h;
wire op_mul_hu;
wire op_div;
wire op_divu;
wire op_mod;
wire op_modu;

// control code decomposition
assign op_add   = alu_op[ 0];
assign op_sub   = alu_op[ 1];
assign op_slt   = alu_op[ 2];
assign op_sltu  = alu_op[ 3];
assign op_and   = alu_op[ 4];
assign op_nor   = alu_op[ 5];
assign op_or    = alu_op[ 6];
assign op_xor   = alu_op[ 7];
assign op_sll   = alu_op[ 8];
assign op_srl   = alu_op[ 9];
assign op_sra   = alu_op[10];
assign op_lui   = alu_op[11];
assign op_mul   = alu_op[12];
assign op_mul_h = alu_op[13];
assign op_mul_hu= alu_op[14];
assign op_div   = alu_op[15];
assign op_divu  = alu_op[16];
assign op_mod   = alu_op[17];
assign op_modu  = alu_op[18];

wire [31:0] add_sub_result;
wire [31:0] slt_result;
wire [31:0] sltu_result;
wire [31:0] and_result;
wire [31:0] nor_result;
wire [31:0] or_result;
wire [31:0] xor_result;
wire [31:0] lui_result;
wire [31:0] sll_result;
wire [63:0] sr64_result;
wire [31:0] sr_result;
wire [31:0] mul_result;
wire [31:0] mulh_result;
wire [31:0] mulhu_result;
wire [31:0] div_result;
wire [31:0] divu_result;
wire [31:0] mod_result;
wire [31:0] modu_result;


// 32-bit adder
wire [31:0] adder_a;
wire [31:0] adder_b;
wire        adder_cin;
wire [31:0] adder_result;
wire        adder_cout;

assign adder_a   = alu_src1;
assign adder_b   = (op_sub | op_slt | op_sltu) ? ~alu_src2 : alu_src2;  //src1 - src2 rj-rk
assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0;
assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

// ADD, SUB result
assign add_sub_result = adder_result;

// SLT result
assign slt_result[31:1] = 31'b0;   //rj < rk 1
assign slt_result[0]    = (alu_src1[31] & ~alu_src2[31])
                        | ((alu_src1[31] ~^ alu_src2[31]) & adder_result[31]);

// SLTU result
assign sltu_result[31:1] = 31'b0;
assign sltu_result[0]    = ~adder_cout;

// bitwise operation
assign and_result = alu_src1 & alu_src2;
assign or_result  = alu_src1 | alu_src2;
assign nor_result = ~or_result;
assign xor_result = alu_src1 ^ alu_src2;
assign lui_result = alu_src2;

// SLL result
assign sll_result = alu_src1 << alu_src2[4:0];   //rj << ui5

// SRL, SRA result
assign sr64_result = {{32{op_sra & alu_src1[31]}}, alu_src1[31:0]} >> alu_src2[4:0]; //rj >> i5

assign sr_result   = sr64_result[31:0];

// MUL result
wire [63:0] res;
wire [65:0] resu;
Mul_wallace mymul(
  .a(alu_src1),
  .b(alu_src2),
  .res(res)
);
Mul_33 mymul_u(
  .a({1'b0,alu_src1}),
  .b({1'b0,alu_src2}),
  .res(resu)
);
assign mul_result   = res[31:0];
assign mulh_result  = res[63:32];
assign mulhu_result = resu[63:32];

// DIV result
assign div_result  = alu_src1/alu_src2;
assign divu_result = $unsigned(alu_src1)/$unsigned(alu_src2);

// MOD result
assign mod_result  = alu_src1 % alu_src2;
assign modu_result = $unsigned(alu_src1) % $unsigned(alu_src2);

// final result mux
assign alu_result = ({32{op_add|op_sub}} & add_sub_result)
                  | ({32{op_slt       }} & slt_result)
                  | ({32{op_sltu      }} & sltu_result)
                  | ({32{op_and       }} & and_result)
                  | ({32{op_nor       }} & nor_result)
                  | ({32{op_or        }} & or_result)
                  | ({32{op_xor       }} & xor_result)
                  | ({32{op_lui       }} & lui_result)
                  | ({32{op_sll       }} & sll_result)
                  | ({32{op_srl|op_sra}} & sr_result)
                  | ({32{op_mul       }} & mul_result)
                  | ({32{op_mul_h     }} & mulh_result)
                  | ({32{op_mul_hu    }} & mulhu_result)
                  | ({32{op_div       }} & div_result)
                  | ({32{op_divu      }} & divu_result)
                  | ({32{op_mod       }} & mod_result)
                  | ({32{op_modu      }} & modu_result);

endmodule
```

### mycpu_top_plus

```verilog
module mycpu_top_plus(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
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
wire [31:0] inst;
reg  [31:0] pc;

wire [18:0] alu_op;
wire        load_op;
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

wire [ 5:0] op_31_26;
wire [ 3:0] op_25_22;
wire [ 1:0] op_21_20;
wire [ 4:0] op_19_15;
wire [ 4:0] rd;
wire [ 4:0] rj;
wire [ 4:0] rk;
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

wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;
wire        rf_we   ;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;

wire [31:0] alu_src1   ;
wire [31:0] alu_src2   ;
wire [31:0] alu_result ;

wire [31:0] mem_result;
wire [31:0] final_result;

assign seq_pc       = pc + 32'h4;
assign nextpc       = br_taken ? br_target : seq_pc;

always @(posedge clk) begin
    if (reset) begin
        pc <= 32'h1bfffffc;     //trick: to make nextpc be 0x1c000000 during reset 
    end
    else begin
        pc <= nextpc;
    end
end

assign inst_sram_we    = 1'b0;
assign inst_sram_addr  = pc;
assign inst_sram_wdata = 32'b0;
assign inst            = inst_sram_rdata;

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

assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd : rk;
regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
    );

assign rj_value  = rf_rdata1;
assign rkd_value = rf_rdata2;

assign rj_eq_rd = (rj_value == rkd_value);
assign br_taken = (   inst_beq  &&  rj_eq_rd
                   || inst_bne  && !rj_eq_rd
                   || inst_blt  && alu_result[0]
                   || inst_bltu && alu_result[0]
                   || inst_bge  && !alu_result[0]
                   || inst_bgeu && !alu_result[0]
                   || inst_jirl
                   || inst_bl
                   || inst_b
                  ) && valid;
assign br_target = (inst_beq || inst_bne || inst_bl || inst_b || inst_blt || inst_bge || inst_bltu || inst_bgeu) 
                                                                ? (pc + br_offs)        :
                                                   /*inst_jirl*/  (rj_value + jirl_offs);

assign alu_src1 = src1_is_pc  ? pc[31:0] : rj_value;
assign alu_src2 = src2_is_imm ? imm : rkd_value;

alu_plus u_alu_plus(
    .alu_op     (alu_op    ),
    .alu_src1   (alu_src1  ),
    .alu_src2   (alu_src2  ),
    .alu_result (alu_result)
    );

// 由于ld/st命令需要读取/存储1个字/半字/字节，所以需要根据data_sram_addr来处理mem_result和data_sram_wdata
reg [31:0]  data_sram_rdata_temp;
reg [31:0]  data_sram_wdata_temp;

always @(*) begin
    case (data_sram_addr[1:0])
        2'b00: data_sram_rdata_temp = data_sram_rdata;
        2'b01: data_sram_rdata_temp = {8'b0,  data_sram_rdata[31: 8]};
        2'b10: data_sram_rdata_temp = {16'b0, data_sram_rdata[31:16]};
        2'b11: data_sram_rdata_temp = {24'b0, data_sram_rdata[31:24]};
    endcase
end

always @(*) begin
    if(inst_st_b) begin
        case (data_sram_addr[1:0])
            2'b00: data_sram_wdata_temp = {data_sram_rdata[31: 8], rkd_value[7:0]};
            2'b01: data_sram_wdata_temp = {data_sram_rdata[31:16], rkd_value[7:0], data_sram_rdata[7:0]};
            2'b10: data_sram_wdata_temp = {data_sram_rdata[31:24], rkd_value[7:0], data_sram_rdata[15:0]};
            2'b11: data_sram_wdata_temp = {rkd_value[7:0], data_sram_rdata[23:0]};
        endcase
    end
    else if(inst_st_h)
        data_sram_wdata_temp = data_sram_addr[1] ? {rkd_value[15:0], data_sram_rdata[15:0]}
                                                 : {data_sram_rdata[31:16], rkd_value[15:0]};
    else
        data_sram_wdata_temp = rkd_value;
end
/*always @(*) begin
    if(inst_st_w)
        data_sram_wdata_temp = rkd_value;
    else if(inst_st_h)
        data_sram_wdata_temp = {data_sram_rdata[31:16], rkd_value[15:0]};
    else if(inst_st_b)
        data_sram_wdata_temp = {data_sram_rdata[31: 8], rkd_value[7:0]};
end*/

assign data_sram_wdata = data_sram_wdata_temp;
assign data_sram_we    = mem_we && valid;
assign data_sram_addr  = alu_result;
//assign data_sram_wdata = rkd_value;

assign mem_result = inst_ld_w ? data_sram_rdata_temp :
                    inst_ld_h ? {{16{data_sram_rdata_temp[15]}}, data_sram_rdata_temp[15:0]} :
                    inst_ld_b ? {{24{data_sram_rdata_temp[7]}}, data_sram_rdata_temp[ 7:0]}  :
                    inst_ld_hu? {16'b0, data_sram_rdata_temp[15:0]}     :
                  /*inst_ld_bu*/{24'b0, data_sram_rdata_temp[ 7:0]}     ;

assign final_result = res_from_mem ? mem_result : alu_result;

assign rf_we    = gr_we && valid;
assign rf_waddr = dest;
assign rf_wdata = final_result;

// debug info generate
assign debug_wb_pc       = pc;
assign debug_wb_rf_we    = {4{rf_we}};
assign debug_wb_rf_wnum  = dest;
assign debug_wb_rf_wdata = final_result;

endmodule
```

