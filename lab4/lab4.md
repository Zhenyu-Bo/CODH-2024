# <center> LabH4 - 流水线CPU设计

<center> PB22081571 薄震宇

[TOC]


## 实验目的

在单周期CPU的基础上，实现流水线CPU，以提高CPU的性能。在设计流水线CPU的过程中，加深对`LA32R CPU`的结构和工作原理的理解。

## 实验内容

1. 添加级间寄存器，得到不考虑相关引发的冲突的简单流水线CPU
2. 添加forwarding模块和Hazard模块，得到能正确处理各种情况的CPU
3. 添加乘除法及取模运算指令

## 实验原理

### 添加级间寄存器

将原先单周期CPU的一个周期即一条指令的执行过程拆分为以下五级：

- IF（Instruction Fetch，取指令），核心耗时为指令存储器的读取。
- ID（Instruction Decode，译码），包含将指令翻译为各个控制信号并读取寄存器堆，核心耗时为寄存器堆的读取。
- EX（Execution，执行），由算术逻辑单元 ALU 进行运算，得到指令的计算结果，同时计算可能需要的跳转地址，核心耗时为 ALU 计算。
- MEM（Memory，访存），对数据存储器进行读取或写入，核心耗时为数据存储器的读写。
- WB（Write Back，回写），将需要写回寄存器堆的数据写入。注意此处耗时与数据存储器写入一样，只考虑准备的时间，因为实际写入是在时钟上升沿进行的。

在每两级之间添加级间寄存器，即得到结果之后不立即传给下一部分继续执行，而是先存储到级间寄存器中，使用时再从寄存器中获取。下面是拆分后的数据通路：

![级间寄存器](F:\CSClasses\CODH\Lab\lab4\figs\级间寄存器.png)

不仅是每个周期计算出的数据需要，控制信号也存储在级间寄存器中，在`ID`段完成译码后，需要将每个周期需要用到的控制信号存储起来。每一级结束后，就不需要将这一级的控制信号再往后传递，所以控制信号的传递是递减的。下面是含控制信号的数据通路：

![级间寄存器加控制信号](F:\CSClasses\CODH\Lab\lab4\figs\级间寄存器加控制信号.png)

添加的级间寄存器如下：

```verilog
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
```

由于对级间寄存器的处理代码过长，所以这里不在粘贴，详见文末的`mycpu_top.v`。

添加了级间寄存器后，将原来单周期CPU代码中相应的信号替换为对应的级间寄存器即可。

### 修改寄存器模块

为了处理结构相关，需要将寄存器堆设置为写优先，即同时对同一个非零寄存器读写时需要读取正在写入的数据，具体来说需要修改的只有下面这两行代码：

```verilog
//READ OUT 1(write first)
assign rdata1 = (raddr1==5'b0) ? 32'b0 : rf[raddr1];
//READ OUT 2(write first)
assign rdata2 = (raddr2==5'b0) ? 32'b0 : rf[raddr2];
```

修改为下面的逻辑：

```verilog
//READ OUT 1(write first)
assign rdata1 = (raddr1==5'b0) ? 32'b0 : ((we && waddr == raddr1) ? wdata : rf[raddr1]);
//READ OUT 2(write first)
assign rdata2 = (raddr2==5'b0) ? 32'b0 : ((we && waddr == raddr2) ? wdata : rf[raddr2]);
```

### 添加forward模块

forward模块用于处理不考虑`load-use hazard`（读取 - 使用冒险）情况的数据相关，它用于处理后一条指令需要用到的数据由前一条指令计算出，但在需要使用的时候前一条指令还没有将结果写回的情况，此时需要直接从结果所在的寄存器获取数据。

当同时满足以下两个条件时，需要使用forward前递的数据：

- MEM/WB 段写使能为 1，且写入非 x0；
- EX 段某读寄存器地址等于 MEM/WB 段的写地址；

数据通路如下：

![forward](F:\CSClasses\CODH\Lab\lab4\figs\forward.png)

由于我将这一部分的代码写在了`mycpu_top.v`的内部而没有单独作为一个模块来写，所以在文末的代码中可能难以找到，所以这里我再粘贴一遍：

```verilog
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

assign alu_src1 = ID_EX_src1_is_pc  ? ID_EX_pc  : forwarda;
assign alu_src2 = ID_EX_src2_is_imm ? ID_EX_imm : forwardb;
```

其中`forwarda`和`forwardb`分别表示在执行当前命令时真正需要使用的两个寄存器a，b的值。

### 添加Hazard模块

#### load-use hazard

对于`load-use hazard`的情况，由于读取在 MEM 段结束才能完成，这时无法直接前递， 而是必须等待一个周期。如果直接前递，则 EX 段的最大延迟就会再加上存储器的读取延迟，这是我们不能接受的。所以若 Load-Use 冒险发生，就需要插入一个气泡，也即假装两条指令间有一个 nop 指令。为了达到插入气泡的效果，原本的下一条指令，ID 阶段的指令将被忽略，也即在下一时钟上升沿**清空** ID/EX 段间寄存器；而还未执行的 IF 前（PC）、IF/ID 段间寄存器需要**停驻**一个周期，让气泡在它们之前通过。

判断条件如下：

- EX 段的指令为读取内存的指令；
- EX 段指令写入寄存器地址非零；
- ID 段某读寄存器地址等于 EX 段的写地址。

数据通路如下：

![load-use](F:\CSClasses\CODH\Lab\lab4\figs\load-use-hazard.png)

#### Branch Hazard

当跳转指令需要跳转即`br_taken`为真时，IF/ID 段间寄存器与 ID/EX 段间寄存器都是按照加4计算得到的错误的地址，故需要清空。

一个简易版本的`Branch Hazard`如下：

![simple_br_hazard](F:\CSClasses\CODH\Lab\lab4\figs\br_hazard_simple.png)

其中`br_taken`在EX段被计算出来，为真时表示需要跳转，为假时不需要跳转。`dFlush`和`eFlush`分别为清空IF/ID 段间寄存器与 ID/EX 段间寄存器控制信号。

我将以上两种情况的处理都集成到了`Hazard.v`中（见文末）。

## 实验结果

### 仿真结果

顺利通过39条指令的测试程序，结果如下：

![test_39](F:\CSClasses\CODH\Lab\lab4\figs\仿真_39.png)

### 上板结果

#### 指令测试程序

顺利通过简化版的39条指令的测试程序，结果如下：

![test39](F:\CSClasses\CODH\Lab\lab4\figs\test39.jpg)

#### 排序程序

和上次实验相同，对`soc_lite_top.v`作以下修改：

1. 增加数码管显示模块并且修改`num_a_gn`，`num_csn`使他们显示数据寄存器读出的数据而不显示`num_data`

2. 增加排序结束标志指令，也即增加死循环，当执行到这条指令时，说明排序已经完成，此时将访问数据存储器的地址设置为开关输入的地址，在此之前访问数据存储器的地址由`mycpu_top.v`的输出决定。代码如下：

   ```verilog
   wire done = (cpu_inst_rdata == 32'h58000000); // 排序程序末尾的死循环标志排序完成
   wire [15:0] addr_chk;
   assign addr_chk = done ? {switch[13:0],2'b0} : data_sram_addr[17:2];
   ```

   其中`{switch[13:0],2'b0}`是为了因为存储器的地址按字节编号，而一个字占4个字节，所以想要显示第`i`个数据时地址应为`4i`。

   由于流水线CPU在执行最后的`58000000`时不会立即跳转，而是需要再经过两个周期才能得到是否需要跳转，此时会向后继续读取指令，所以我将排序程序末尾添加3条`58000000`指令以标志排序完成。

3. 修改`led = {16{done}}`，排序完成时LED灯全亮。

修改后成功运行排序程序，下面是前几项的数据（结果为降序，开关输入为下标，LED灯全亮表示排序完成）：

![sort_0](F:\CSClasses\CODH\Lab\lab4\figs\sort_0.jpg)

![sort_1](F:\CSClasses\CODH\Lab\lab4\figs\sort_1.jpg)

![sort_2](F:\CSClasses\CODH\Lab\lab4\figs\sort_2.jpg)

![sort_3](F:\CSClasses\CODH\Lab\lab4\figs\sort_3.jpg)

### 电路资源和性能

#### 电路资源

电路资源使用情况如下图：

![utilization](F:\CSClasses\CODH\Lab\lab4\figs\资源.png)

该CPU主要使用了`LUT`（查找表）和`FF`（触发器），因为代码中实现了ALU的大部分功能，也即实现了很多逻辑函数，所以`LUT` 的大量使用是必然的。

再看一看上次实验的单周期CPU的资源使用情况：

![单周期](F:\CSClasses\CODH\Lab\mycpu_env\figs\电路资源.png)

与单周期CPU相比，各项资源的使用均大量减少。

#### 电路性能

`cpu_clk == 10ns`即频率为100MHz时，`timing report`如下：

![10ns](F:\CSClasses\CODH\Lab\lab4\figs\10ns.png)

此时`WNS == 6.606ns`，还很大，说明电路性能不止于100MHz。

减小`cpu_clk`至5ns，即频率为200MHz时，`timing report`如下：

![5ns](F:\CSClasses\CODH\Lab\lab4\figs\5ns.png)

此时WNS为负担绝对值并不是很大。

再略微增加`cpu_clk`至5.556ns，即频率为180MHz时，`timing report`如下：

![5.556ns](F:\CSClasses\CODH\Lab\lab4\figs\5.556ns.png)

此时WNS为正且接近于0，说明设计的流水线CPU的工作频率约为**180MHz**，工作的时钟周期约为**5.556ns**。

上次实验设计的单周期CPU的性能约为66.7MHz，所以流水线CPU的性能约为单周期CPU的性能的3倍，理论上五级流水线CPU的性能最大可达单周期CPU性能的5倍，说明设计的流水线CPU的性能还不是很好。



## 选做部分

使用的仍然是上次实验的方法——用华莱士树算法设计了乘法器，除法和取模运算用`verilog`自带的运算符实现。但是由于没有测试程序所以未进行测试。

### 乘法器设计

选做部分需要增加乘，除和取模的几条指令。以现有的知识，除法和取模都只能利用`verilog`自带的运算符进行计算，乘法则可以利用华莱士树乘法器。具体设计如下：

首先根据以下原理将32位部分积转换为16位部分积：

![booth](F:\CSClasses\CODH\Lab\mycpu_env\figs\booth.png)

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

然后可以构造booth编码，由于对15位booth编码进行赋值的代码过长，所以下面以booth[15]为例（完整代码附文末）：

```verilog
assign booth[15] =  (  b[31] == 1'b0 ) ? ( (b[30] == 1'b0) ? ((b[29] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[29] == 1'b0) ? 3'd1 : 3'd2) ) : ( (b[30] == 1'b0) ? ((b[29] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[29] == 1'b0) ? 3'd7 : 3'd0) ) ;
```

其中`booth[i] == 3'd0`时表示0，`booth[i] == 3'd1`时表示a，`booth[i] == 3'd2`时表示2a，`booth[i] == 3'd6`时表示-2a，`booth[i] == 3'd7`时表示-a。于是可得部分积，依然是以`add[15]`为例：

```verilog
assign add[15] = ((booth[15] == 3'd0) ? 64'd0 : ((booth[15] == 3'd1) ? temp_a  : ((booth[15] == 3'd2) ? temp_a << 1 : ((booth[15] == 3'd7) ? temp_not  : temp_not << 1 )))) << 30;
```

然后使用全加器将16位部分积不断相加，最终得到两位部分积，这两位部分积相加即得最终结果。

全加器及乘法器完整代码附文末。

### 电路资源

电路资源如下：

![utilization_mul](F:\CSClasses\CODH\Lab\lab4\figs\资源_mul.png)

与未添加乘除取模运算的`mycpu_top.v`相比，`LUT`（查找表）的使用大量增加，这也是显然的，因为我的乘法器中大量使用了诸如`assign booth[15] =  (  b[31] == 1'b0 ) ? ( (b[30] == 1'b0) ? ((b[29] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[29] == 1'b0) ? 3'd1 : 3'd2) ) : ( (b[30] == 1'b0) ? ((b[29] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[29] == 1'b0) ? 3'd7 : 3'd0) ) ;`的代码。此外`FF`（触发器）的使用也略微有所增加，增加了运算后资源消耗增加也是合乎情理的。不过这里却没有再显示LUTRAM这一在之前版本的CPU中使用量较大的资源，我对此并不是很理解。

### 电路性能

`cpu_clk == 10ns`时，`timing report`如下：

![10ns](F:\CSClasses\CODH\Lab\lab4\figs\10nsmul.png)

可以看到，此时`WNS == -65.221ns`，时序严重违例。

`cpu_clk == 50ns`时，`timing report`如下：

![50ns_mul](F:\CSClasses\CODH\Lab\lab4\figs\50nsmul.png)

此时WNS为正且绝对值较大。

`cpu_clk == 40ns`时，`timing report`如下：

![40nsmul](F:\CSClasses\CODH\Lab\lab4\figs\40nsmul.png)

此时WNS为负。

`cpu_clk == 42.5ns`时，`timing report`如下：

![42.5ns](F:\CSClasses\CODH\Lab\lab4\figs\42.5nsmul.png)

此时WNS虽然为负但是已经接近于0。

`cpu_clk == 43ns`时，`timing report`如下：

![43ns](F:\CSClasses\CODH\Lab\lab4\figs\43nsmul.png)

此时WNS为正且接近于0，说明添加了乘除取模运算后的CPU的工作时钟周期约为43ns，工作频率约为23.256MHz。

这个性能远低于未添加乘除取模运算的版本，原因应是除法和取模运算都使用了`verilog`自带的运算符而未做优化，导致EX段的延迟远大于其他几段。而流水线CPU的性能取决于延迟最长的阶段，所以导致性能降低过多。



## 实验总结

总的来说这次的实验并不困难，主要工作在于添加级间寄存器，forward模块和Hazard模块，逻辑上都较为简单，但在单周期CPU代码的基础上修改时，总是容易忘记修改某些信号或是使用上有错误，带来了不少麻烦。此外，起初我根据龙芯的CPU设计实战中要求使用了块式存储器，要比分布式存储器难以处理，这也给我带来了不少麻烦，后来换用了分布式存储器解决了问题。



## 源码

由于代码环境都是龙芯环境里自带的或是助教提供的，所以这里只提供有所不同的模块代码：

### mycpu_top.v

```verilog
module mycpu_top(
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
Decoder cpu_decoder(
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

alu u_alu(
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
```

### Decoder.v

```verilog
module Decoder(
    input           [31: 0]         inst,

    output          [11: 0]         alu_op,
    output          [31: 0]         imm,
    output          [ 0: 0]         src1_is_pc,
    output          [ 0: 0]         src2_is_imm,
    output          [ 0: 0]         res_from_mem,
    //output          [ 0: 0]         dst_is_r1,
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
assign gr_we         = (~inst_st_w & ~inst_st_b & ~inst_st_h &
                       ~inst_beq  & ~inst_bne  & ~inst_b    & ~inst_blt & ~inst_bge & ~inst_bltu & ~inst_bgeu);
assign mem_we        = (inst_st_w  | inst_st_h  | inst_st_b);
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
assign inst_kind[63:39] = 25'b0;

endmodule
```

### Hazard.v

```verilog
module Hazard(
    input           [ 4: 0]         ID_raddr1,
    input           [ 4: 0]         ID_raddr2,
    input           [ 4: 0]         EX_dest,
    input           [ 0: 0]         EX_mem_read,
    input           [ 0: 0]         EX_rf_we,
    input           [ 0: 0]         br_taken,

    output  reg     [ 0: 0]         dStall,
    output  reg     [ 0: 0]         dFlush,
    output  reg     [ 0: 0]         eStall,
    output  reg     [ 0: 0]         eFlush,
    output  reg     [ 0: 0]         fStall
);
    always @(*) begin
        dStall = 0;
        dFlush = 0;
        eStall = 0;
        eFlush = 0;
        fStall = 0;
        if(EX_mem_read && EX_rf_we && (EX_dest == ID_raddr1 || EX_dest == ID_raddr2) && EX_dest) begin
            eFlush = 1; // 清空ID_EX段间寄存器
            dStall = 1; // 暂停IF_ID段
            fStall = 1; // 暂停PC
        end
        else if(br_taken) begin
            eFlush = 1; // 清空ID_EX段间寄存器
            dFlush = 1; // 清空IF_ID段间寄存器
        end
    end
endmodule
```

### regfile.v

```verilog
module regfile(
    input  wire        clk,
    // READ PORT 1
    input  wire [ 4:0] raddr1,
    output wire [31:0] rdata1,
    // READ PORT 2
    input  wire [ 4:0] raddr2,
    output wire [31:0] rdata2,
    // WRITE PORT
    input  wire        we,       //write enable, HIGH valid
    input  wire [ 4:0] waddr,
    input  wire [31:0] wdata
);
reg [31:0] rf[31:0];

//WRITE
always @(posedge clk) begin
    if (we) rf[waddr] <= wdata;
end

//READ OUT 1(write first)
assign rdata1 = (raddr1==5'b0) ? 32'b0 : ((we && waddr == raddr1) ? wdata : rf[raddr1]);

//READ OUT 2(write first)
assign rdata2 = (raddr2==5'b0) ? 32'b0 : ((we && waddr == raddr2) ? wdata : rf[raddr2]);

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

### soc_top_sort.v(在soc_lite_top.v的基础上修改以运行排序程序)

```verilog
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
/*reg done;
initial begin
    done <= 0;
end
always @(posedge cpu_clk) begin
    if(cpu_inst_rdata == 32'h58000000 && done == 0) begin
        done <= 1;
    end
end*/
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
         
    //.led          ( led        ),  // o, 16   
    .led(),
    .led_rg0      ( led_rg0    ),  // o, 2      
    .led_rg1      ( led_rg1    ),  // o, 2      
    //.num_csn      ( num_csn    ),  // o, 8      
    //.num_a_gn      ( num_a_gn    ),  // o, 7	//changed for N4-DDR
    .num_csn(),
    .num_a_gn(),
//    .num_data     ( num_data   ),  // o, 32	//removed for N4-DDR
    .switch       ( switch[7:0]     ),  // i, 8     
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

assign led = {16{done}};

endmodule
```

### Segment.v

```verilog
module Segment(
   input                       clk,
   input                       rst,
   input       [31:0]          output_data,
   input       [ 7:0]          output_valid,
   output  reg [ 7:0]          an,
   output  reg [ 6:0]          seg
);
reg [31:0]  counter;
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

### mycpu_top_plus.v

```verilog
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
reg [18: 0] ID_EX_alu_op;
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
        ID_EX_alu_op        <= 19'h0;
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
```

### Decoder_plus.v

```verilog
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
wire [32:0] alu_src1_u = {1'b0,alu_src1};
wire [32:0] alu_src2_u = {1'b0,alu_src2};
wire [65:0] resu;
Mul_wallace mymul(
  .a(alu_src1),
  .b(alu_src2),
  .res(res)
);
Mul_33 mymul_u(
  .a(alu_src1_u),
  .b(alu_src2_u),
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

    //assign res = temp_res[63:0];
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

