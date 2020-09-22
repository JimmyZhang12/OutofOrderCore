


`define LOG_PHYS	$clog2(NUM_PHYS_REGS)

module PhysRegFile #(
    parameter NUM_PHYS_REGS = 64
    input CLK,
    input STALL,
    //PReg read
    input srcA_IN,
    input srcB_IN,
    input dest_IN,

    output srcA_OUT,
    output srcB_OUT,
    output dest_OUT,

    //PReg write
    input DCacheData_IN,
    input DCacheReg_IN,
    input DCache_Valid,
    input EXEData_IN,
    input EXEReg_IN,
    input EXE_Valid

    //additional information to EXE
    input [31:0] Instr1_In,
	input [31:0] Instr1_PC_IN,
	input ALU_Control1_IN,
	input MemRead1_IN,
	input MemWrite1_IN,
	input ShiftAmount1_IN,

    output [31:0] Instr1_OUT,
	output [31:0] Instr1_PC_OUT,
	output ALU_Control1_OUT,
	output MemRead1_OUT,
	output MemWrite1_OUT,
	output ShiftAmount1_OUT,


    reg [31:0] PReg [NUM_PHYS_REGS-1:0] /*verilator public*/;
    //passing along additional info for EXE
    assign srcA_OUT = PReg[srcA_IN];
    assign srcB_OUT = PReg[srcB_IN];
    assign dest_IN = PReg[dest_IN];
    assign Instr1_OUT = Instr1_IN,
	assign Instr1_PC_OUT = Instr1_PC_IN,
	assign ALU_Control1_OUT = ALU_Control1_IN,
	assign MemRead1_OUT = MemRead1_IN,
	assign MemWrite1_OUT = MemWrite1_IN,
	assign ShiftAmount1_OUT = ShiftAmount1_IN,


    always @(posedge CLK)begin
   	 if(!STALL)begin
   		 if(DCache_Valid)begin
   			 PReg[DCacheReg_IN] = DCacheData_IN;
   		 end
   		 if(EXE_Valid)begin
   			 PReg[EXEReg_IN] = EXEData_IN;
   		 end
   	 end

	/* Write Me */

endmodule

