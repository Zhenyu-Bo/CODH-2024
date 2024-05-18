module TagV_Mem(
    input                   clk,
    input                   resetn,
    input                   we,
    input       [ 7:0]      rindex,
    input       [ 7:0]      windex,
    input       [19:0]      wtag,
    output      [19:0]      rtag,
    output      [ 0:0]      rvalid
);
    reg [20:0]  tagv[0:255];
    integer i;
    always @(posedge clk) begin
        if(!resetn) begin
            for(i = 0; i < 256;i = i + 1) begin
                tagv[i] <= 0;
            end
        end
        else begin
            if(we)
                tagv[windex] <= {wtag, 1'b1}; 
        end
    end

    assign rtag   = tagv[rindex][20:1];
    assign rvalid = tagv[rindex][0];
    
endmodule
