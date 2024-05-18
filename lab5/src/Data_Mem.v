module Data_Mem(
    input                   clk,
    input                   resetn,
    input                   we,
    input       [ 7: 0]     rindex,
    input       [ 7: 0]     windex,
    input       [127:0]     wdata,
    output      [127:0]     rdata
);
    reg [127:0] data[0:255];
    integer i;
    always @(posedge clk) begin
        if(!resetn) begin
            for(i = 0; i < 256;i = i + 1) begin
                data[i] <= 0;
            end
        end
        else begin
            if(we)
                data[windex] <= wdata; 
        end
    end

    assign rdata = data[rindex];

endmodule