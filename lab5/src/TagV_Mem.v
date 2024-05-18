module TagV_Mem #(
    parameter TAG_WIDTH = 20,
    parameter ADDR_WIDTH = 8,
    parameter MEM_SIZE = 256
)(
    input                               clk,
    input                               resetn,
    input                               we,
    input       [ADDR_WIDTH-1:0]        rindex,
    input       [ADDR_WIDTH-1:0]        windex,
    input       [ TAG_WIDTH-1:0]        wtag,
    output      [ TAG_WIDTH-1:0]        rtag,
    output                              rvalid
);
    reg [TAG_WIDTH:0]  tagv[0:MEM_SIZE];
    integer i;
    always @(posedge clk) begin
        if(!resetn) begin
            for(i = 0; i < MEM_SIZE;i = i + 1) begin
                tagv[i] <= 0;
            end
        end
        else begin
            if(we)
                tagv[windex] <= {wtag, 1'b1}; 
        end
    end

    assign rtag   = tagv[rindex][TAG_WIDTH:1];
    assign rvalid = tagv[rindex][0];
    
endmodule
