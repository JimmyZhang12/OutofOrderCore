 module Rename(
	input CLK,
	input RESET,
	input [4:0] arch_regA,// arch.A register from Decode stage
	input [4:0] arch_regB,// arch.B register from Decode Stage
	input [4:0] write_reg,// arch. register to write back from Decode stage
	input regWrite,

	input [5:0] reg_FreeList_WB, // the register in which we want to write back to free list. This will come from retire/commit
	input FreeList_WB // if we want to write back to free list, set to 1. This will come from retire/commit

	input Stall,

	output reg [5:0] phy_regA_out,// physical register read from FRAT
	output reg [5:0] phy_regB_out,// physical register read  from FRAT
	output reg [5:0] phy_regWrite_out, // physical register from Free List that we assigned to
	output stall_signal, // set to one when we run out of registers to rename.

	// passing other informations
	input [31:0] Instr1_In,
	input [31:0] Instr1_PC_IN,
	input ALU_Control1_IN,
	input MemRead1_IN,
	input MemWrite1_IN,
	input ShiftAmount1_IN,
	//Instruction being passed to EXE [debug]
	output reg [31:0]Instr1_OUT,
	//PC of instruction being passed to EXE [debug]
	output reg [31:0]Instr1_PC_OUT,
	//we'll be writing to a register... passed to EXE
	output reg RegWrite1_OUT,
	//ALU control passed to EXE
	output reg [5:0]ALU_Control1_OUT,
	//This is a memory read (passed to EXE)
	output reg MemRead1_OUT,
	//This is a memory write (passed to EXE)
	output reg MemWrite1_OUT,
	//Shift amount [for ALU functions] (passed to EXE)
	output reg [4:0]ShiftAmount1_OUT,
	
);



reg [5:0] FreeList[5:0]; // free list. each need 6 lists to see content
reg [6:0] FreeListPointer; // this will be set to how many entries is in Free List right now. We need 64 since max is 64 and min is 0 

wire [5:0] FRAT_outA;
wire [5:0] FRAT_outB;

assign stall_signal = (FreeListPointer == 0)&&regWrite; // if we have to write to a register for this instruction, but theres nothing in free list, we must stall


FRAT RAT(
	.arch_regA(arch_regA),
	.arch_regB(arch_regB),
	.arch_reg_write(write_reg),
	.reg_to_change(FreeList[0]),
	.want_write(regWrite),

	// output

	.phy_regA(FRAT_outA),
	.phy_regB(FRAT_outB)
);

integer i;

always @(posedge CLK or negedge RESET) begin
	if(!RESET) begin
		for(i=0;i<=63;i++)begin
			FreeList[i] = i;
		end
		FreeListPointer = 64;
		Instr1_OUT = 0;
		Instr1_PC_OUT = 0;
		RegWrite1_OUT = 0;
		ALU_Control1_OUT = 0;
		MemRead1_OUT = 0;
		MemWrite1_OUT = 0;
		ShiftAmount1_OUT = 0;
	end
	else begin
		if((FreeListPointer == 0) && regWrite)begin // if we cant do anything since we're stalling, dont do anything

		end else begin
			if(!Stall)begin // if other pipeline is not requesting anything
				phy_regA_out = FRAT_outA; // assign Rename stage output
				phy_regB_out = FRAT_outB; // assign Rename stage output
				phy_regWrite_out = 0; // assign written to register to 0 for now. We will grab this from free list later
				if(regWrite) begin // if this instruction wants to write to a register
					phy_regWrite_out = FreeList[0]; // written to register is the first of free list.
					for(i=0;i<63;i++)begin 
						FreeList[i] = FreeList[i+1]; //pushing free list forward by one slot until we reach 62
					end
					FreeList[63] = 0; // set toeh last free list entry to 0
					FreeListPointer = FreeListPointer - 1; // wenow have one less free register
				end
				if(FreeListWB)begin // if commit is saying we are adding a new register to free list
					FreeList[FreeListPointer-1] = reg_FreeList_WB; // add that one to the where pointer points
					FreeListPointer = FreeListPointer + 1; // we now have 1 more free register
				end
				// pass on everything else
				Instr1_OUT = Instr1_IN;
				Instr1_PC_OUT = Instr1_PC_IN;
				RegWrite1_OUT = regWrite;
				ALU_Control1_OUT = ALU_Control1_IN;
				MemRead1_OUT = MemRead1_IN;
				MemWrite1_OUT = MemWrite1_IN;
				ShiftAmount1_OUT = ShiftAmount1_IN;
			end
		end

end




endmodule
