# Lab 1 运算器与存储器

## ALU与RegFile

### ALU

#### 代码实现

由于可以使用`verilog`自带的运算符，所以`ALU`的实现较为简单，只需要用一个`case`语句根据操作码返回结果即可。其中无符号数的比较没有直接的运算符，我采取的方法是：`src0 < src1`当且仅当`src0`首位为0而`src1`首位为1或是二者首位相同但是按有符号数计算时`src0 < src1`。以下为代码实现：

```verilog
module ALU(
    input               [31: 0]    src0,src1,
    input               [ 3: 0]    op,
    output      reg     [31: 0]    res
);
    wire [31: 0]    sub_res = src0 - src1;
    always @(*) begin
        case (op)
            4'b0000: res = src0 + src1;
            4'b0001: res = src0 - src1;
            4'b0010: res = sub_res[31] ? 32'b1 : 32'b0;
            // 无符号比较时，src0 < src1当且仅当src0首位为0，src1首位为1或二者首位相同的情况下res[31] = 1
            4'b0011: res = ( (~src0[31] & src1[31]) | (((src0[31] & src1[31]) | (~src0[31] & ~src1[31])) & sub_res[31]) ) ? 32'b1 : 32'b0;
            //4'b0011: res = ($unsigned(src0) < $unsigned(src1)) ? 32'b1 : 32'b0;
            4'b0100: res = src0 & src1;
            4'b0101: res = src0 | src1;
            4'b0110: res = ~(src0 | src1);
            4'b0111: res = src0 ^ src1;
            4'b1000: res = src0 << src1[4 : 0];
            4'b1001: res = src0 >> src1[4 : 0];
            4'b1010: res = src0 >>> src1[4 : 0];
            4'b1011: res = src1;
            default: res = 32'b0;
        endcase
    end

endmodule
```

#### RTL电路图

![ALU_RTL](F:\CSClasses\CODH\Lab\lab1\figs\ALU_RTL.png)

#### 功能仿真

![ALU功能仿真](F:\CSClasses\CODH\Lab\lab1\figs\ALU_功能仿真 1.png)

![ALU功能仿真](F:\CSClasses\CODH\Lab\lab1\figs\ALU_功能仿真2.png)

可以看出各种结果计算均正确，说明ALU设计正确。

#### 电路资源

![ALU资源](F:\CSClasses\CODH\Lab\lab1\figs\ALU_hierarchy.png)

![ALU资源](F:\CSClasses\CODH\Lab\lab1\figs\ALU_summary.png)

可以看出ALU模块使用了大量查找表，对IO端口的使用率也很高。



### RegFile

#### 代码实现

`RegFile`的实现关键有以下几点：

1. 0号寄存器需要初始化为0。
2. 写入数据时如果地址为0，则无法写入。
3. 同时读写时，写优先，将要写入的数据赋给数据读取端口即可。

```verilog
module RegFile(
    input                   clk,
    input       [ 4: 0]     ra0,ra1,
    output      [31: 0]     rd0,rd1,
    input       [ 4: 0]     wa,
    input       [31: 0]     wd,
    input                   we
);
    reg [31: 0] x[31: 0];

    initial begin
        x[0] = 32'b0; // 0号寄存器初始化为0
    end

    always @(posedge clk) begin
        if(we && wa)
            x[wa] <= wd; // we有效且wa不为0时写入数据
    end

    assign rd0 = ((ra0 == wa) && we && wa) ? wd : x[ra0]; // 读端口0，同时读写且wa不为0时读取写优先，读取要写入的数据
    assign rd1 = ((ra1 == wa) && we && wa) ? wd : x[ra1]; // 读端口1
endmodule
```

#### RTL电路图

![RF_RTL](F:\CSClasses\CODH\Lab\lab1\figs\RF_RTL.png)

#### 功能仿真

![RF仿真](F:\CSClasses\CODH\Lab\lab1\figs\RF_功能仿真.png)

可以看出`RegFile`的各项要求（0号寄存器恒为0，读模式为写优先）均得到了满足。

#### 电路资源

![RF资源](F:\CSClasses\CODH\Lab\lab1\figs\RF_utilization_hierarchy.png)

![RF资源](F:\CSClasses\CODH\Lab\lab1\figs\RF_utilization_summary.png)





## 比较分布式存储器与块式存储器

分布式存储器与块式存储器的主要区别为读取数据的模式不同，前者为异步读取，后者为同步读取（也就是说读操作需要一个周期）。

下面通过简单的例化这两种存储器后进行时序仿真和查看电路资源来比较他们的特性。

#### 时序仿真

分布式存储器仿真结果如下：

![dist仿真](F:\CSClasses\CODH\Lab\lab1\figs\dist时序仿真.png)

可以看出读取数据时有很多的杂信号。

以下为有效数据中的部分无效信号：

![dist杂信号](F:\CSClasses\CODH\Lab\lab1\figs\dist时序仿真杂信号.png)



块式存储器仿真结果如下：
![blk仿真](F:\CSClasses\CODH\Lab\lab1\figs\blk时序仿真.png)

可以看出块式存储器的读取没有杂信号，但是花费的时间很长，在`ena == 1 && wea == 0`后过来一段时间`dout`才发生改变。所以后续再使用块式存储器实现`SRT`时，需要为读取数据增加周期数。



#### 电路资源

分布式存储器消耗的电路资源如下：

![dist资源](F:\CSClasses\CODH\Lab\lab1\figs\dist_utilization_hierarchy.png)

![dist资源](F:\CSClasses\CODH\Lab\lab1\figs\dist_utilization_summary.png)

块式存储器消耗的电路资源如下：

![块式资源](F:\CSClasses\CODH\Lab\lab1\figs\SRT_blk_utilization_h.png)

![blk资源](F:\CSClasses\CODH\Lab\lab1\figs\SRT_blk_summary.png)

可以看出，相对于分布式存储器，例化的模块块式存储器增加了一个`BRAM`（块式存储器），减少了很多其他资源的消耗。



## SRT

### 逻辑设计

#### 状态转换

首先简述实验的基本思路如下：传统的冒泡排序是通过两层循环，每一次内层循环都将未排过序的数中最小（大）的数交换到最后，外层循环执行次数为数组长度（设为n）减1，以将n-1个最大（小）的数依次放到最后。实验中对算法做了以下两点优化：

1. 使用一个变量`swapped`来记录一趟排序中是否发生了交换，如没有则说明已经排好了序。
2. 使用一个变量`lastIndex`来存储上一趟排序中最后一次交换的两个元素的下标的较小值，则本次循环中位于`lastIndex`后的数据都是已排好序的数据，不需要再比较。

为了实现读取数据，比较大小，交换数据，我设置了七个状态，其中主要的有`READ0`, `READ1`, `COMP`, `WRITE0`, `WRITE1`，分别用来读取两个数据，比较两个数据大小判断是否需要交换，以及需要交换时将数据写回存储器实现交换。此外还有`INIT`和`DONE`分别表示初始状态和排序完成状态。状态图如下：

![状态图](F:\CSClasses\CODH\Lab\lab1\figs\状态转换图.jpg)

各状态的转换关系如下：

1. `!rstn`为真时立即恢复为`INIT`状态（下面任何状态中`!rstn`为真时都恢复为`INIT`状态，故后面不再重复说明）。
2. 当前为`INIT`状态时，若`start`为真，则进入`READ0`状态，开始排序。
3. 当前为`READ0`状态时，下一个状态为`READ1`，继续读取下一数据。
4. 当前为`READ1`状态时，下一个状态为`COMP`，比较两个数据大小，根据比较结果和`up`的值判断是否需要交换数据。
5. 当前为`COMP`状态时，若`comp_res`为真，则交换数据，进入`WRITE0`状态，否则返回`READ0`状态，继续向后读取数据。
6. 当前为`WRITE0`状态时，下一个状态为`WRITE1`，写入另一个数据。
7. 当前为`WRITE1`状态时，若`index + 1 == lastIndex && swapped == 0 `为真，则说明一趟排序已经完成且没有发生交换，排序结束，进入`DONE`状态，否则返回`READ0`状态，继续读取数据（此时需要将`index`清零，`lastIndex`重置为`temp_lastIndex`）。

以下为状态转换的代码：

```verilog
	// current_state
    always @(posedge clk) begin
        if(!rstn)
            current_state <= INIT;
        else
            current_state <= next_state;
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
```



#### 数据通路

数据通路如下图：

![数据通路](F:\CSClasses\CODH\Lab\lab1\figs\数据通路.jpg)

其中主要可分为以下几个部分：

1. `temp_lastIndex`：`temp_lastIndex`在初始化即`!rstn`为真时设为1023，是数组的最后一个元素的下标。在排序的过程中，如果发生了交换，则`temp_lastIndex = index`，设为交换的两个数据的下标的较小值。否则`temp_lastIndex`保持不变。
2. `lastIndex`：`lastIndex`也是在初始化时设为1023，在一趟排序完成但排序并没有结束后`lastIndex = temp_lastIndex`，其余时刻保持不变。
3. `swapped`：在开始一轮新的排序时`swapped`赋值为0，在一趟排序的过程中，如果发生了交换，则`swapped`赋值为1，否则保持不变。
4. `comp_res`：`comp_res`有两个数据的大小（利用ALU判断）和`up`的值决定，若`up == 1`，则`src0 < src1`时`comp_res`为假，否则为真；若`up == 0`，则`src0 < src1`时`comp_res`为真，否则为假。
5. `index`：`index`在`!rstn`为真或是进入`DONE`的瞬间或是一趟排序完成后赋值为0，在向后读取数据的过程中不断自增（`READ0`状态自增1，其余状态保持不变），在排序完成按下`prior`键时自减1，按下`next`键时自增1（`index == 1023`时加1会变成0，`index == 0`时减1会变成1023，实现循环读取）。
6. `src0`及`src1`：在`READ0`状态`src0 = spo`读取数据，在`READ1`状态`src1 = spo`读取数据，其余时刻二者保持不变。
7. `we`：在`WRITE0`和`WRITE1`状态`we = 1`以写入数据，其余时刻`we`保持为0，不写入数据。
8. `a`：`a`为读取或写入寄存器的地址，在`READ0/WRITE0/DONE`状态时`a = index`以读取或写入数据，在`READ1/WRITE1`状态时`a = index + 1`以读取或写入下一个数据，其余状态`a`保持为0。
9. `d`：`d`在`WRITE0`状态赋值为`src1`，在`WRITE1`状态赋值为`src0`，以实现数据交换，其余状态`d`保持不变。
10. `count`：`count`在状态不为`INIT/DONE`时每个周期自增1，以实现计数，其余时刻保持为0。
11. `done`：`done`在状态为`INIT/DONE`时赋值为1，其余时刻赋值为0。
12. `data`：`data`在`done`不为1时赋值为0，否则赋值为`spo`以显示数据。

由于这一部分几乎为`SRT`的全部代码，所以代码见文末。



### 核心代码

#### SRT模块核心代码

核心代码包括状态转换，下标变换，`lastIndex`和`swapped`的赋值，数据的读取和写入等。代码如下：

```verilog
	// 状态转换
	// current_state
    always @(posedge clk) begin
        if(!rstn)
            current_state <= INIT;
        else
            current_state <= next_state;
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

	// 下标变换
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

	// lastIndex
	always @(posedge clk) begin
        if(!rstn)
            temp_lastIndex <= LASTINDEX;
        else if(current_state == COMP && comp_res)
            temp_lastIndex <= index;
        else
            temp_lastIndex <= temp_lastIndex;
    end
    always @(posedge clk) begin
        if(!rstn)
            lastIndex <= LASTINDEX;
        else if (new_cycle)
            lastIndex <= temp_lastIndex;
        else
            lastIndex <= lastIndex;
    end

	// swapped
	always @(posedge clk) begin
        if(!rstn)
            swapped = 0;
        else if(current_state == WRITE0)
            swapped = 1;
        else if(index == 0)
            swapped = 0; // 一趟排序完成后swapped清零
    end

	// 数据读取与写入
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
```

#### 其他模块核心代码

要实现上板还需要一个顶层模块来例化`SRT`，并且加上捕获按键上升沿，数码管显示等模块。代码如下：

捕获上升沿：

```verilog
module Edge_capture(
    input                clk,
    input                rstn,
    input                sig_in,
    output               pos_edge,
    output               neg_edge
);
    reg sig_r1, sig_r2, sig_r3;

    always @(posedge clk) begin
        if (!rstn) begin
            sig_r1 <= 0;
            sig_r2 <= 0;
            sig_r3 <= 0;
        end
        else begin
            sig_r1 <= sig_in;
            sig_r2 <= sig_r1;
            sig_r3 <= sig_r2;
        end
    end

    assign pos_edge = sig_r3 & ~sig_r2;
    assign neg_edge = ~sig_r3 & sig_r2;
endmodule
```

数码管显示模块：

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



### 仿真结果

![仿真结果](F:\CSClasses\CODH\Lab\lab1\figs\SRT仿真.png)

可以看到排序用了`0x001ff8cb`个周期，`lastIndex`最终为0xc，这比正常冒泡排序至少节省了最后12趟排序的时间。



### RTL电路，电路资源和性能

#### RTL电路

SRT模块的RTL电路如下图：

![SRT_RTL](F:\CSClasses\CODH\Lab\lab1\figs\SRT_RTL电路.png)

Top模块的RTL电路如下图：

![Top_RTL](F:\CSClasses\CODH\Lab\lab1\figs\TOP_RTL.png)





#### 电路资源

![SRT资源](F:\CSClasses\CODH\Lab\lab1\figs\SRT_utilization_summary.png)

![SRT资源](F:\CSClasses\CODH\Lab\lab1\figs\SRT_utilization_hierarchy.png)

#### 电路性能

![SRT性能](F:\CSClasses\CODH\Lab\lab1\figs\SRT_timing.png)

可以看出在时钟周期为10 ns 时电路还有性能还可进一步提升。

用`Top`模块例化`SRT`模块和`Edge_capture`，`Segment`等模块后，电路资源和性能如下：

![Top资源](F:\CSClasses\CODH\Lab\lab1\figs\TOP_utilization_summary.png)

![Top资源](F:\CSClasses\CODH\Lab\lab1\figs\TOP_utilization_hierarchy.png)

![Top性能](F:\CSClasses\CODH\Lab\lab1\figs\TOP_timing.png)



### 下载结果

下载测试结果如下：

图中后十个LED灯表示数据的下标，第一个LED灯表示`done`，第二个LED灯表示`up`，拨动最后一个开关可以改变up的值，倒数第二个开关可以决定数码管的显示结果为数据还是周期数。（数据的显示为循环的方式，即显示第一个数据时按`prior`会显示最后一个数据，显示最后一个数据时按`next`会显示第一个数据）

<img src="F:\CSClasses\CODH\Lab\lab1\figs\dist1.jpg" alt="dist1" style="zoom: 50%;" />

![dist2](F:\CSClasses\CODH\Lab\lab1\figs\dist2.jpg)

![dist3](F:\CSClasses\CODH\Lab\lab1\figs\dist3.jpg)

可以看出此时数据按降序排列，最大的值为`FFFC2116`，`003C1822`。

![dist4](F:\CSClasses\CODH\Lab\lab1\figs\dist5.jpg)

可以看到排序花费了`0x001FF8CB`个周期，这与仿真结果一致。

### 结果分析

由测试结果可得，SRT电路设计正确，结果正确，且性能尚可，电路使用最多的是查找表（`LUT`）和分布式存储器（`FF`）。



## 选做——利用块式存储器实现冒泡排序

### 逻辑设计

块式存储器与分布式存储器的设计基本相同，不同的是由于块式存储器是同步读写，读取数据需要一个周期，所以我增加了两个缓冲状态，以能正常读取数据不会进入比较状态。以下为状态设计与转移部分的代码：

```verilog
	localparam INIT    = 4'd0;
    localparam READ0   = 4'd1;
    localparam BUFFER0 = 4'd2;
    localparam READ1   = 4'd3;
    localparam BUFFER1 = 4'd4;
    localparam COMP    = 4'd5;
    localparam WRITE0  = 4'd6;
    localparam WRITE1  = 4'd7;
    localparam DONE    = 4'd9;

	// current_state
    always @(posedge clk) begin
        if(!rstn)
            current_state <= INIT;
        else
            current_state <= next_state;
    end

	wire test = (index + 1 == lastIndex && swapped == 0) || lastIndex == 0;
    // next_state
    always @(*) begin
        next_state = current_state;
        case (current_state)
            INIT  : next_state = start ? READ0 : INIT; 
            READ0 : next_state = BUFFER0;
            BUFFER0: next_state = READ1;
            READ1 : next_state = BUFFER1;
            BUFFER1: next_state = COMP;
            COMP  : next_state = comp_res ? WRITE0 : (test ? DONE : READ0);
            WRITE0: next_state = WRITE1;
            WRITE1: next_state = test ? DONE : READ0;
            DONE  : next_state = rstn ? DONE : INIT;
        endcase
    end
```



### 核心代码

块式存储器实现的排序器的核心代码也是与分布式存储器的基本相同，除去上面所提到状态设置的不同。同分布式存储器实现的排序器一样，这里不再粘贴，代码见文末。



### 仿真结果

![SRT_blk](F:\CSClasses\CODH\Lab\lab1\figs\SRT_blk时序仿真.png)

可以看出，块式存储器实现的排序器所用的周期要比分布式存储器多，这是因为块式存储的读取比分布式存储器慢，需要花费更多的周期来读取数据。



### RTL电路，电路资源和性能

RTL电路图如下：

![SRT_blk_RTL](F:\CSClasses\CODH\Lab\lab1\figs\SRT_blk_RTL.png)

电路资源如下：

![SRT_blk资源](F:\CSClasses\CODH\Lab\lab1\figs\SRT_blk_summary.png)

![SRT_blk资源](F:\CSClasses\CODH\Lab\lab1\figs\SRT_blk_utilization_h.png)



可以看出，块式存储器实现的排序器比分布式存储器实现的排序器节省了很多资源。

电路性能如下：

![SRT_blk性能](F:\CSClasses\CODH\Lab\lab1\figs\SRT_blk_timing.png)

可以看出块式存储器实现的排序器性能也更好，总的延迟时间小于分布式存储器实现的排序器。但是前者完成排序花费的时间更长，因为块式存储器读取数据所需的时间更长。



### 下载结果

![blk1](F:\CSClasses\CODH\Lab\lab1\figs\blk1.jpg)

![blk2](F:\CSClasses\CODH\Lab\lab1\figs\blk2.jpg)

![blk3](F:\CSClasses\CODH\Lab\lab1\figs\blk3.jpg)

![blk4](F:\CSClasses\CODH\Lab\lab1\figs\blk4.jpg)

可以看出数据按升序排列，最小的值为`003C1822`，最大的值为`FFFC2116`，由于两种排序器使用的是同一个COE文件，所以排序结果相同。

![blk5](F:\CSClasses\CODH\Lab\lab1\figs\blk5.jpg)

可以看出排序花费`002FD20D`个周期，这与仿真结果一致，但比分布式存储器实现的排序器花费的时间要长。

### 结果分析

块式存储器实现的排序器的结果均正确，但花费的周期数要比分布式存储器实现的排序器多，这是正常的，因为块式存储器的读取需要更多的时间，故需要更多的周期。



## 实验总结

本次实验各项结果均正确且符合要求，但在过程中遇到了一些问题，总结如下：

1. 在对`SRT`进行仿真时，我原以为时钟周期设置得越短越好，但是却因为时钟周期设置的太短而导致分布式存储器无法正确的读取与写入数据，为了这个问题我花费了大量的时间调试。由此我也明白了仿真时的周期不能设置的太短。
2. 在利用块式存储器实现排序器时，我增加了状态数，但是却忘记了增加状态的位宽，导致程序无法进入溢出的状态，这个错误我同样也是花费了大量的时间来调试。由此我也吸取了教训，以后实验一定更加认真细致。



## 设计文件

### ALU.v

```verilog
module ALU(
    input               [31: 0]    src0,src1,
    input               [ 3: 0]    op,
    output      reg     [31: 0]    res
);
    wire [31: 0]    sub_res = src0 - src1;
    always @(*) begin
        case (op)
            4'b0000: res = src0 + src1;
            4'b0001: res = src0 - src1;
            4'b0010: res = sub_res[31] ? 32'b1 : 32'b0;
            // 无符号比较时，src0 < src1当且仅当src0首位为0，src1首位为1或二者首位相同的情况下res[31] = 1
            4'b0011: res = ( (~src0[31] & src1[31]) | (((src0[31] & src1[31]) | (~src0[31] & ~src1[31])) & sub_res[31]) ) ? 32'b1 : 32'b0;
            4'b0100: res = src0 & src1;
            4'b0101: res = src0 | src1;
            4'b0110: res = ~(src0 | src1);
            4'b0111: res = src0 ^ src1;
            4'b1000: res = src0 << src1[4 : 0];
            4'b1001: res = src0 >> src1[4 : 0];
            4'b1010: res = src0 >>> src1[4 : 0];
            4'b1011: res = src1;
            default: res = 32'b0;
        endcase
    end

endmodule
```



### RegFile.v

```verilog
module RegFile(
    input                   clk,
    input       [ 4: 0]     ra0,ra1,
    output      [31: 0]     rd0,rd1,
    input       [ 4: 0]     wa,
    input       [31: 0]     wd,
    input                   we
);
    reg [31: 0] x[31: 0];

    initial begin
        x[0] = 32'b0; // 0号寄存器初始化为0
    end

    always @(posedge clk) begin
        if(we && wa)
            x[wa] <= wd; // we有效且wa不为0时写入数据
    end

    assign rd0 = ((ra0 == wa) && we && wa) ? wd : x[ra0]; // 读端口0，同时读写且wa不为0时读取写优先，读取要写入的数据
    assign rd1 = ((ra1 == wa) && we && wa) ? wd : x[ra1]; // 读端口1
endmodule
```



### SRT.v

```verilog
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
```



### Edge_capture.v

```verilog
module Edge_capture(
    input                clk,
    input                rstn,
    input                sig_in,
    output               pos_edge,
    output               neg_edge
);
    reg sig_r1, sig_r2, sig_r3;

    always @(posedge clk) begin
        if (!rstn) begin
            sig_r1 <= 0;
            sig_r2 <= 0;
            sig_r3 <= 0;
        end
        else begin
            sig_r1 <= sig_in;
            sig_r2 <= sig_r1;
            sig_r3 <= sig_r2;
        end
    end

    assign pos_edge = sig_r3 & ~sig_r2;
    assign neg_edge = ~sig_r3 & sig_r2;
endmodule
```

### Segment.v

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

### Top.v

```verilog
module Top(
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
);
    
    wire            pos_prior;
    wire            pos_next;

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

    SRT mysrt(
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
```

### SRT_blk.v

```verilog
module SRT_blk(
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
    localparam INIT    = 4'd0;
    localparam READ0   = 4'd1;
    localparam BUFFER0 = 4'd2;
    localparam READ1   = 4'd3;
    localparam BUFFER1 = 4'd4;
    localparam COMP    = 4'd5;
    localparam WRITE0  = 4'd6;
    localparam WRITE1  = 4'd7;
    localparam DONE    = 4'd9;

    localparam LASTINDEX  = 1023;// LASTINDEX为序列的最后一个元素的下标

    reg     [ 3: 0]     current_state, next_state;
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
    //wire                en;

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
    assign comp_res = up ? ~res[0] : res[0];

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

    wire test = (index + 1 == lastIndex && swapped == 0) || lastIndex == 0;
    // next_state
    always @(*) begin
        next_state = current_state;
        case (current_state)
            INIT  : next_state = start ? READ0 : INIT; 
            READ0 : next_state = BUFFER0;
            BUFFER0: next_state = READ1;
            READ1 : next_state = BUFFER1;
            BUFFER1: next_state = COMP;
            COMP  : next_state = comp_res ? WRITE0 : (test ? DONE : READ0);
            WRITE0: next_state = WRITE1;
            WRITE1: next_state = test ? DONE : READ0;
            DONE  : next_state = rstn ? DONE : INIT;
            //default: next_state = 4'd10;
        endcase
    end

    // 其他变量

    always @(posedge clk) begin
        if(current_state == READ0 || current_state == BUFFER0)
            src0 <= spo;
        else
            src0 <= src0;
    end
    always @(posedge clk) begin
        if(current_state == READ1 || current_state == BUFFER1)
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

    blk_mem_gen_0 my_blk_mem(
        .clka(clk),
        .wea(we),
        .ena(1'b1),
        .dina(d),
        .douta(spo),
        .addra(a)
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
```

### Top_blk.v

与`Top.v`一样

### dist_gen_mem_test.v

```verilog
module dist_mem_gen_test(
    input                           clk,
    input       [ 9: 0]             a,
    input       [31: 0]             d,
    input                           we,
    output      [31: 0]             spo
);
    dist_mem_gen_0 my_dist_mem_gen_0(
        .clk(clk),
        .a(a),
        .d(d),
        .we(we),
        .spo(spo)
    );
    
endmodule
```

### blk_gen_mem_test.v

```verilog
module blk_mem_gen_test(
    input                           clka,
    input       [ 9: 0]             addra,
    input       [31: 0]             dina,
    input                           ena,
    input                           wea,
    output      [31: 0]             douta
);
    blk_mem_gen_0 my_blk_mem_gen_0(
        .clka(clka),
        .addra(adrra),
        .dina(dina),
        .ena(ena),
        .wea(wea),
        .douta(douta)
    );
endmodule
```

### ALU_tb.v

```verilog
module ALU_tb();
    reg     [31: 0]     src0,src1;
    reg     [ 3: 0]     op;
    wire    [31: 0]     res;

    initial begin
        src0 = 32'h1111_1111;
        src1 = 32'hffff_ffff;
        op = 4'b0000;
        while(op <= 4'd11) begin
            #2 op = op + 1;
        end
    end

    ALU myalu(
        .src0(src0),
        .src1(src1),
        .op(op),
        .res(res)
    );

endmodule
```

### RegFile_tb.v

```verilog
module RegFile_tb();
    reg                     clk;
    reg                     we;
    reg     [ 4: 0]         ra0, ra1, wa;
    reg     [31: 0]         wd;
    wire    [31: 0]         rd0, rd1;

    reg [ 5: 0] cnt;
    initial begin
        clk = 0;
        we = 1;
        cnt = 0;
        #2; // 先测试0号寄存器能否写入
        wa = 0; 
        wd = 1;
        ra0 = 0;

        while(cnt < 32) begin
            #2;
            cnt = cnt + 1;
            //we = ~we;
            wd = cnt + 1;
            wa = cnt;
            ra0 = cnt;// 测试是否为写优先
            ra1 = cnt;
        end
    end

    always #1 clk = ~clk;

    RegFile myrf(
        .clk(clk),
        .ra0(ra0),
        .ra1(ra1),
        .rd0(rd0),
        .rd1(rd1),
        .wa(wa),
        .wd(wd),
        .we(we)
    );
endmodule
```

### SRT_tb.v

```verilog
module SRT_tb();
    reg                     clk, rstn;
    reg                     next, prior, start, up;
    wire                    done;
    wire    [ 9: 0]         index;
    wire    [31: 0]         data;
    wire    [31: 0]         count;

    initial begin
        clk = 0;
        rstn = 0;
        next = 0;
        prior = 0;
        start = 0;
        up = 0;
        #20 rstn = 1;
        #20 start = 1;
        #20 start = 0;
        while(!done) begin
            #10;
        end
        $display("Done");
        next = 1;
    end

    always #5 clk = ~clk;

    SRT mysrt(
        .clk(clk),
        .rstn(rstn),
        .next(next),
        .prior(prior),
        .start(start),
        .up(up),
        .done(done),
        .index(index),
        .data(data),
        .count(count)
    );

endmodule
```

### SRT_blk_tb.v

与`SRT_tb.v`一样。

### dist_mem_gen_tb.v

```verilog
module dist_mem_gen_tb();
    reg                     clk;
    reg                     we;
    reg     [ 9: 0]         a;
    reg     [31: 0]         d;
    wire    [31: 0]         spo;

    initial begin
        clk = 0;
        we = 0;
        #10; we = 1; d = 1;
        #2 we = 0;
        #10; we = 1; d = 2;
        #2 we = 0;
        #10; we = 1; d = 3;
        #2 we = 0;
    end

    initial begin
        a = 0;
        while(a <= 1023)
            #2  a = a + 1; // 显示存储器内容
    end

    always #1 clk = ~clk;

    dist_mem_gen_test my_dist_mem_gen_test(
        .a(a),
        .d(d),
        .clk(clk),
        .we(we),
        .spo(spo)
    );

endmodule
```

### blk_gen_mem_tb.v

```verilog
module blk_mem_gen_tb();
    reg                     clka;
    reg                     wea;
    reg                     ena;
    reg     [ 9: 0]         addra;
    reg     [31: 0]         dina;
    wire    [31: 0]         douta;

    initial begin
        clka = 0;
        wea = 0;
        ena = 1;
        dina = 0;
    end

    initial begin
        addra = 1;
        #20; wea = 1; dina = 1; addra = 2;
        #20  wea = 0; 
        #20  ena = 0;
        #20; wea = 1; dina = 2; addra = 3;
        #20 ena = 1;
        /*while(addra < 11'd1023) begin
            #10;
            //wea = ~wea;
            //ena = ~ena;
            addra = addra + 1; // 显示存储器内容
            dina = addra;
        end*/
    end


    always #5 clka = ~clka;

    blk_mem_gen_test my_blk_mem_gen_test(
        .clka(clka),
        .addra(addra),
        .dina(dina),
        .ena(ena),
        .wea(wea),
        .douta(douta)
    );

endmodule
```





