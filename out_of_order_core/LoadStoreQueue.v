module LoadStoreQueue(
    input CLK,
    input RESET,

    //INPUTS from EXE
	//Output of ALU (contains address to access, or data enroute to writeback)
	input EXE_valid_IN,
	input [31:0] ALU_result_EXE_IN,
	//The instruction from EXE requests a load
	input instr_age_EXE_IN,

    //INPUTS FROM RENAME
    //ALU control value (used to also specify the type of memory operation)
    input [5:0] ALU_Control_rename_IN,
    //What physical register will get our ultimate outputs
	input [4:0] WriteRegister_rename_IN,
    input MemRead_rename_IN,
    input MemWrite_rename_IN,
    input valid_rename_IN, //did rename output
    input instr_rename_IN, //instr itself (debug)
    input instrAge_rename_IN,


	//OUTPUT BUFFER going to physical reg file
	//What register we are writing to
	output reg valid_2Preg;
	output reg [4:0] WriteRegister_OUT,
	//And what data
	output reg [31:0] WriteData_OUT,

    //ROB wires
    output reg ROB_StorePending; //is a store at head of queue
    input reg ROB_StoreCommit; //did the ROB just commit a store

    //output to cache
	output reg[31:0] data_address_2DM,
	output reg MemRead_2DM,

    input [31:0] data_read_fDM,
	output MemFlush_2DM,
	input data_valid_fDM,
	output Mem_Needs_Stall,

	output queue_Full //the queue is full


)
//Load/store queue is program order FIFO

    reg data_read_aligned[31:0];
    assign WriteData_OUT = data_read_aligned;
    assign WriteRegister_OUT = WriteRegister_queue[15];

    //actual queue
	reg [31:0] ALU_result_queue [15:0];
    reg [4:0] WriteRegister_queue [15:0];
	reg [31:0] WriteData_queue [15:0];
	reg [5:0] ALU_Control_queue[15:0];
	reg MemRead_queue[15:0]; //1 is loads, 0 is stores
	reg ready_queue[15:0]
	reg valid_queue[15:0];
	reg [31:0]instrAge_queue{15:0];

    reg [4:0] queueLength;


    assign (queueLength==16)?(queue_Full = 1):(queue_Full=0);
integer i;
always(@posedge CLK)begin
    valid_2Preg = 0;
    if((MemRead_queue[15]|| ROB_StoreCommit) && data_valid_fDM )begin //we can dequeue
        if (data_valid_fDM)begin //are we doing a load
            case(ALU_Control_queue[15])
                6'b101101: begin
                    //LWL   (Load Word Left)
                    case (ALU_result[1:0])
                    0:  data_read_aligned = data_read_fDM;		//Aligned access; read everything
                    1:  data_read_aligned[31:8] = data_read_fDM[23:0];	//Mem:[3,2,1,0] => [2,1,0,8'h00]
                    2:  data_read_aligned[31:16] = data_read_fDM[15:0]; //Mem: [3,2,1,0] => [1,0,16'h0000]
                    3:  data_read_aligned[31:24] = data_read_fDM[7:0];	//Mem: [3,2,1,0] => [0,24'h000000]
                    endcase
                end
                6'b101110: begin
                    //LWR (Load Word Right)
                    case (ALU_result[1:0])
                    0:  data_read_aligned[7:0] = data_read_fDM[31:24];	//Mem:[3,2,1,0] => [2,1,0,8'h00]
                    1:  data_read_aligned[15:0] = data_read_fDM[31:16]; //Mem: [3,2,1,0] => [1,0,16'h0000]
                    2:  data_read_aligned[23:0] = data_read_fDM[31:8];	//Mem: [3,2,1,0] => [0,24'h000000]
                        3: data_read_aligned = data_read_fDM;		//Aligned access; read everything
                    endcase
                end
                6'b100001: begin
                    //LB (Load byte and sign-extend it)
                    case (ALU_result[1:0])
                        0: data_read_aligned={{24{data_read_fDM[31]}},data_read_fDM[31:24]};
                        1: data_read_aligned={{24{data_read_fDM[23]}},data_read_fDM[23:16]};
                        2: data_read_aligned={{24{data_read_fDM[15]}},data_read_fDM[15:8]};
                        3: data_read_aligned={{24{data_read_fDM[7]}},data_read_fDM[7:0]};
                    endcase
                end
                6'b101011: begin
                    //LH (Load halfword)
                    case( ALU_result[1:0] )
                        0:data_read_aligned={{16{data_read_fDM[31]}},data_read_fDM[31:16]};
                        2:data_read_aligned={{16{data_read_fDM[15]}},data_read_fDM[15:0]};
                    endcase
                end
                6'b101010: begin
                    //LBU (Load byte unsigned)
                    case (ALU_result[1:0])
                        0: data_read_aligned={{24{1'b0}},data_read_fDM[31:24]};
                        1: data_read_aligned={{24{1'b0}},data_read_fDM[23:16]};
                        2: data_read_aligned={{24{1'b0}},data_read_fDM[15:8]};
                        3: data_read_aligned={{24{1'b0}},data_read_fDM[7:0]};
                    endcase
                end
                6'b101100: begin
                    //LHU (Load halfword unsigned)
                    case( ALU_result[1:0] )
                        0:data_read_aligned={{16{1'b0}},data_read_fDM[31:16]};
                        2:data_read_aligned={{16{1'b0}},data_read_fDM[15:0]};
                    endcase
                end
                6'b111101, 6'b101000, 6'd0, 6'b110101: begin	//LW, LL, NOP, LWC1
                    data_read_aligned = data_read_fDM;
                end
            endcase
            valid_2Preg = 1;

        end
        else if (ROB_StoreCommit)begin
            RegWrite_OUT = 0;
        end

        //queue shifts right
        for(i=15;i>0;i--)begin
            ALU_result_queue[i] =  ALU_result_queue[i-1];
            WriteRegister_queue[i] = WriteRegister_queue[i-1];
            WriteData_queue[i] = WriteData_queue[i-1];
            ALU_Control_queue[i] = ALU_Control_queue[i-1];
            MemRead_queue[i] = MemRead_queue[i-1];
            ready_queue[i] = ready_queue[i-1];
        end
        queueLength = queueLength - 1;


    end

    //update connection to cache and ROB if load
    if(MemRead_queue[15])begin
        data_address_2DM = ALU_result_queue[15];
        MemRead_2DM = MemRead_queue[15];
        MemFlush_2DM = (ALU_result_queue[15] == 6'b000011);
        Mem_Needs_Stall = (MemRead_queue[15] || MemFlush_2DM) && !data_valid_fDM; //idk how this works
        ROB_StorePending = 0;

    end
    else begin
        ROB_StorePending = 1;
    end

    //TODO:search the queue upon EXE
    if(EXE_valid_IN)
        for (i=0;i<16;i++)begin
            if (instr_age_EXE_in == instrAge_queue[i])begin
                ALU_result_queue[i] = ALU_result_EXE_IN;
                ready_queue[i] = 1;
            end
        end
    end

    //can we enqueue
    if(valid_rename_IN &&(MemRead_rename_IN ||MemWrite_rename_IN))begin
            RegWrite_queue[15-queueLength] = RegWrite_rename_IN;
            ALU_Control_queue[15-queueLength] = ALU_Control_rename_IN;
            instrAge_rename[15-queueLength] = instrAge_rename_IN;
            //1 is loads, 0 is stores
            if(MemRead_rename_IN)begin
                MemRead_queue[15-queueLength] = 1;

            end
            else if (MemWrite_rename_IN)begin
                MemRead_queue[15-queueLength] = 0;

            end
            WriteRegister_queue[15-queueLength] = WriteRegister_rename_IN;
            WriteData_queue[15-queueLength] = WriteData_rename_IN;
            ready_queue[15-queueLength]= 0;
            queueLength = queueLength + 1;
        end

    end


end





endmodule



