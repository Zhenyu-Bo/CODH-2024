module forwarding_unit (
    input wire rf_we_mem,
    input wire rf_we_wb,
    input wire [4:0] rf_wa_mem,
    input wire [4:0] rf_wa_wb,
    input wire [31:0] rf_wd_mem,
    input wire [31:0] rf_wd_wb,
    input wire [4:0] rf_ra0_ex,
    input wire [4:0] rf_ra1_ex,
    // input wire [1:0]rf_wd_sel,
    output reg rf_rd0_fe,
    output reg rf_rd1_fe,
    output reg [31:0] rf_rd0_fd,
    output reg [31:0] rf_rd1_fd
);
  always @(*) begin

    rf_rd0_fe = 0;
    rf_rd1_fe = 0;
    rf_rd0_fd = 0;
    rf_rd1_fd = 0;
    if(rf_we_mem && rf_wa_mem!=5'd0 && rf_wa_mem==rf_ra0_ex)//mem回传
    begin
      rf_rd0_fe = 1;
      rf_rd0_fd = rf_wd_mem;
    end
    else if(rf_we_wb && rf_wa_wb!=5'd0 && rf_wa_wb==rf_ra0_ex)//wb回传
    begin
      rf_rd0_fe = 1;
      rf_rd0_fd = rf_wd_wb;
    end

    if(rf_we_mem && rf_wa_mem!=5'd0 && rf_wa_mem==rf_ra1_ex)//mem回传
    begin
      rf_rd1_fe = 1;
      rf_rd1_fd = rf_wd_mem;
    end
    else if(rf_we_wb && rf_wa_wb!=5'd0 && rf_wa_wb==rf_ra1_ex)//wb回传
    begin
      rf_rd1_fe = 1;
      rf_rd1_fd = rf_wd_wb;
    end
  end
endmodule