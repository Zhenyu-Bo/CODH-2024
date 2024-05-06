module Hazard_unit(
    input wire memread_ex,
    input wire rf_we_ex,
    input wire [4:0]rf_wa_ex,
    input wire [4:0]rf_ra0_id,
    input wire [4:0]rf_ra1_id,
    input wire npc_sel_ex,
    output reg stall_pc,
    output reg stall_if_id,
    output reg flush_if_id,
    output reg flush_id_ex
);
always @(*)begin
    stall_pc=1'b0;
    stall_if_id=1'b0;
    flush_if_id=1'b0;
    flush_id_ex=1'b0;
    if(memread_ex && rf_we_ex && (rf_wa_ex==rf_ra0_id || rf_wa_ex==rf_ra1_id) && (rf_wa_ex!=5'd0))begin
        stall_pc=1'b1;
        stall_if_id=1'b1;
        flush_id_ex=1'b1;
    end
    else if(npc_sel_ex)begin
        flush_id_ex=1'b1;
        flush_if_id=1'b1;
    end
end
endmodule