# TIMER_ADDR		0xbfafe000	// 计时器

# LED_ADDR		    0xbfaff020	// 16个LED指示灯
# LED_RG0_ADDR		0xbfaff030	// 双色LED指示灯0
# LED_RG1_ADDR		0xbfaff040	// 双色LED指示灯1
# NUM_ADDR		    0xbfaff050	// 8个7段数码管
# SWITCH_ADDR		0xbfaff060	// 16个开关
# BTN_STEP_ADDR		0xbfaff080	// 2个按钮

# initialtion
    li.w        a0, 0x1c800000
    li.w        a1, 0xbfaff000
    li.w        a2, 0xbfafe000
    li.w        s0, 0x12345678
    li.w        t0, 0xe0000200
    addi.w      t8, zero, 0
    addi.w      s3, zero, 0

    la.local    sp, READN
    bl          READBTNC
JUDGE1:
    beq         s3, s1, SHOWAVERAGE
    bl          LFSR
    la.local    sp, SHOWARRAY
    bl          READBTNC
    
    ld.w        t2, a2, 0           # 读取计时器
    bl          SORT                # 调用排序子程序
    ld.w        t3, a2, 0           # 再次读取计时器
    sub.w       t7, t3, t2          # 计算排序所用时间
    add.w       t8, t7, t8          # 累加排序所用时间
    
    la.local    sp, SHOWBOTH   
    bl          READBTNC
    addi.w      s3, s3, 1
    b           JUDGE1
SHOWAVERAGE:
    beq         s1, zero, SHOW
    addi.w      s1, s1, -1
    beq         s1, zero, SHOW
    addi.w      s1, s1, -1
    beq         s1, zero, DIVIDE2
    addi.w      s1, s1, -2
    beq         s1, zero, DIVIDE4
    b           DIVIDE8
DIVIDE2:
    srli.w      t8, t8, 1
    b           SHOW
DIVIDE4:
    srli.w      t8, t8, 2
    b           SHOW
DIVIDE8:
    srli.w      t8, t8, 3
SHOW:
    st.w        t8, a1, 0x050       # 显示平均排序时间  
    li.w        a2, 0x0000ffff
    st.w        a2, a1, 0x020       # LED灯全亮    
ENDLESSLOOP:
    b           ENDLESSLOOP


SHOWARRAY:
    ld.w        a4, a1, 0x060       # 读取开关输入的下标
    st.w        a4, a1, 0x020       # LED灯显示下标
    slli.w      a4, a4, 4           # a4左移4位，以消除高四位影响
    srli.w      a4, a4, 2           # a4再右移2位以得到真正的偏移量
    add.w       a4, a4, a0          # 定位数据地址
    ld.w        t2, a4, 0           # 读取数据
    st.w        t2, a1, 0x050       # 显示数据
    jirl        zero, ra, 0

SHOWBOTH:
    ld.w        a4, a1, 0x060       # 读取开关输入的下标
    st.w        a4, a1, 0x020       # LED灯显示下标
    srli.w      t2, a4, 11          # 读取开关的第11位
    andi        t2, t2, 1           # 取开关的第11位
    bne         t2, zero, show_time
    slli.w      a4, a4, 4           # a4左移4位，以消除高四位影响
    srli.w      a4, a4, 2           # a4再右移2位以得到真正的偏移量
    add.w       a4, a4, a0          # 定位数据地址
    ld.w        t2, a4, 0           # 读取数据
    st.w        t2, a1, 0x050       # 显示数据
    jirl        zero, ra, 0
show_time:
    st.w        t7, a1, 0x050
    jirl        zero, ra, 0

SHOWTIME:
    st.w        t7, a1, 0x050
    jirl        zero, ra, 0


READN:
    ld.w        s1, a1, 0x060
    st.w        s1, a1, 0x020           # 用LED显示N
    srli.w      s1, s1, 12              # s1存储输入的N（由开关的高4位输入）
    st.w        s1, a1, 0x050           # 用数码管显示N
    jirl        zero, ra, 0


LFSR:
    addi.w      a7, a0,   4             # a7 <- a0 + 4
    addi.w      s6, s0,   0             # s6 <- s0
    addi.w      t1, zero, 1             # t1 <- 1
    addi.w      tp, zero, 0             # tp <- 0
    st.w        s6, a0,   0             # MEM[a0] <- s6
    addi.w      t6, zero, 1024          # t6 <- 1024
LFSRLOOP:
    bgeu        t1, t6,   RET1          # if t1 >= t6 then return
    andi        tp, s6, 1               # tp <- s6 & 1
    srli.w      s6, s6, 1               # s6 <- s6 >> 1
    beq         tp, zero, STORE         # if tp == 0 then goto STORE
    xor         s6, s6, t0              # s6 <- s6 ^ t0
STORE:
    st.w        s6, a7, 0               # MEM[a7] <- s6
    addi.w      a7, a7, 4               # a7 <- a7 + 4
    addi.w      t1, t1, 1               # t1 <- t1 + 1
    addi.w      tp, zero, 0             # tp <- 0
    b           LFSRLOOP                # goto LFSRLOOP
RET1:
    jirl        zero, ra, 0             # return


# 排序子程序
SORT:
    li.w    	t5, 4092         	  # t5 <- 1023*4 = 4092
	add.w		t5, t5, a0            # t5 <- t5 + a0
extern_loop:
    addi.w  	a7, a0,   0           # a7存储数组起始地址
    addi.w  	a3, t5,   0           # a3存储lastIndex, 初始化为t5
    addi.w  	s8, zero, 0           # s8存储swapped
inner_loop:
    bgeu    	a7, a3,   judge       # 若index等于lastIndex则跳转
    ld.w    	t6, a7,   0
    ld.w    	t1, a7,   4
    bgeu    	t6, t1,   addIndex
    st.w    	t1, a7,   0
    st.w    	t6, a7,   4
    addi.w  	t5, a7,   0
    addi.w  	s8, zero, 1
addIndex:
    addi.w  	a7, a7,   4
    b       	inner_loop
judge:
    bne     	s8, zero, extern_loop
    jirl        zero, ra, 0


READBTNC:
    addi.w      a6, zero, 2
    addi.w      s7, ra, 0
READBTNC_LOOP:
    ld.w        a5, a1, 0x080
    andi        a5, a5, 2
    and         a6, a5, a6
    jirl        ra, sp, 0
    bge         a6, a5, READBTNC_LOOP
    jirl        zero, s7, 0
