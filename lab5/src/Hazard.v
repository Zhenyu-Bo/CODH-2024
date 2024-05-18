module Hazard(
    input           [ 4: 0]         ID_raddr1,
    input           [ 4: 0]         ID_raddr2,
    input           [ 4: 0]         EX_dest,
    input           [ 0: 0]         EX_mem_read,
    input           [ 0: 0]         EX_rf_we,
    input           [ 0: 0]         br_taken,

    output  reg     [ 0: 0]         dStall,
    output  reg     [ 0: 0]         dFlush,
    output  reg     [ 0: 0]         eStall,
    output  reg     [ 0: 0]         eFlush,
    output  reg     [ 0: 0]         fStall
);
    always @(*) begin
        dStall = 0;
        dFlush = 0;
        eStall = 0;
        eFlush = 0;
        fStall = 0;
        if(EX_mem_read && EX_rf_we && (EX_dest == ID_raddr1 || EX_dest == ID_raddr2) && EX_dest) begin
            eFlush = 1; // 清空ID_EX段间寄存器
            dStall = 1; // 暂停IF_ID段
            fStall = 1; // 暂停PC
        end
        else if(br_taken) begin
            eFlush = 1; // 清空ID_EX段间寄存器
            dFlush = 1; // 清空IF_ID段间寄存器
        end
    end
endmodule
