//THINGS TODO
//input instr needs valid? stall?
 module issue(
    //INSTRUCTION IN
	input CLK,
	input RESET,
	input STALL,
	input reg [5:0] phy_regA_IN,// physical register read from FRAT
	input reg [5:0] phy_regB_IN,// physical register read  from FRAT
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

	//INSTRUCTION OUT
	output reg [5:0] phy_regA_OUT,// physical register read from FRAT
	output reg [5:0] phy_regB_OUT,// physical register read  from FRAT
	output reg [5:0] phy_regWrite_OUT, // physical register from Free List that we assigned to
	output stall_signal, // set to one when we run out of registers to rename.
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

    output Valid, //did we issue an instr
    output STALL,

    //COMMON DATA BUS
	input  [511:0]BusyBits,

);

    reg [15:0]phy_regA_queue[5:0];// physical register read from FRAT
    reg [15:0]phy_regB_queue[5:0];// physical register read  from FRAT
    reg [15:0]phy_regWrite_queue[5:0]; // physical register from Free List that we assigned to

    reg [15:0]Instr1_queue[31:0];
    //PC of instruction being passed to EXE [debug]
    reg [15:0]Instr1_PC_queue[31:0];
    //we'll be writing to a register... passed to EXE
    reg [15:0]RegWrite1_queue;
    //ALU control passed to EXE
    reg [15:0]ALU_Contro1_queue[5:0];
    //This is a memory read (passed to EXE)
    reg [15:0]MemRead1_queue;
    //This is a memory write (passed to EXE)
    reg [15:0]MemWrite1_queue; //debug
    //Shift amount [for ALU functions] (passed to EXE)
    reg [15:0]ShiftAmount1_queue[4:0];

    //queue control
    reg [15:0]Instr_Rdy;
    reg [15:0]Valid;
    reg [3:0]QueueLength;

    assign STALL = (QueueLength == 15)?0:1;

integer i;


always @(posedge CLK or negedge RESET) begin
	if(!RESET) begin
		//TODO
	end
	else begin
	    //WAKEUP AND SELECT

	    i = 0;
        while (i<=16)begin
            if(i == 16) begin
                Valid = 0;
            end
            if((BusyBits[phy_regA_queue[i]] && BusyBits[phy_regB_queue[i]]) || Instr_Rdy[i] )begin
                phy_regA_OUT = phy_regA_queue[i];
                phy_regB_OUT= phy_regB_queue[i];
                phy_regWrite_OUT = phy_regWrite_queue[i];
                Instr1_OUT= Instr1_queue[i];
                Instr1_PC_OUT = Instr1_PC_queue[i];
                RegWrite1_OUT = RegWrite1_queue[i];
                ALU_Control1_OUT = ALU_Contro1_queue[i];
                MemRead1_OUT= MemRead1_queue[i];
                MemWrite1_OUT= MemWrite1_queue[i];
                ShiftAmount1_OUT= ShiftAmount1_queue[i];

                Instr_Rdy[i] = 0;
                Valid[i] = 0;
                QueueLength = QueueLength -1;

                Valid = 1;
                break;
            end

            i = i + 1;
        end
        //COMPACTING
        i = 0
        while (i<15)begin
            if(valid([i+1]) && !valid([i]))begin
                phy_regA_queue[i+1] = phy_regA_queue[i];
                phy_regB_queue[i+1]= phy_regB_queue[i];
                phy_regWrite_queue[i+1] = phy_regWrite_queue[i];
                Instr1_queue[i+1]= Instr1_queue[i];
                Instr1_PC_queue[i+1] = Instr1_PC_queue[i];
                RegWrite1_queue[i+1] = RegWrite1_queue[i];
                ALU_Contro1_queue[i+1] = ALU_Contro1_queue[i];
                MemRead1_queue[i+1]= MemRead1_queue[i];
                MemWrite1_queue[i+1]= MemWrite1_queue[i];
                ShiftAmount1_queue[i+1]= ShiftAmount1_queue[i];

                Instr_Rdy[i+1] = Instr_Rdy[i];
            end

            i = i + 1;
        end
        //newly vacated spot at end of queue is not ready or valid
        Instr_Rdy[i]=1;
        Valid[i] = 0;

        //add new instr to end of queue
        if(!STALL && QueueLength < 16)begin
            phy_regA_queue[QueueLength] = phy_regA_IN;
            phy_regB_queue[QueueLength] = phy_regB_IN;
            phy_regWrite_queue[QueueLength] = phy_regWrite_IN;
            Instr1_queue[QueueLength] = Instr1_IN;
            Instr1_PC_queue[QueueLength] = Instr1_PC_IN;
            RegWrite1_queue[QueueLength] = RegWrite1_IN;
            ALU_Contro1_queue[QueueLength] = ALU_Contro1_IN;
            MemRead1_queue[QueueLength] = MemRead1_IN;
            MemWrite1_queue[QueueLength] = MemWrite1_IN;
            ShiftAmount1_queue[QueueLength] = ShiftAmount1_IN;
            Valid[QueueLength] = 1;
            QueueLength = QueueLength + 1;


        end
        else begin
        end

end




endmodule
