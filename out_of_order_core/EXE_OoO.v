`include "config.v"

module EXE(
    input CLK,
    input RESET,
	 //Current instruction [debug]
    input [31:0] Instr1_IN,
    //Current instruction's PC [debug]
    input [31:0] Instr1_PC_IN,
    //Operand A (if already known)
    input [31:0] OperandA1_IN,
    //Operand B (if already known)
    input [31:0] OperandB1_IN,

    //normally this would be two regs HI and LO but combine into single 64 bit
    input [63:0] DestReg_Data_IN, //for mfhi, mflo

    //Destination register
    input [4:0] WriteRegister1_IN,
    //We do a register write
    input RegWrite1_IN,
    //ALU Control signal
    input [5:0] ALU_Control1_IN,
    //We read from memory (passed to MEM)
    input MemRead1_IN,
    //We write to memory (passed to MEM)
    input MemWrite1_IN,
    //Shift amount (needed for shift operations)
    input [4:0] ShiftAmount1_IN,
    input [31:0] InstrAge_IN;

    //broadcast Instruction out to MEM, PhysReg, and Commit
    output reg [31:0] Instr1_OUT,
    //PC [debug] to MEM
    output reg [31:0] Instr1_PC_OUT,
    //Our ALU results to MEM
    output reg [31:0] ALU_result1_OUT,
    //What register gets the data (or store from) to MEM
    output reg [4:0] WriteRegister1_OUT,
    //Data in WriteRegister1 (if known) to MEM
    output reg RegWrite1_OUT,
    //ALU Control (actually used by MEM)
    output reg [5:0] ALU_Control1_OUT,
    //We need to read from MEM (passed to MEM)
    output reg MemRead1_OUT,
    //We need to write to MEM (passed to MEM)
    output reg MemWrite1_OUT,

    output reg branchTaken_OUT,
    output reg [31:0]InstrAge_OUT,

//added by Hsin to manipulate stalling
	input IF_stall_request


    );

wire [31:0] A1;
wire [31:0] B1;
wire[31:0]ALU_result1;
wire compareOut_branchTaken;



assign A1 = OperandA1_IN;
assign B1 = OperandB1_IN;

//what do these do idk
reg [31:0] HI/*verilator public*/;
reg [31:0] LO/*verilator public*/;


//the HI and LO we are actually using
reg [31:0] actual_HI;
reg [31:0] acutal_LO;

assign actual_HI = DestReg_Data_IN[0:31];
assign acutal_LO = DestReg_Data_IN[32:63];

wire [31:0] HI_new1;
wire [31:0] LO_new1;
wire [31:0] new_HI;
wire [31:0] new_LO;

assign new_HI=HI_new1;
assign new_LO=LO_new1;

wire isMultorDiv;
//div,divu,mult,multu/mult,mfhi,mflo
assign isMultorDiv = (ALU_Control1_IN == 6'b000101) || (ALU_Control1_IN == 6'b000110) || (ALU_Control1_IN == 6'b001101) ||(ALU_Control1_IN == 6'b001001) || (ALU_Control1_IN == 6'b001010) || (ALU_Control1_IN == 6'b001011) || (ALU_Control1_IN == 6'b001100);


ALU ALU1(
    .aluResult(ALU_result1),
    .HI_OUT(HI_new1),
    .LO_OUT(LO_new1),
    .HI_IN(acutal_HI),
    .LO_IN(actual_LO),
    .A(A1),
    .B(B1),
    .ALU_control(ALU_Control1_IN),
    .shiftAmount(ShiftAmount1_IN),
    .CLK(!CLK)
    );

compare compare(
    .OpA(A1),
    .OpB(B1),
    .Instr_input(Instr1_IN), //compare just uses the first 6 bits
    .taken(compareOut_branchTaken),
    );



always @(posedge CLK or negedge RESET) begin
	if(!RESET) begin
		Instr1_OUT <= 0;
		Instr1_PC_OUT <= 0;
		ALU_result1_OUT <= 0;
		WriteRegister1_OUT <= 0;
		MemWriteData1_OUT <= 0;
		RegWrite1_OUT <= 0;
		ALU_Control1_OUT <= 0;
		MemRead1_OUT <= 0;
		MemWrite1_OUT <= 0;
		$display("EXE:RESET");
	end else if(CLK) begin
		if(!IF_stall_request)begin

		    //i dont know what these do
			HI <= new_HI;
			LO <= new_LO;


			Instr1_OUT <= Instr1_IN;
			Instr1_PC_OUT <= Instr1_PC_IN;

			if(isMultorDiv)begin
			    ALU_result1_OUT <= {HI_new1,LO_new1};
			end
			else begin
                ALU_result1_OUT <= ALU_result1;
			end

			WriteRegister1_OUT <= WriteRegister1_IN;
			RegWrite1_OUT <= RegWrite1_IN;
			ALU_Control1_OUT <= ALU_Control1_IN;
			MemRead1_OUT <= MemRead1_IN;
			MemWrite1_OUT <= MemWrite1_IN;
			branchTaken_OUT<=compareOut_branchTaken;
			InstrAge_OUT<=InstrAge_IN;

		end else begin
				$display("EXE:STALLING:Instr1=%x,Instr1_PC=%x,ALU_result1=%x; Write?%d to %d",Instr1_IN,Instr1_PC_IN,ALU_result1, RegWrite1_IN, WriteRegister1_IN);

		end
	end
end

endmodule
