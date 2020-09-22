


`define LOG_PHYS	$clog2(NUM_PHYS_REGS)

module PhysRegFile #(
    parameter NUM_PHYS_REGS = 64,
    input CLK,
    input STALL,

    //From Issue
    input reg [5:0]srcA_Issue_IN,
    input reg [5:0]srcB_Issue_IN,
    input reg [5:0] phy_regWrite_IN, // physical register from Free List that we assigned to
	input reg [31:0]Instr1_IN,
	//PC of instruction being passed to EXE [debug]
	input reg [31:0]Instr1_PC_IN,
	//we'll be writing to a register... passed to EXE
	input reg RegWrite1_IN,
	//ALU control passed to EXE
	input reg [5:0]ALU_Control1_IN,
	//This is a memory read (passed to EXE)
	input reg MemRead1_IN,
	//This is a memory write (passed to EXE)
	input reg MemWrite1_IN,
	//Shift amount [for ALU functions] (passed to EXE)
	input reg [4:0]ShiftAmount1_IN,

    //to EXE
    output [63:0]srcA_Issue_2EXE_OUT,
    output [63:0]srcB_Issue_2EXE_OUT,
    output [63:0]destRegData_2EXE_OUT, //some instructions read dest data like mfhi,mflo
    output reg [5:0] phy_regWrite_2EXE_OUT, // physical register from Free List that we assigned to
	output reg [31:0]Instr1_2EXE_OUT,
	//PC of instruction being passed to EXE [debug]
	output reg [31:0]Instr1_PC_2EXE_OUT,
	//we'll be writing to a register... passed to EXE
	output reg RegWrite1_2EXE_OUT,
	//ALU control passed to EXE
	output reg [5:0]ALU_Control1_2EXE_OUT,
	//This is a memory read (passed to EXE)
	output reg MemRead1_2EXE_OUT,
	//This is a memory write (passed to EXE)
	output reg MemWrite1_2EXE_OUT,
	//Shift amount [for ALU functions] (passed to EXE)
	output reg [4:0]ShiftAmount1_2EXE_OUT,
	output reg [31:0]MemWriteData1_2EXE_OUT,

	//From EXE (write to PRreg)
    input reg [31:0] Instr1_FEXE_IN, //debug
    //PC [debug] to MEM
    input reg [31:0] Instr1_PC_FEXE_IN,//debug
    //Our ALU results to MEM
    input reg [31:0] ALU_result1_FEXE_IN,
    //What register gets the data (or store from) to MEM
    input reg [4:0] WriteRegister1_FEXE_IN,
    //Whether we will write to a register
    input reg RegWrite1_FEXE_IN,
    //ALU Control (actually used by MEM)
    input reg [5:0] ALU_Control1_FEXE_IN,



    //retire read
    input [5:0]srcA_Retire_IN,
    input [5:0]srcB_Retire_IN,

    //retire data out
    output [63:0]srcA_Retire_OUT,
    output [63:0]srcB_Retire_OUT,


    //preg write
    input reg [63:0]DCacheData_IN,
    input reg [63:0]DCacheReg_IN,
    input DCache_Valid,


    //Did rename push instr and is it busy
    input BusyBit_Rename_Valid;
    input BusyBit_Rename_IN;
    //Busybit CDB
    output BusyBit_CDB[31:0];




	);

    reg [63:0] PReg [NUM_PHYS_REGS-1:0] /*verilator public*/;
    reg BusyBits[NUM_PHYS_REGS-1:0];

    assign BusyBit_CDB = BusyBits;

always @(posedge CLK)begin
    if(!STALL)begin
        //writes
        if(BusyBit_Rename_Valid)begin
            BusyBit[BusyBit_Rename_IN] <= 1;
        end

        if(DCache_Valid)begin
            PReg[DCacheReg_IN] <= DCacheData_IN;
            BusyBit[DCacheReg_IN] <= 0;
        end
        if(RegWrite1_FEXE_IN)begin
            case(ALU_Control1_FEXE_IN)
                //6'b000101, 6'b000110,6'b001101,6'b001001,6'b001010:begin //div,divu,mult,multu
                //    PReg[WriteRegister1_FEXE_IN] <= ALU_result1_FEXE_IN;
                //end
                6'b001011:begin//mfhi
                    PReg[WriteRegister1_FEXE_IN] <= {ALU_result1_FEXE_IN[31:0],32'h00000000};
                end
                6'b001100:begin //mflo
                    PReg[WriteRegister1_FEXE_IN] <= {32'h00000000,ALU_result1_FEXE_IN[31:0]};
                end
                default begin
                    PReg[WriteRegister1_FEXE_IN] <= ALU_result1_FEXE_IN;

                end
            endcase
            BusyBit[WriteRegister1_FEXE_IN] <= 0;
        end

        //reads
        srcA_Issue_OUT <= PReg[srcA_Issue_IN];
        srcB_Issue_OUT <= PReg[srcB_Issue_IN];
        MemWriteData1_OUT < = PReg[srcA_Issue_IN]; //TODO: check if opA is correct for store
        destRegData_OUT <= PReg[phy_regWrite_IN];

        srcA_Retire_OUT <= PReg[srcA_Retire_IN];
        srcB_Retire_OUT <= PReg[srcB_Retire_IN];

        //pass from issue to exe
        phy_regWrite_OUT <= phy_regWrite_IN; // physical register from Free List that we assigned to
        Instr1_IN_OUT <= Instr1_IN;
        //PC of instruction being passed to EXE [debug]
        Instr1_PC_OUT <= Instr1_PC_IN;
        //we'll be writing to a register... passed to EXE
        RegWrite1_OUT <= RegWrite1_IN;
        //ALU control passed to EXE
        ALU_Control1_OUT <= ALU_Control1_IN,
        //This is a memory read (passed to EXE)
        MemRead1_OUT <= MemRead1_IN,
        //This is a memory write (passed to EXE)
        MemWrite1_OUT <= MemWrite1_IN,
        //Shift amount [for ALU functions] (passed to EXE)
        ShiftAmount1_OUT <= ShiftAmount1_IN,


   	 end
end


endmodule
