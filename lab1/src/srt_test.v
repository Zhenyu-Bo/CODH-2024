module srt_test (
    input clk, rstn,
    input up, start, prior, next,
    output done,
    output reg [9: 0] index,
    output [31: 0] data,
    output reg [31: 0] count
);

// Process buttons

always @(posedge clk) begin
    if (rstn) index <= 0;
    else if (prior) index <= index - 1;
    else if (next) index <= index + 1;
end

// Process algorithm

localparam READ1 = 0;
localparam READ2 = 1;
localparam COMPARE = 2;
localparam PLACE1 = 3;
localparam PLACE2 = 4;
localparam DONE = 5;

reg we;
reg [2: 0] nstate, mstate;
reg [9: 0] ni, nj, mi, mj, addr;
wire [31: 0] dat;
reg [31: 0] val1, val2, mval1, mval2, wdat;
wire [31: 0] alu_res;

always @(posedge clk) begin
    if (rstn) count <= 0;
    else if (mstate != DONE) count <= count + 1;
end

always @(posedge clk) begin
    if (rstn) begin
        nstate <= DONE;
        ni <= 0;
        nj <= 10'd1022;
        val1 <= 0;
        val2 <= 0;
    end
    else begin
        nstate <= mstate;
        ni <= mi;
        nj <= mj;
        val1 <= mval1;
        val2 <= mval2;
    end
end

always @(*) begin
    if (nstate == READ1) mstate = READ2;
    else if (nstate == READ2) mstate = COMPARE;
    else if (nstate == COMPARE) begin
        if (alu_res[0] != up) mstate = PLACE1;
        else mstate = (ni == 10'd1022 && nj == 10'd1022) ? DONE : READ1;
    end
    else if (nstate == PLACE1) mstate = PLACE2;
    else if (nstate == PLACE2) mstate = (ni == 10'd1022 && nj == 10'd1022) ? DONE : READ1;
    else if (start && nstate == DONE) mstate = READ1;
    else mstate = DONE;
end

always @(*) begin
    mval1 = val1;
    mval2 = val2;
    if (nstate == DONE || mstate != READ1) begin
        mi = ni;
        mj = nj;
    end
    else begin
        mi = ni;
        mj = nj - 1;
        if (nj == ni) begin
            mi = ni + 1;
            mj = 10'd1022;
        end
    end
    if (nstate == READ1 || nstate == PLACE1) addr = nj;
    else if (nstate != DONE) addr = nj + 1;
    else addr = index;
    if (nstate == PLACE1 || nstate == PLACE2) we = 1;
    else we = 0;
    if (nstate == READ1) mval1 = dat;
    if (nstate == READ2) mval2 = dat;
    if (nstate == PLACE1) wdat = mval2;
    else wdat = mval1;
end

assign done = (nstate == DONE);
assign data = (nstate == DONE) ? dat : 0;

// Connect modules

ALU alumni30 (
    .src0(val1),
    .src1(val2),
    .op(3), // Unsigned less
    .res(alu_res)
);

dist_mem_gen_0 dmg0 (
    .a(addr),
    .d(wdat),
    .clk(clk),
    .we(we),
    .spo(dat)
);

endmodule
