/**************************************
* Module: RetireCommit
* Date:2013-12-10
* Author: isaac
*
* Description: Handles commits to the ROB, and retires instructions from the ROB.
*
* This is the last stop of this train. All passengers must exit.
***************************************/
`define LOG_PHYS    $clog2(NUM_PHYS_REGS)
module  RetireCommit #(
    parameter NUM_PHYS_REGS = 64
    /* You may want more parameters here */
)
(

	input CLK,
	input RESET,

	input Instr_Valid_in_rename,
	input [5:0] phy_regA_in_rename,
	input [5:0] phy_regB_in_rename,

	input [5:0] phy_reg_write_in_rename,

	input [4:0] arch_regA_in_rename,
	input [4:0] arch_regB_in_rename,

	input [4:0] arch_reg_write_in_rename,

	input [31:0] instr_PC_rename,
	input [31:0] instr_rename,
	input [31:0] instr_age_rename,


     //added by Jimmy
	input [31:0] instr_age_done_EXE,
	input [31:0] instr_age_done_MEM,
	input [31:0] store_dest_MEM;
	input [31:0] store_data_MEM
	input        branch_taken_fEXE;
	input        EXE_commit; //did EXE just finish an instr
	input        MEM_commit; //did MEM just finish an instr


	output mispredict_recover;
	//line to cache
    output MemWrite_2DM;
	output [31:0]data_write_2DM;
	output [31:0]data_address_2DM;
	output [1:0]data_write_size_2DM

	output stall_signal

);/*verilator public_module*/


wire [5:0] ROB_phy_reg_write0;
wire [4:0] ROB_arch_reg_write0;
wire ROB_done0;




/* verilator lint_off PINMISSING */
RAT RRAT(
	.CLK(CLK),
	.RESET(RESET),
	.arch_reg_write(ROB_arch_reg_write0),
	.reg_to_change(ROB_phy_reg_write0),
	.want_write(ROB_done0)
    /* Write Me */
);


ROB ROB(
	.CLK(CLK),
	.RESET(RESET),
	.phy_regA_in_rename(phy_regA_in_rename),
	.phy_regB_in_rename(phy_regB_in_rename),

	.phy_reg_write_in_rename(phy_reg_write_in_rename),

	.arch_regA_in_rename(arch_regA_in_rename),
	.arch_regB_in_rename(arch_regB_in_rename),

	.arch_reg_write_in_rename(arch_reg_write_in_rename),

	.instr_PC_rename(instr_PC_rename),
	.instr_rename(instr_rename),
	.instr_age_rename(instr_age_rename),
	.stall_signal(stall_signal),

	.ROB_phy_reg_write0(ROB_phy_reg_write0),
	.ROB_arch_reg_write0(ROB_arch_reg_write0),
	.ROB_done0(ROB_done0),

	.Instr_Valid(Instr_Valid_in_rename),

	//added by jimmy
	instr_age_done_EXE(instr_age_done_EXE),
	instr_age_done_MEM(instr_age_done_MEM),
	store_dest_MEM(store_dest_MEM),
	store_data_MEM(store_data_MEM),
	branch_taken_fEXE(branch_taken_fEXE),
	EXE_commit(EXE_commit), //did EXE just finish an instr
	MEM_commit(MEM_commit), //did MEM just finish an instr
	mispredict_recover(mispredict_recover),
	MemWrite_2DM(MemWrite_2DM),
	data_write_2DM(data_write_2DM),
	data_address_2DM(data_address_2DM),
	data_write_size_2D(data_write_size_2D),



    //added by Jimmy
	input [31:0] instr_age_done_EXE,
	input [31:0] instr_age_done_MEM,
	input [31:0] store_dest_MEM;
	input [31:0] store_data_MEM
	input        branch_taken_fEXE;
	input        EXE_commit; //did EXE just finish an instr
	input        MEM_commit; //did MEM just finish an instr
	output

	//added by Jimmy
	output mispredict_recover;
	//line to cache
    output MemWrite_2DM;
	output [31:0]data_write_2DM;
	output [31:0]data_address_2DM;
	output [1:0]data_write_size_2DM


);

    /* Write Me */
/* verilator lint_on PINMISSING */
endmodule

