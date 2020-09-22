/* verilator lint_off BLKSEQ */
module RenameQueue(
	input flush,
	input CLK,
	input RESET, 
	input STALL,

	input  [31:0]Instr1_IN,
	input  [31:0]Instr1_PC_IN,
	input  [31:0]OperandA1_IN,
	input  [31:0]OperandB1_IN,
	input  [4:0]ReadRegisterA1_IN,
	input  [4:0]ReadRegisterB1_IN,
	input  [4:0]WriteRegister1_IN,
	input  [31:0]MemWriteData1_IN,
	input  RegWrite1_IN,
	input  [5:0]ALU_Control1_IN,
	input  MemRead1_IN,
	input  MemWrite1_IN,
	input  [4:0]ShiftAmount1_IN,
	input ID_Valid,


	output reg [31:0]Instr1_OUT,
	output reg [31:0]Instr1_PC_OUT,
	output reg [31:0]OperandA1_OUT,
	output reg [31:0]OperandB1_OUT,
	output reg [4:0]ReadRegisterA1_OUT,
	output reg [4:0]ReadRegisterB1_OUT,
	output reg [4:0]WriteRegister1_OUT,
	output reg [31:0]MemWriteData1_OUT,
	output reg RegWrite1_OUT,
	output reg [5:0]ALU_Control1_OUT,
	output reg MemRead1_OUT,
	output reg MemWrite1_OUT,
	output reg [4:0]ShiftAmount1_OUT,
	output reg Instr_Valid_OUT,

	output RenameQueue_Full,

	input RN_STALL

);


	//Instruction being passed to EXE [debug]
	 reg [31:0]Instr1_OUT_queue[7:0];
	//PC of instruction being passed to EXE [debug]
	 reg [31:0]Instr1_PC_OUT_queue[7:0];
	//OperandA passed to EXE
	 reg [31:0]OperandA1_OUT_queue[7:0];
	//OperandB passed to EXE
	 reg [31:0]OperandB1_OUT_queue[7:0];
	//RegisterA passed to EXE
	 reg [4:0]ReadRegisterA1_OUT_queue[7:0];
	//RegisterB passed to EXE
	 reg [4:0]ReadRegisterB1_OUT_queue[7:0];
	//Destination Register passed to EXE
	 reg [4:0]WriteRegister1_OUT_queue[7:0];
	//Data to write to memory passed to EXE [for store]
	 reg [31:0]MemWriteData1_OUT_queue[7:0];
	//we'll be writing to a register... passed to EXE
	 reg RegWrite1_OUT_queue[7:0];
	//ALU control passed to EXE
	 reg [5:0]ALU_Control1_OUT_queue[7:0];
	//This is a memory read (passed to EXE)
	 reg MemRead1_OUT_queue[7:0];
	//This is a memory write (passed to EXE)
	 reg MemWrite1_OUT_queue[7:0];
	//Shift amount [for ALU functions] (passed to EXE)
	 reg [4:0]ShiftAmount1_OUT_queue[7:0];

	// added by Hsin

	reg [3:0] Queue_counter;
	reg Instr_Valid_Queue[0:7];

	reg [3:0] i; // for loop purposes

	 //reg [31:0] temp32 [0:6];
	 //reg [5:0] temp6 [0:6];
	 //reg [4:0] temp5 [0:6];
	 //reg temp1 [0:6];

	//integer i;

assign RenameQueue_Full = (Queue_counter == 8)&& RN_STALL;
always @(posedge CLK or negedge RESET) begin
	if(!RESET) begin

		for (i = 0; i < 8; i = i + 1) begin
			Instr1_OUT_queue[i[2:0]] = 0;
			Instr1_PC_OUT_queue[i[2:0]] = 0;
			OperandA1_OUT_queue[i[2:0]] = 0;
			OperandB1_OUT_queue[i[2:0]] = 0;
			ReadRegisterA1_OUT_queue[i[2:0]] = 0;
			ReadRegisterB1_OUT_queue[i[2:0]] = 0;
			WriteRegister1_OUT_queue[i[2:0]] = 0;
			MemWriteData1_OUT_queue[i[2:0]] = 0;
			RegWrite1_OUT_queue[i[2:0]] = 0;
			ALU_Control1_OUT_queue[i[2:0]] = 0;
			MemRead1_OUT_queue[i[2:0]] = 0;
			MemWrite1_OUT_queue[i[2:0]] = 0;
			ShiftAmount1_OUT_queue[i[2:0]] = 0;
			// added by Hsin
			Instr_Valid_Queue[i[2:0]] = 0;
    		end
		Queue_counter = 0;

    	end
	else if(CLK) begin
        	if(!STALL) begin
			if(flush) begin
				for (i = 0; i < 8; i = i + 1) begin
					 Instr1_OUT_queue[i[2:0]] = 0;
					 Instr1_PC_OUT_queue[i[2:0]] = 0;
					 OperandA1_OUT_queue[i[2:0]] = 0;
					 OperandB1_OUT_queue[i[2:0]] = 0;
					 ReadRegisterA1_OUT_queue[i[2:0]] = 0;
					 ReadRegisterB1_OUT_queue[i[2:0]] = 0;
					 WriteRegister1_OUT_queue[i[2:0]] = 0;
					 MemWriteData1_OUT_queue[i[2:0]] = 0;
					 RegWrite1_OUT_queue[i[2:0]] = 0;
					 ALU_Control1_OUT_queue[i[2:0]] = 0;
					 MemRead1_OUT_queue[i[2:0]] = 0;
					 MemWrite1_OUT_queue[i[2:0]] = 0;
					 ShiftAmount1_OUT_queue[i[2:0]] = 0;
					// added by Hsin
					Instr_Valid_Queue[i[2:0]] = 0;
				end
				Queue_counter = 0;
			end
			else begin
				if(!RN_STALL)begin
					Instr1_OUT = Instr1_OUT_queue[7];
					Instr1_PC_OUT = Instr1_PC_OUT_queue[7];
					OperandA1_OUT = OperandA1_OUT_queue[7];
					OperandB1_OUT = OperandB1_OUT_queue[7];
					ReadRegisterA1_OUT = ReadRegisterA1_OUT_queue[7];
					ReadRegisterB1_OUT = ReadRegisterB1_OUT_queue[7];
					WriteRegister1_OUT = WriteRegister1_OUT_queue[7];
					MemWriteData1_OUT = MemWriteData1_OUT_queue[7];
					RegWrite1_OUT = RegWrite1_OUT_queue[7];
					ALU_Control1_OUT = ALU_Control1_OUT_queue[7];
					MemRead1_OUT = MemRead1_OUT_queue[7];
					MemWrite1_OUT = MemWrite1_OUT_queue[7];
					ShiftAmount1_OUT = ShiftAmount1_OUT_queue[7];
					Instr_Valid_OUT = Instr_Valid_Queue[7];
					
					for(i=0;i<7;i++)begin
						Instr1_OUT_queue[i[2:0]+1] = Instr1_OUT_queue[i[2:0]];
						Instr1_PC_OUT_queue[i[2:0]+1] = Instr1_PC_OUT_queue[i[2:0]];
						OperandA1_OUT_queue[i[2:0]+1] = OperandA1_OUT_queue[i[2:0]];
						OperandB1_OUT_queue[i[2:0]+1] = OperandB1_OUT_queue[i[2:0]];
						ReadRegisterA1_OUT_queue[i[2:0]+1] = ReadRegisterA1_OUT_queue[i[2:0]];
						ReadRegisterB1_OUT_queue[i[2:0]+1] = ReadRegisterB1_OUT_queue[i[2:0]];
						WriteRegister1_OUT_queue[i[2:0]+1] = WriteRegister1_OUT_queue[i[2:0]];
						MemWriteData1_OUT_queue[i[2:0]+1] = MemWriteData1_OUT_queue[i[2:0]];
						RegWrite1_OUT_queue[i[2:0]+1] = RegWrite1_OUT_queue[i[2:0]];
						ALU_Control1_OUT_queue[i[2:0]+1] = ALU_Control1_OUT_queue[i[2:0]];
						MemRead1_OUT_queue[i[2:0]+1] = MemRead1_OUT_queue[i[2:0]];
						MemWrite1_OUT_queue[i[2:0]+1] = MemWrite1_OUT_queue[i[2:0]];
						ShiftAmount1_OUT_queue[i[2:0]+1] = ShiftAmount1_OUT_queue[i[2:0]];
						Instr_Valid_Queue[i[2:0]+1] = Instr_Valid_Queue[i[2:0]];

					end
					Instr1_OUT_queue[0] = 0;
					Instr1_PC_OUT_queue[0] = 0;
					OperandA1_OUT_queue[0] = 0;
					OperandB1_OUT_queue[0] = 0;
					ReadRegisterA1_OUT_queue[0] = 0;
					ReadRegisterB1_OUT_queue[0] = 0;
					WriteRegister1_OUT_queue[0] = 0;
					MemWriteData1_OUT_queue[0] = 0;
					RegWrite1_OUT_queue[0] = 0;
					ALU_Control1_OUT_queue[0] = 0;
					MemRead1_OUT_queue[0] = 0;
					MemWrite1_OUT_queue[0] = 0;
					ShiftAmount1_OUT_queue[0] = 0;
					Instr_Valid_Queue[0] = 0;
					if(Queue_counter>0) begin
						Queue_counter = Queue_counter - 1;
					end
				end
				
				if(ID_Valid)begin
					Instr1_OUT_queue[7-Queue_counter[2:0]] = Instr1_IN;
					Instr1_PC_OUT_queue[7-Queue_counter[2:0]] = Instr1_PC_IN;
					OperandA1_OUT_queue[7-Queue_counter[2:0]] = OperandA1_IN;
					OperandB1_OUT_queue[7-Queue_counter[2:0]] = OperandB1_IN;
					ReadRegisterA1_OUT_queue[7-Queue_counter[2:0]] = ReadRegisterA1_IN;
					ReadRegisterB1_OUT_queue[7-Queue_counter[2:0]] = ReadRegisterB1_IN;
					WriteRegister1_OUT_queue[7-Queue_counter[2:0]] = WriteRegister1_IN;
					MemWriteData1_OUT_queue[7-Queue_counter[2:0]] = MemWriteData1_IN;
					RegWrite1_OUT_queue[7-Queue_counter[2:0]] = RegWrite1_IN;
					ALU_Control1_OUT_queue[7-Queue_counter[2:0]] = ALU_Control1_IN;
					MemRead1_OUT_queue[7-Queue_counter[2:0]] = MemRead1_IN;
					MemWrite1_OUT_queue[7-Queue_counter[2:0]] = MemWrite1_IN;
					ShiftAmount1_OUT_queue[7-Queue_counter[2:0]] = ShiftAmount1_IN;
					Instr_Valid_Queue[7-Queue_counter[2:0]] = ID_Valid;
					if(Queue_counter < 8)begin
						Queue_counter = Queue_counter+1;
					end
				end



				
			end 
        	end
	$display("	Rename Queue Dump:  Instr1_OUT_queue   Instr1_PC_OUT_queue   ReadRegisterA1_OUT_queue   ReadRegisterB1_OUT_queue   WriteRegister1_OUT_queue");
	for(i=0;i<=7;i++)begin
	$display("	                 %d  %x %x %d %d %d",i, Instr1_OUT_queue[i[2:0]], Instr1_PC_OUT_queue[i[2:0]], ReadRegisterA1_OUT_queue[i[2:0]], ReadRegisterB1_OUT_queue[i[2:0]],WriteRegister1_OUT_queue[i[2:0]]);
	end
    end



end

/*
				temp32 = Instr1_OUT_queue[6:0];
				Instr1_OUT_queue[7:1] = temp32;
				Instr1_OUT_queue[0] = Instr1_IN;
				Instr1_OUT = Instr1_OUT_queue[7];

				temp32 = Instr1_PC_OUT_queue[6:0];
				Instr1_PC_OUT_queue[7:1] = temp32;
				Instr1_PC_OUT_queue[0] = Instr1_PC_IN;
				Instr1_PC_OUT = Instr1_PC_OUT_queue[7];

				temp32 = OperandA1_OUT_queue[6:0];
				OperandA1_OUT_queue[7:1] = temp32;
				OperandA1_OUT_queue[0] = OperandA1_IN;
				OperandA1_OUT = OperandA1_OUT_queue[7];

				temp32 = OperandB1_OUT_queue[6:0];
				OperandB1_OUT_queue[7:1] = temp32;
				OperandB1_OUT_queue[0] = OperandB1_IN;
				OperandB1_OUT = OperandB1_OUT_queue[7];

				temp5 = ReadRegisterA1_OUT_queue[6:0];
				ReadRegisterA1_OUT_queue[7:1] = temp5;
				ReadRegisterA1_OUT_queue[0] = ReadRegisterA1_IN;
				ReadRegisterA1_OUT = ReadRegisterA1_OUT_queue[7];

				temp5 = ReadRegisterB1_OUT_queue[6:0];
				ReadRegisterB1_OUT_queue[7:1] = temp5;
				ReadRegisterB1_OUT_queue[0] = ReadRegisterB1_IN;
				ReadRegisterB1_OUT = ReadRegisterB1_OUT_queue[7];

				temp5 = WriteRegister1_OUT_queue[6:0];
				WriteRegister1_OUT_queue[7:1] = temp5;
				WriteRegister1_OUT_queue[0] = WriteRegister1_IN;
				WriteRegister1_OUT = WriteRegister1_OUT_queue[7];

				temp32 = MemWriteData1_OUT_queue[6:0];
				MemWriteData1_OUT_queue[7:1] = temp32;
				MemWriteData1_OUT_queue[0] = MemWriteData1_IN;
				MemWriteData1_OUT = MemWriteData1_OUT_queue[7];

				temp1 = RegWrite1_OUT_queue[6:0];
				RegWrite1_OUT_queue[7:1] = temp1;
				RegWrite1_OUT_queue[0] = RegWrite1_IN;
				RegWrite1_OUT = RegWrite1_OUT_queue[7];

				temp6 = ALU_Control1_OUT_queue[6:0];
				ALU_Control1_OUT_queue[7:1] = temp6;
				ALU_Control1_OUT_queue[0] = ALU_Control1_IN;
				ALU_Control1_OUT = ALU_Control1_OUT_queue[7];

				temp1 = MemRead1_OUT_queue[6:0];
				MemRead1_OUT_queue[7:1] = temp1;
				MemRead1_OUT_queue[0] = MemRead1_IN;
				MemRead1_OUT = MemRead1_OUT_queue[7];

				temp1 = MemWrite1_OUT_queue[6:0];
				MemWrite1_OUT_queue[7:1] = temp1;
				MemWrite1_OUT_queue[0] = MemWrite1_IN;
				MemWrite1_OUT = MemWrite1_OUT_queue[7];

				temp5 = ShiftAmount1_OUT_queue[6:0];
				ShiftAmount1_OUT_queue[7:1] = temp5;
				ShiftAmount1_OUT_queue[0] = ShiftAmount1_IN;
				ShiftAmount1_OUT = ShiftAmount1_OUT_queue[7];

*/

endmodule
