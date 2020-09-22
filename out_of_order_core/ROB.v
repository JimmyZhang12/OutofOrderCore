module ROB(
	input CLK,
	input RESET,
	input Instr_Valid_rename,

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


	output stall_signal,

	// output information about first entry of ROB to R-RAT.
	// If the done is 1, then we have to write to R-RAT.
	output [5:0] ROB_phy_reg_write0,
	output [4:0] ROB_arch_reg_write0,
	//added by Jimmy
	output mispredict_recover;
	//line to cache
    output MemWrite_2DM;
	output [31:0]data_write_2DM;
	output [31:0]data_address_2DM;
	output [1:0]data_write_size_2DM

);
reg comment = 1;

reg [5:0] ROB_phy_regA [63:0];
reg [5:0] ROB_phy_regB [63:0];
reg [31:0] ROB_instr_PC [63:0];
reg [31:0] ROB_instr [63:0];
reg [31:0] ROB_instr_age [63:0];
reg ROB_ready_2_commit [63:0];
reg [4:0] ROB_arch_regA [63:0];
reg [4:0] ROB_arch_regB [63:0];
reg [6:0] ROB_num_count; // if this value is 64, that means all ROB is full and we should stall fetching.
reg [5:0] ROB_phy_write [63:0];
reg [4:0] ROB_arch_write [63:0];
//added by Jimmy
reg [31:0] ROB_ALU_result[63:0]; //for store destination
reg [31:0] ROB_store_data[63:0]; //for store data
reg [31:0] ROB_branch_taken[63:0];
reg [5:0] physReg_buffer_OUT;


reg [6:0] i;
reg [6:0] j;

wire [5:0] ROB_num_pointer;

//added by Jimmy
wire isBranch;
wire opCode = ROB_instr[0][31:26];

assign ROB_phy_reg_write0 = ROB_phy_write[0];
assign ROB_arch_reg_write0 = ROB_arch_write[0];
assign ROB_done0 = ROB_ready_2_commit[0];
//added by Jimmy

assign mispredict_recover = ROB_branch_taken[0];
assign isBranch = (opCode == 6b'000101) || (opCode == 6b'000001)|| (opCode == 6b'000110)|| (opCode == 6b'000111)|| (opCode == 6b'000001)|| (opCode == 6b'000100);
assign (isBranch)? mispredict_recover = ROB_branch_taken[0]:0;

assign stall_signal = (ROB_num_count == 7'b1000000);
assign ROB_num_pointer = ROB_num_count[5:0];

/* verilator lint_off BLKSEQ */
always @(posedge CLK or negedge RESET) begin
	if(!RESET) begin
		for(i=0;i<=63;i++)begin
			ROB_phy_regA[i[5:0]] = 0;
			ROB_phy_regB[i[5:0]] = 0;
			ROB_instr_PC[i[5:0]] = 0;
			ROB_instr[i[5:0]] = 0;
			ROB_instr_age[i[5:0]] = 0;
			ROB_ready_2_commit[i[5:0]] = 0;
			ROB_arch_regA[i[5:0]] = 0;
			ROB_arch_regB[i[5:0]] = 0;

			ROB_phy_write[i[5:0]] = 0;
			ROB_arch_write[i[5:0]] = 0;
			//added by Jimmy
			ROB_ALU_result[i[5:0]] = 0;
			ROB_store_data[i[5:0]] = 0;
			ROB_branch_taken[i[5:0]] = 0;

		end
		ROB_num_count = 0;
	end else begin
		if(!stall_signal) begin
			// if the first entry ROB we need to push that out of the ROB and having it go to R-RAT.
			// R-RAT part is already done OUTSIDE of this always loop.
            data_address_2DM = ROB_ALU_result[0];
            //if store, commit
            case(ROB_instr[0][31:26])begin //the opcode for instr at head of ROB
                6'b101111: begin	//SB
                        data_write_size_2DM=1;
                        data_write_2DM[7:0] = ROB_store_data[0][7:0];
                        end
                6'b110000: begin	//SH
                        data_write_size_2DM=2;
                        data_write_2DM[15:0] = ROB_store_data[0][15:0];
                        end
                6'b110001, 6'b110110: begin	//SW/SC
                        data_write_size_2DM=0;
                        data_write_2DM = ROB_store_data[0];
                        end
                6'b110010: begin	//SWL
                        case( ROB_ALU_result[0][1:0] )
                            0: begin data_write_2DM = ROB_store_data[0]; data_write_size_2DM=0; end
                            1: begin data_write_2DM[23:0] = ROB_store_data[0][31:8]; data_write_size_2DM=3; end
                            2: begin data_write_2DM[15:0] = ROB_store_data[0][31:16]; data_write_size_2DM=2; end
                            3: begin data_write_2DM[7:0] = ROB_store_data[0][31:24]; data_write_size_2DM=1; end
                        endcase
                        end
                6'b110011: begin	//SWR
                        data_address_2DM = {ROB_ALU_result[0][31:2],2'b00};
                        case( ROB_ALU_result[0][1:0] )
                            //TODO: this may be wrong. It needs to be tested.
                            0: begin data_write_2DM[7:0] = ROB_store_data[0][7:0]; data_write_size_2DM=1; end
                            1: begin data_write_2DM[15:0] = ROB_store_data[0][15:0]; data_write_size_2DM=2; end
                            2: begin data_write_2DM[23:0] = ROB_store_data[0][23:0]; data_write_size_2DM=3; end
                            3: begin data_write_2DM = ROB_store_data[0]; data_write_size_2DM=0; end
                        endcase
            endcase


            for(j=0;j<63;j++)begin
                ROB_phy_regA[j[5:0]] = ROB_phy_regA[j[5:0]+1];
                ROB_phy_regB[j[5:0]] = ROB_phy_regB[j[5:0]+1];
                ROB_instr_PC[j[5:0]] = ROB_instr_PC[j[5:0]+1];
                ROB_instr[j[5:0]] = ROB_instr[j[5:0]+1];
                ROB_instr_age[j[5:0]] = ROB_instr_age[j[5:0]+1];
                ROB_ready_2_commit[j[5:0]] = ROB_ready_2_commit[j[5:0]+1];
                ROB_arch_regA[j[5:0]] = ROB_arch_regA[j[5:0]+1];
                ROB_arch_regB[j[5:0]] = ROB_arch_regB[j[5:0]+1];
                ROB_phy_write[j[5:0]] = ROB_phy_write[j[5:0]+1];
                ROB_arch_write[j[5:0]] = ROB_arch_write[j[5:0]+1];
                //added by jimmy
                ROB_ALU_result[j[5:0]] = ROB_ALU_result[j[5:0]+1];
                ROB_store_data[j[5:0]] = ROB_store_data[j[5:0]+1];
                ROB_branch_taken[j[5:0]] = ROB_branch_taken[j[5:0]+1];
            end
            ROB_num_count = ROB_num_count - 1;
            ROB_phy_regA[63] = 0;
            ROB_phy_regB[63] = 0;
            ROB_instr_PC[63] = 0;
            ROB_instr[63] = 0;
            ROB_instr_age[63] = 0;
            ROB_ready_2_commit[63] = 0;
            ROB_arch_regA[63] = 0;
            ROB_arch_regB[63] = 0;
            ROB_phy_write[63] = 0;
            ROB_arch_write[63] = 0;
            //added by Jimmy
            ROB_ALU_result[63] = 0;
            ROB_store_data[63] = 0;
            ROB_branch_taken[63] = 0;
        end

        if(Instr_Valid_rename)begin
            // writing from rename to ROB entry.
            ROB_phy_regA[ROB_num_pointer] = phy_regA_in_rename;
            ROB_phy_regB[ROB_num_pointer] = phy_regB_in_rename;
            ROB_instr_PC[ROB_num_pointer] = instr_PC_rename;
            ROB_instr[ROB_num_pointer] = instr_rename;
            ROB_instr_age[ROB_num_pointer] = instr_age_rename;
            ROB_ready_2_commit[ROB_num_pointer] = 0;

            ROB_arch_regA[ROB_num_pointer] = arch_regA_in_rename;
            ROB_arch_regB[ROB_num_pointer] = arch_regB_in_rename;

            ROB_phy_write[ROB_num_pointer] = phy_reg_write_in_rename;
            ROB_arch_write[ROB_num_pointer] = arch_reg_write_in_rename;
            // once instruction gets out of MEM stage, its done. We can now commit it if its head of ROB.
            // this part will search in ROB for an instruction age. If it matches, set the DONE bit to one.
            // the code will then see if the first entry in ROB has the done bit of 1. If it is, commit that part.

            ROB_num_count = ROB_num_count + 1;
        end
        if(ROB_num_count != 0 || EXE_Commit || MEM_Commit)begin //if instr has been executed in rest of pipeline
            for(i=0;i<=ROB_num_count-1;i++)begin
                if(EXE_Commit)begin
                    if(ROB_instr_age[i[5:0]] == instr_age_done_EXE)begin
                        ROB_ready_2_commit[i[5:0]] = 1;
                        ROB_branch_taken[i[5:0]] = branch_taken_fEXE;
                    end
                end
                if(MEM_Commit)begin
                    if(ROB_instr_age[i[5:0]] == instr_age_done_MEM)begin
                        ROB_ready_2_commit[i[5:0]] = 1;
                        ROB_ALU_result[i[5:0]] = store_dest_MEM;
                        ROB_store_data[i[5:0]] = store_data_MEM; //for store data
                    end

                end
            end
        end

			//end main loop

    end
		if(comment)begin
			for(i=0;i<=63;i++)begin
				$display("ROB[%d]: phy_regA: %d, phy_regB: %d, phy_write_reg: %d, instr_PC: %x, instr: %x, instr_age: %x, ready_2_commit: %b, arch_regA: %d, arch_regB: %d, arch_write_reg: %d",i,ROB_phy_regA[i[5:0]],ROB_phy_regB[i[5:0]],ROB_phy_write[i[5:0]],ROB_instr_PC[i[5:0]],ROB_instr[i[5:0]],ROB_instr_age[i[5:0]],ROB_ready_2_commit[i[5:0]],ROB_arch_regA[i[5:0]],ROB_arch_regB[i[5:0]],ROB_arch_write[i[5:0]]);
			end
			$display("ROB_couter %d", ROB_num_count);
		end
	end
end
/* verilator lint_on BLKSEQ */

endmodule
