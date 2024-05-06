# Lab2 汇编程序设计

## 设计思路

实验的基本思路如下：传统的冒泡排序是通过两层循环，每一次内层循环都将未排过序的数中最小（大）的数交换到最后，外层循环执行次数为数组长度（设为n）减1，以将n-1个最大（小）的数依次放到最后。实验中对算法做了以下两点优化：

1. 使用一个变量`swapped`来记录一趟排序中是否发生了交换，如没有则说明已经排好了序。
2. 使用一个变量`lastIndex`来存储上一趟排序中最后一次交换的两个元素的下标的较小值，则本次循环中位于`lastIndex`后的数据都是已排好序的数据，不需要再比较。

在使用汇编程序设计冒泡排序时，则需要使用相应的寄存器来表示这些变量。

## 流程图

根据设计思路，可以作出流程图如下：

![流程图](F:\CSClasses\CODH\Lab\lab2\figs\流程图.jpg)

虽然流程图中已经注明了各个寄存器表示的变量，这里还是作进一步说明：

1. `t0`,  `t1`：这两个寄存器分别表示`src0`，`src1`，也就是冒泡排序时对应的取出的当前下标的数值和下一个下标的数值。
2. `s0`：`s0`用来存储`lastIndex`的值，它用来表示上一趟排序最后一次发生交换的两个元素的下标的较小值，也就是说在当前的排序中，`lastIndex`后的数据都是排好序的，不需要再比较。
3. `t2`：`t2`用来存储`templastIndex`，因为在一趟排序中，`lastIndex`的值应是不变的，所以使用`templstIndex`来存储这趟排序的最后一次发生交换的两个元素的下标的较小值，每当有数据发生交换时就更新`t2`的值，最后在下一趟排序开始前将`t2`的值赋给`s0`。
4. `s1`：`s1`用来存储`swapped`的值，它用来表示一趟排序是否发生交换。在一趟排序开始前，`s1`复位为0，每当发生交换时，`s1`就赋值为1。如果一趟排序完成后没有发生交换即`s1`的值为0，就说明数组已经排好序，排序结束。
5. `a0`：`a0`用来存储读取数据的下标`index`，需要注意的是每次需要往后读取数据时`a0`需要加4而不是加1。

## 代码设计

根据流程图，可以很容易地写出代码：

```asm
			la.local	$s2, array				# 将数组起始地址存入寄存器中，方便后续使用
			#li.w		$s2, 0x1c800000
            li.w    	$t2, 4092         		# t2存储1023*4，为最后一个数据的地址
			add.w		$t2, $t2, $s2
			#li.w		$t2, 0x1c800ffc
extern_loop:
            addi.w  	$a0, $s2,   0           # a0存储数组起始地址
            addi.w  	$s0, $t2,   0           # s0存储lastIndex, 初始化为t2
            addi.w  	$s1, $zero, 0           # s1存储swapped
inner_loop:
            bgeu    	$a0, $s0,   judge       # 若index等于lastIndex则跳转
            ld.w    	$t0, $a0,   0
            ld.w    	$t1, $a0,   4
            bgeu    	$t0, $t1,   addIndex
            st.w    	$t1, $a0,   0
            st.w    	$t0, $a0,   4
            addi.w  	$t2, $a0,   0
            addi.w  	$s1, $zero, 1
addIndex:
            addi.w  	$a0, $a0,   4
            b       	inner_loop

judge:
            bne     	$s1, $zero, extern_loop
```

但是本次实验需要对数组进行排序，所以需要写入数据。写入数据有两种方法，一是在代码段中增加写入数据的代码，可以采用一个循环，不断更新写入的数值和地址，一共循环1024次，但是这势必会消耗一定的时间；二是在数据段导入数据，这样可以在编译阶段实现数据的写入，节省了时间。所以我直接将`lab1`的数据附在了代码的数据段中。由于完整代码过长（因为数据段就至少需要1024行），所以这里我只粘贴含有数据段的一部分代码：

```asm
.text    
			la.local	$s2, array				# 将数组起始地址存入寄存器中，方便后续使用
			#li.w		$s2, 0x1c800000
            li.w    	$t2, 4092         		# t2存储1023*4，为最后一个数据的地址
			add.w		$t2, $t2, $s2
			#li.w		$t2, 0x1c800ffc
extern_loop:
            addi.w  	$a0, $s2,   0           # a0存储数组起始地址
            addi.w  	$s0, $t2,   0           # s0存储lastIndex, 初始化为t2
            addi.w  	$s1, $zero, 0           # s1存储swapped
inner_loop:
            bgeu    	$a0, $s0,   judge       # 若index等于lastIndex则跳转
            ld.w    	$t0, $a0,   0
            ld.w    	$t1, $a0,   4
            bgeu    	$t0, $t1,   addIndex
            st.w    	$t1, $a0,   0
            st.w    	$t0, $a0,   4
            addi.w  	$t2, $a0,   0
            addi.w  	$s1, $zero, 1
addIndex:
            addi.w  	$a0, $a0,   4
            b       	inner_loop

judge:
            bne     	$s1, $zero, extern_loop


.data
array:
	.word	0xaf2b1906
	.word	0x6c815f98
```

后面的数据均为`	.word	0x...`的格式。

## 执行结果

排完序后内存部分数值如下：

![res1](F:\CSClasses\CODH\Lab\lab2\figs\屏幕截图 2024-03-26 220323.png)

![res2](F:\CSClasses\CODH\Lab\lab2\figs\屏幕截图 2024-03-26 220816.png)

![res3](F:\CSClasses\CODH\Lab\lab2\figs\屏幕截图 2024-03-26 220915.png)

可见数值确实为降序排序，代码设计正确。

由于导出的`COE`文件过长，所以这里不再粘贴。