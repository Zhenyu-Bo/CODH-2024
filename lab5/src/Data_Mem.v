module Data_Mem #(
    parameter DATA_WIDTH = 128,
    parameter ADDR_WIDTH = 8,
    parameter MEM_SIZE = 256
)(
    input                               clk,
    input                               resetn,
    input                               we,
    input       [ADDR_WIDTH-1: 0]       rindex,
    input       [ADDR_WIDTH-1: 0]       windex,
    input       [DATA_WIDTH-1: 0]       wdata,
    output      [DATA_WIDTH-1: 0]       rdata
);
    reg [DATA_WIDTH-1:0] data[0:MEM_SIZE-1];
    integer i;
    always @(posedge clk) begin
        if(!resetn) begin
            for(i = 0; i < MEM_SIZE;i = i + 1) begin
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