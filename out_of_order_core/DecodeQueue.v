/* verilator lint_off BLKSEQ */
module DecodeQueue(
    input flush,
    input CLK,
    input RESET, 
    input IF_Valid,
    //This should contain the fetched instruction
    output [31:0] Instr_OUT_2ID,
    //This should contain the address of the fetched instruction [DEBUG purposes]
    output [31:0] Instr_PC_OUT_2ID,
    //This should contain the address of the instruction after the fetched instruction (used by ID)
    output [31:0] Instr_PC_Plus4_2ID,
    //Will be set to true if we need to just freeze the fetch stage.

	output Instr_Valid_2ID,

    //Address from which we want to fetch an instruction
    //Instruction received 
    input [31:0]   Instr_fIF,
    input [31:0]   Instr_PC_fIF,
    input [31:0]   Instr_PC_Plus4_fIF,
	output DecodeQueue_Full,
	// add later when other queues are done
	input ID_stall,

	input STALL
);

//reg STALL = 0;
//reg ID_stall = 0;
reg [31:0] Instr_Queue [0:7];
reg [31:0] Instr_PC_Queue [0:7];
reg [31:0] Instr_PC_Plus4_Queue [0:7];

//reg [31:0] temp [0:6];

//added by Hsin
reg Instr_Valid_Queue[0:7];

//reg temp_valid [0:6];

reg [3:0] Queue_counter;
// counting purposes
reg [3:0] i;

assign Instr_OUT_2ID = ID_stall?0:Instr_Queue[7];
assign Instr_PC_OUT_2ID = ID_stall?0:Instr_PC_Queue[7];
assign Instr_PC_Plus4_2ID = ID_stall?0:Instr_PC_Plus4_Queue[7];
assign Instr_Valid_2ID = ID_stall?0:Instr_Valid_Queue[7];

assign DecodeQueue_Full = (Queue_counter == 8) && ID_stall;
always @(posedge CLK or negedge RESET) begin
	if(!RESET) begin
		Instr_Queue[0] = 32'h00;
		Instr_Queue[1] = 32'h00;
		Instr_Queue[2] = 32'h00;
		Instr_Queue[3] = 32'h00;
		Instr_Queue[4] = 32'h00;
		Instr_Queue[5] = 32'h00;
		Instr_Queue[6] = 32'h00;
		Instr_Queue[7] = 32'h00;
		Instr_PC_Queue[0] = 32'h00;
		Instr_PC_Queue[1] = 32'h00;
		Instr_PC_Queue[2] = 32'h00;
		Instr_PC_Queue[3] = 32'h00;
		Instr_PC_Queue[4] = 32'h00;
		Instr_PC_Queue[5] = 32'h00;
		Instr_PC_Queue[6] = 32'h00;
		Instr_PC_Queue[7] = 32'h00;
		Instr_PC_Plus4_Queue[0] = 32'h00;
		Instr_PC_Plus4_Queue[1] = 32'h00;
		Instr_PC_Plus4_Queue[2] = 32'h00;
		Instr_PC_Plus4_Queue[3] = 32'h00;
		Instr_PC_Plus4_Queue[4] = 32'h00;
		Instr_PC_Plus4_Queue[5] = 32'h00;
		Instr_PC_Plus4_Queue[6] = 32'h00;
		Instr_PC_Plus4_Queue[7] = 32'h00;
		// added by Hsin

		Instr_Valid_Queue[0] = 0;
		Instr_Valid_Queue[1] = 0;
		Instr_Valid_Queue[2] = 0;
		Instr_Valid_Queue[3] = 0;
		Instr_Valid_Queue[4] = 0;
		Instr_Valid_Queue[5] = 0;
		Instr_Valid_Queue[6] = 0;
		Instr_Valid_Queue[7] = 0;

		Queue_counter = 0;
    	end
	else if(CLK) begin

		$display("	Decode Queue: Inputs: Instr1:%x Instr1_PC:%x IF_Valid:%x", Instr_fIF, Instr_PC_fIF, IF_Valid);
		$display("	DecodeQueue_Full: %b, STALL: %b, ID_stall: %b", DecodeQueue_Full, STALL, ID_stall);
        	if(!DecodeQueue_Full&&(!STALL))begin
			if(flush)begin
				Instr_Queue[0] = 32'h00;
				Instr_Queue[1] = 32'h00;
				Instr_Queue[2] = 32'h00;
				Instr_Queue[3] = 32'h00;
				Instr_Queue[4] = 32'h00;
				Instr_Queue[5] = 32'h00;
				Instr_Queue[6] = 32'h00;
				Instr_Queue[7] = 32'h00;
				Instr_PC_Queue[0] = 32'h00;
				Instr_PC_Queue[1] = 32'h00;
				Instr_PC_Queue[2] = 32'h00;
				Instr_PC_Queue[3] = 32'h00;
				Instr_PC_Queue[4] = 32'h00;
				Instr_PC_Queue[5] = 32'h00;
				Instr_PC_Queue[6] = 32'h00;
				Instr_PC_Queue[7] = 32'h00;
				Instr_PC_Plus4_Queue[0] = 32'h00;
				Instr_PC_Plus4_Queue[1] = 32'h00;
				Instr_PC_Plus4_Queue[2] = 32'h00;
				Instr_PC_Plus4_Queue[3] = 32'h00;
				Instr_PC_Plus4_Queue[4] = 32'h00;
				Instr_PC_Plus4_Queue[5] = 32'h00;
				Instr_PC_Plus4_Queue[6] = 32'h00;
				Instr_PC_Plus4_Queue[7] = 32'h00;

				// added by Hsin

				Instr_Valid_Queue[0] = 0;
				Instr_Valid_Queue[1] = 0;
				Instr_Valid_Queue[2] = 0;
				Instr_Valid_Queue[3] = 0;
				Instr_Valid_Queue[4] = 0;
				Instr_Valid_Queue[5] = 0;
				Instr_Valid_Queue[6] = 0;
				Instr_Valid_Queue[7] = 0;
				
				Queue_counter = 0;
			end
			else begin
				if(!ID_stall)begin

					for(i=0;i<7;i++)begin
						Instr_Queue[i[2:0]+1] = Instr_Queue[i[2:0]];
						Instr_PC_Queue[i[2:0]+1] = Instr_PC_Queue[i[2:0]];
						Instr_PC_Plus4_Queue[i[2:0]+1] = Instr_PC_Plus4_Queue[i[2:0]];
						Instr_Valid_Queue[i[2:0]+1] = Instr_Valid_Queue[i[2:0]];
					end

					Instr_Queue[0] = 0;
					Instr_PC_Queue[0] = 0;
					Instr_Valid_Queue[0] = 0;
					Instr_PC_Plus4_Queue[0] = 0;
					if(Queue_counter > 0)begin
						Queue_counter = Queue_counter-1;
					end
				end else begin
 
				end
				$display("	Decode Queue: %d", Queue_counter);
				Instr_Queue[7-(Queue_counter[2:0])] = Instr_fIF;
				Instr_PC_Queue[7-(Queue_counter[2:0])] = Instr_PC_fIF;
				Instr_Valid_Queue[7-(Queue_counter[2:0])] = IF_Valid;
				Instr_PC_Plus4_Queue[7-(Queue_counter[2:0])] = Instr_PC_Plus4_fIF;
				if(IF_Valid && (Queue_counter < 8) )begin
					Queue_counter = Queue_counter+1;
				end
/*
				temp = Instr_Queue[6:0];
				Instr_Queue[7:1] = temp;
				Instr_Queue[7-(Queue_counter[2:0]-1)] = Instr_fIF;

				temp = Instr_PC_Queue[6:0];
				Instr_PC_Queue[7:1] = temp;
				Instr_PC_Queue[Queue_counter[2:0]-1] = Instr_PC_fIF;

				temp_valid = Instr_Valid_Queue[6:0];
				Instr_Valid_Queue[7:1] = temp_valid;
				Instr_Valid_Queue[Queue_counter[2:0]-1] = IF_Valid;

				temp = Instr_PC_Plus4_Queue[6:0];
				Instr_PC_Plus4_Queue[7:1] = temp;
				Instr_PC_Plus4_Queue[Queue_counter[2:0]-1] = Instr_PC_Plus4_fIF;
*/


				
				$display("	Decode Queue Dump: IF_Valid:%b", IF_Valid);
			end 
        	end
    end
	$display("	Decode Queue: %d", Queue_counter);
	for(i=0;i<=7;i++)begin
		$display("    Decode Queue Dump: Instr_PC[%d]: %x, Instr[%d]: %x, Instr_Valid[%d], %b",i,Instr_PC_Queue[i[2:0]],i, Instr_Queue[i[2:0]],i, Instr_Valid_Queue[i[2:0]]);
	end

//$display("   Decode Queue Dump:\n     Instr_PC_0:%x Instr_0:%x:\n     Instr_PC_1:%x Instr_1:%x:\n     Instr_PC_2:%x Instr_2:%x:\n     Instr_PC_3:%x Instr_3:%x:\n     Instr_PC_4:%x Instr_4:%x:\n     Instr_PC_5:%x Instr_5:%x:\n     Instr_PC_6:%x Instr_6:%x:\n     Instr_PC_7:%x Instr_7:%x:\n",Instr_PC_Queue[0],Instr_Queue[0],Instr_PC_Queue[1],Instr_Queue[1],Instr_PC_Queue[2],Instr_Queue[2],Instr_PC_Queue[3],Instr_Queue[3],Instr_PC_Queue[4],Instr_Queue[4],Instr_PC_Queue[5],Instr_Queue[5],Instr_PC_Queue[6],Instr_Queue[6],Instr_PC_Queue[7],Instr_Queue[7]);


end



endmodule
