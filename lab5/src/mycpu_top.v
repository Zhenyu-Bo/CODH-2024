module mycpu_top (
	input 			clk,
    input 			rstn,

    //Ports For Debug
    input  [31:0] 	dra0,
    output [31:0] 	drd0,
    
	output [31:0] 	ir
);

	wire        inst_sram_we;
  	wire [31:0] inst_sram_addr;
  	wire [31:0] inst_sram_wdata;
  	wire [31:0] inst_sram_rdata;
  	wire        data_sram_we;
  	wire [31:0] data_sram_addr;
  	wire [31:0] data_sram_wdata;
  	wire [31:0] data_sram_rdata;

  	wire        inst_valid;
  	wire        inst_ready;
  	wire        inst_addr_valid;
  	wire        inst_addr_ready;

  	wire [31:0] inst_mem_raddr;
  	wire [31:0] inst_mem_rdata;


  	mycpu_LA32 cpu (
      	.clk (clk),
      	.resetn(rstn),

      	.inst_sram_we(inst_sram_we),
      	.inst_sram_addr(inst_sram_addr),
      	.inst_sram_wdata(inst_sram_wdata),
      	.inst_sram_rdata(inst_sram_rdata),

      	.data_sram_we		(data_sram_we),
      	.data_sram_addr  (data_sram_addr),
      	.data_sram_wdata (data_sram_wdata),
      	.data_sram_rdata (data_sram_rdata),

      	.inst_valid(inst_valid),
      	.inst_ready(inst_ready),
      	.inst_addr_valid(inst_addr_valid),
      	.inst_addr_ready(inst_addr_ready)
  	);

  	i_cache u_icache (
      	.clk           (clk),
      	.resetn        (rstn),
      	.raddr         (inst_sram_addr),
      	.rdata         (inst_sram_rdata),
      	.addr_ready    (inst_addr_ready),
      	.addr_valid    (inst_addr_valid),
      	.inst_valid    (inst_valid),
      	.inst_ready    (inst_ready),
      	.inst_mem_raddr(inst_mem_raddr),
      	.inst_mem_rdata(inst_mem_rdata)
  	);
  
  	data_ram u_data_ram (
      	.clk(clk),
      	.we (data_sram_we),
      	.a  (data_sram_addr[17:2]),
      	.d  (data_sram_wdata),
      	.spo(data_sram_rdata),
      	//debug
      	.dpra(dra0),
        .dpo (drd0)
  	);

  	inst_ram u_inst_ram (
      	.clk(clk),
      	.we (inst_sram_we),
      	.a  (inst_mem_raddr),
      	.d  (inst_sram_wdata),
      	.spo(inst_mem_rdata)
  	);

  	assign ir = inst_sram_rdata;

endmodule