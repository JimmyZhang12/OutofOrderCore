//-----------------------------------------
//           RAT
//-----------------------------------------

`define LOG_ARCH    $clog2(NUM_ARCH_REGS)
`define LOG_PHYS    $clog2(NUM_PHYS_REGS)

module RAT #(
	/*
	 * NUM_ARCH_REGS is the number of architectural registers present in the
	 * RAT.
	 *
	 * sim_main assumes that the value of LO is stored in architectural
	 * register 33, and that the value of HI is stored in architectural
	 * register 34.
	 *
	 * It is left as an exercise to the student to explain why.
	 */
    parameter NUM_ARCH_REGS = 35,
    parameter NUM_PHYS_REGS = 64

    /* Maybe Others? */
)
(
	input [4:0] arch_regA;
	input [4:0] arch_regB;
	input [4:0] arch_reg_write;
	input [5:0] reg_to_change;
	input want_write;

	output [5:0] phy_regA;
	output [5:0] phy_regB;

	//added by jimmy
	output reg overwritten_reg;
	output reg [`LOG_PHYS-1:0] RAT_CDB [NUM_ARCH_REGS-1:0];

    /* Write Me */
		);

// actual RAT memory
reg [`LOG_PHYS-1:0] regPtrs [NUM_ARCH_REGS-1:0] /*verilator public_flat*/;

assign RAT_CBD = regPtrs;
assign phy_regA = regPtrs[arch_regA]; // instant read
assign phy_regB = regPtrs[arcj_regB]; // instant read

integer i;

always @(posedge CLK or negedge RESET) begin
	if(!RESET) begin
		for(i=0;i<35;i++)begin
			regPtrs[i] = 0;
		end
	end
	else begin
		if(want_write)begin
		    overwritten_reg = regPtrs[arch_reg_write];
			regPtrs[arch_reg_write] = reg_to_change;
		end
	end

end
    /* Write Me */


endmodule

