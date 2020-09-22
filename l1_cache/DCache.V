//2am version
module DCache(
	input RESET,
	input CLK,
	
	//used by both Loads and Writes
	input [31:0] address_fMEM, 				//an address from mem
	input [31:0] data_fMEM,					//a word from mem
	output [31:0] addr_2MainMem,			//address of a word to MainMem
	output cache_busy, 						//whether cache can accept load or store requests, stall whenever cache_busy high

	//LOADS
	//between MEM and cache
	input wantLoad_fMEM,					//if MEM sends load request
	output  data_out_valid_2MEM,			//is data_out valid, valid on cache_state 9 and 10
	output  [31:0] data_2MEM,				//acutal word fetched for MEM
	//between cache and MainMem
	input [31:0] data_FMainMem,				//word of data fetched from main mem
	output wantRead_2MainMem,				//when high, main mem reads addr_2MainMem, returns data_FMainMem

	//WRITES
	//from MEM and cache
	input wantWrite_fMEM,					//MEM sends write request
	//between cache and MainMem
	output wantwrite_2MainMem,				//when high, main mem reads addr_2MainMem
	output [31:0] data_2MainMem,			//the data be written to MainMem

	//which of these should be regs?
)

//DEFINE CACHE
//offset is 6 bits since 8 words per block,
//block is 32 bytes, 8 words, 255 bits, 
//index is log(512) = 9 bits
//tag is 32-9-6 = 17 bits
reg cache_state[3:0]
		//0: idling, MEM can only send load/store request at this state 
		//1: retrieving first word from a block, writing word 1 of cache to Mainmem if dirty
		//2. Return word 2 to cache, writing word 2 of cache to Mainmem if dirty
		//3. Return word 3 to cache, writing word 3 of cache to Mainmem if dirty
		//4. Return word 4 to cache, writing word 4 of cache to Mainmem if dirty
		//5. Return word 5 to cache, writing word 5 of cache to Mainmem if dirty
		//6. Return word 6 to cache, writing word 6 of cache to Mainmem if dirty
		//7. Return word 7 to cache, writing word 7 of cache to Mainmem if dirty
		//8. Return word 8 to cache, writing word 8 of cache to Mainmem if dirty
		//9: Cache is readable after clearing dirty block for loads
		//10:Update cache block after clearing dirty block
		
reg [255:0] main_cache_set1 [511:0]; // main memory space for first set
reg [255:0] main_cache_set2 [511:0]; // main memory space for second set
reg main_cache_valid1 [511:0]; // valid bit for first set
reg main_cache_valid2 [511:0]; // valid bit for second set
reg main_cache_dirty1  [511:0]; // dirty bit for first set
reg main_cache_dirty2 [511:0]; // dirty bit for second set
reg [19:0] main_cache_tag1 [511:0]; // tag bits for first set
reg [19:0] main_cache_tag2 [511:0]; // tag bits for second set
reg main_cache_last_used [511:0]; // for Least Recently used. set to one if set 1 was recently used, and 0 if 2 
//END CACHE DEFINITION

//parse tag and index and offset from instr
reg [16:0] instr_tag ; // this is tag bits from the input addr
reg [8:0] instr_index; // this is index bits from input addr
reg [5:0] instr_offset;

reg dirty_Block_write //on a read, if we must write the dirty block to MainMem before evicting it
reg write_data; //hold data on cache write, need to hold data through 8 cycle block fetch

//compare cache tags
reg tag_match1; // set to 1 if tag matches
reg tag_match2; // set to 1 if tag matches

reg handling_write; //during the 8 cycle block fetch, are we handling a missed write or missed read?


always @(posedge CLK or negedge RESET)begin
	if(!RESET) begin
		//TODO: reset functionality
		
	end else begin
		case (cache_state) 
		4'b0000:begin
					//idling cache doesn't stall and isnt outputting data
					//these may be uncessary but its easier to think about
					data_out_valid_2MEM = 0;
					wantRead_2MainMem = 0;
					wantwrite_2MainMem = 0;
					
					cache_busy=0;

					if(wantLoad_fMEM) begin //idling cache receives load request
						instr_tag = address_fMEM[31:15];  //grabbing tag from Instr_address_fMEM
						instr_index = address_fMEM[14:6]; //grabbing index from Instr_address_fMEM
						instr_offset = address_fMEM[5:0]; //grabbing offest from Instr_address_fMEM
											
						tag_match1 = (main_cache_tag1[instr_index] == instr_tag)?1'b1:1'b0; // assigning tag match bit for set 1
						tag_match2 = (main_cache_tag2[instr_index] == instr_tag)?1'b1:1'b0; // assign tag match bit for set 2
						
						cache_busy=1;
						
						if(tag_match1 && main_cache_valid1[instr_index])begin //hit in set 1	
							data_out=main_cache_set1[instr_index][(instr_offset+1)*8-1:instr_offset*8];
							main_cache_last_used[instr_index] = 1;
							cache_state = 9;
						end
						else if(tag_match2 &&  main_cache_valid2[instr_index]) begin //hit in set 2
							data_out=main_cache_set2[instr_index][(instr_offset+1)*8-1:instr_offset*8];
							main_cache_last_used[instr_index] = 2;
							cache_state = 9;
						end
						else begin //read miss
							if(main_cache_last_used[instr_index]) begin //if last used is 1, evict in 2
								if(main_cache_dirty2[instr_index])begin
									dirty_Block_write = 1;
								end
							end
							else begin	//if last used is 2, evict in 1
								if(main_cache_dirty1[instr_index])begin 
									dirty_Block_write = 1;
								end
							end 
							handling_write = 0;
							cache_state = 1;
						end
					end
					
					else if(wantWrite_fMEM) begin //idling cache receives write request
						instr_tag = address_fMEM[31:15]; 
						instr_index = address_fMEM[14:6]; 
						instr_offset = address_fMEM[5:0]; 
						
						tag_match1 = (main_cache_tag1[instr_index] == instr_tag)?1'b1:1'b0; // assigning tag match bit for set 1
						tag_match2 = (main_cache_tag2[instr_index] == instr_tag)?1'b1:1'b0; // assign tag match bit for set 2
						
						write_data = data_2MEM;
						
						if(tag_match1 && main_cache_valid1[instr_index])begin //write hit in set 1	
							main_cache_set1[instr_index][(instr_offset+1)*8-1:instr_offset*8]=write_data;
							main_cache_last_used[instr_index] = 1;
							main_cache_dirty1[instr1_index] = 1; //we didn't update main mem so this block is dirty
							cache_state = 0; //return to idling, dont need a cycle for reading cache unlike load miss

							
						end
						else if(tag_match2 &&  main_cache_valid2[instr_index]) begin //write hit in set 2
							main_cache_set2[instr_index][(instr_offset+1)*8-1:instr_offset*8]=write_data;
							main_cache_last_used[instr_index] = 0;
							main_cache_dirty2[instr1_index] = 1; //we didn't update main mem so this block is dirty
							cache_state = 0;

						end
						else begin //write miss, so write allocate 
							if(main_cache_last_used[instr_index]) begin //if last used is 1, evict in 2
								if(main_cache_dirty2[instr_index])begin
									dirty_Block_write = 1;
								end
							end
							else begin	//if last used is 2, evict in 1
								if(main_cache_dirty1[instr_index])begin 
									dirty_Block_write = 1;
								end
							end 
							handling_write = 1;
							cache_state = 1;
						end
					end
	
		
				end
		4'b0001:begin //get the first word of block
					wantwrite_2MainMem = 0;
					wantRead_2MainMem = 0;
					if (main_cache_last_used[instr_index])begin
						if(dirty_Block_write)begin //if the block being overwritten is dirty, simutaneously write that block to MainMem
							addr_2MainMem = {main_cache_tag2[instr_index],instr_index, 6'b000000};
							data_2MainMem = main_cache_set2[instr_index][31:0];
							//-----------------------FIGURE OUT IF YOU CAN DO THIS --------------------------------------------------------------------------------------------------
							wantwrite_2MainMem = 1; 
							wantwrite_2MainMem = 0;
							//---------------------------------------------------------------------------------------------------------------------------------------------------------

						end
						
						addr_2MainMem = {instr_tag,instr_index, 6'b000000};
						wantRead_2MainMem = 1;
						main_cache_set2[instr_index][31:0]=data_FMainMem;

					end	
					else begin
						if(dirty_Block_write)begin //if the block being overwritten is dirty, simutaneously write it to MainMem
							addr_2MainMem = {main_cache_tag1[instr_index],instr_index, 6'b000000};
							data_2MainMem = main_cache_set1[instr_index][31:0];
							wantwrite_2MainMem = 1;
							wantwrite_2MainMem = 0;
							
						end
						
						addr_2MainMem = {instr_tag,instr_index, 6'b000000};
						wantRead_2MainMem = 1;
						main_cache_set1[instr_index][31:0]=data_FMainMem;
					end	
					cache_state = 2;
			 	end
		4'b0010:begin //2
					wantwrite_2MainMem = 0;
					wantRead_2MainMem = 0;
					if (main_cache_last_used[instr_index])begin
						if(dirty_Block_write)begin //if the block being overwritten is dirty, simutaneously write that block to MainMem
							addr_2MainMem = {main_cache_tag2[instr_index],instr_index, 6'b000100};
							data_2MainMem = main_cache_set2[instr_index][63:32];
							wantwrite_2MainMem = 1;
							wantwrite_2MainMem = 0;
						end
						
						addr_2MainMem = {instr_tag,instr_index, 6'b000100};
						wantRead_2MainMem = 1;
						main_cache_set2[instr_index][63:32]=data_FMainMem;

					end	
					else begin
						if(dirty_Block_write)begin //if the block being overwritten is dirty, simutaneously write it to MainMem
							addr_2MainMem = {main_cache_tag1[instr_index],instr_index, 6'b000100};
							data_2MainMem = main_cache_set1[instr_index][63:32];
							wantwrite_2MainMem = 1;
							wantwrite_2MainMem = 0;
						end
						
						addr_2MainMem = {instr_tag,instr_index, 6'b000100};
						wantRead_2MainMem = 1;
						main_cache_set1[instr_index][63:32]=data_FMainMem;

					end	
					cache_state = 3;
			  	end
		4'b0011:begin //3
					wantwrite_2MainMem = 0;
					wantRead_2MainMem = 0;
					if (main_cache_last_used[instr_index])begin
						if(dirty_Block_write)begin //if the block being overwritten is dirty, simutaneously write that block to MainMem
							addr_2MainMem = {main_cache_tag2[instr_index],instr_index, 6'b001000};
							data_2MainMem = main_cache_set2[instr_index][95:64];
							wantwrite_2MainMem = 1;
							wantwrite_2MainMem = 0;
						end
						
						addr_2MainMem = {instr_tag,instr_index, 6'b001000};
						main_cache_set2[instr_index][95:64]=data_FMainMem;
						wantRead_2MainMem = 1;

					end	
					else begin
						if(dirty_Block_write)begin //if the block being overwritten is dirty, simutaneously write it to MainMem
							addr_2MainMem = {main_cache_tag1[instr_index],instr_index, 6'b001000};
							data_2MainMem = main_cache_set1[instr_index][95:64];
							wantwrite_2MainMem = 1;
							wantwrite_2MainMem = 0;
						end
						
						addr_2MainMem = {instr_tag,instr_index, 6'b001000};
						wantRead_2MainMem = 1;
						main_cache_set1[instr_index][95:64]=data_FMainMem;

					end	
					cache_state = 4;
				end
		4'b0100:begin //4
					wantwrite_2MainMem = 0;
					wantRead_2MainMem = 0;
					if (main_cache_last_used[instr_index])begin
						if(dirty_Block_write)begin //if the block being overwritten is dirty, simutaneously write that block to MainMem
							addr_2MainMem = {main_cache_tag2[instr_index],instr_index, 6'b001100};
							data_2MainMem = main_cache_set2[instr_index][127:96];
							wantwrite_2MainMem = 1;
							wantwrite_2MainMem = 0;
						end
						
						addr_2MainMem = {instr_tag,instr_index, 6'b001100};
						wantRead_2MainMem = 1;	
						main_cache_set2[instr_index][127:96]=data_FMainMem;


					end	
					else begin
						if(dirty_Block_write)begin //if the block being overwritten is dirty, simutaneously write it to MainMem
							addr_2MainMem = {main_cache_tag1[instr_index],instr_index, 6'b001100};
							data_2MainMem = main_cache_set1[instr_index][127:96];
							wantwrite_2MainMem = 1;
							wantwrite_2MainMem = 0;
						end
						
						addr_2MainMem = {instr_tag,instr_index, 6'b001100};
						wantRead_2MainMem = 1;
						main_cache_set1[instr_index][127:96]=data_FMainMem;

					end	
					cache_state = 5;
				end
		4'b0101:begin //5
					wantwrite_2MainMem = 0;
					wantRead_2MainMem = 0;
					if (main_cache_last_used[instr_index])begin
						if(dirty_Block_write)begin //if the block being overwritten is dirty, simutaneously write that block to MainMem
							addr_2MainMem = {main_cache_tag2[instr_index],instr_index, 6'b010000};
							data_2MainMem = main_cache_set2[instr_index][159:128];
							wantwrite_2MainMem = 1;
							wantwrite_2MainMem = 0;
						end
						
						addr_2MainMem = {instr_tag,instr_index, 6'b010000};
						wantRead_2MainMem = 1;
						main_cache_set2[instr_index][159:128]=data_FMainMem;


					end	
					else begin
						if(dirty_Block_write)begin //if the block being overwritten is dirty, simutaneously write it to MainMem
							addr_2MainMem = {main_cache_tag1[instr_index],instr_index, 6'b010000};
							data_2MainMem = main_cache_set1[instr_index][159:128];
							wantwrite_2MainMem = 1;
							wantwrite_2MainMem = 0;
						end
						
						addr_2MainMem = {instr_tag,instr_index, 6'b010000};
						wantRead_2MainMem = 1;
						main_cache_set1[instr_index][159:128]=data_FMainMem;

					end	
					cache_state = 6;
				end
		4'b0110:begin //6
					wantwrite_2MainMem = 0;
					wantRead_2MainMem = 0;
					if (main_cache_last_used[instr_index])begin
						if(dirty_Block_write)begin //if the block being overwritten is dirty, simutaneously write that block to MainMem
							addr_2MainMem = {main_cache_tag2[instr_index],instr_index, 6'b010100};
							data_2MainMem = main_cache_set2[instr_index][191:160];
							wantwrite_2MainMem = 1;
							wantwrite_2MainMem = 0;
						end
						
						addr_2MainMem = {instr_tag,instr_index, 6'b010100};
						wantRead_2MainMem = 1;
						main_cache_set2[instr_index][191:160]=data_FMainMem;


					end	
					else begin
						if(dirty_Block_write)begin //if the block being overwritten is dirty, simutaneously write it to MainMem
							addr_2MainMem = {main_cache_tag1[instr_index],instr_index, 6'b010100};
							data_2MainMem = main_cache_set1[instr_index][191:160];
							wantwrite_2MainMem = 1;
							wantwrite_2MainMem = 0;
						end
						
						addr_2MainMem = {instr_tag,instr_index, 6'b010100};
						wantRead_2MainMem = 1;
						main_cache_set1[instr_index][191:160]=data_FMainMem;
						
					end	
					cache_state = 7;
				end
		4'b0111:begin //7
					wantwrite_2MainMem = 0;
					wantRead_2MainMem = 0;
					if (main_cache_last_used[instr_index])begin
						if(dirty_Block_write)begin //if the block being overwritten is dirty, simutaneously write that block to MainMem
							addr_2MainMem = {main_cache_tag2[instr_index],instr_index, 6'b011000};
							data_2MainMem = main_cache_set2[instr_index][223:192];
							wantwrite_2MainMem = 1;
							wantwrite_2MainMem = 0;
						end
						
						addr_2MainMem = {instr_tag,instr_index, 6'b011000};
						wantRead_2MainMem = 1;
						main_cache_set2[instr_index][223:192]=data_FMainMem;


					end	
					else begin
						if(dirty_Block_write)begin //if the block being overwritten is dirty, simutaneously write it to MainMem
							addr_2MainMem = {main_cache_tag1[instr_index],instr_index, 6'b011000};
							data_2MainMem = main_cache_set1[instr_index][223:192];
							wantwrite_2MainMem = 1;
							wantwrite_2MainMem = 0;
						end
						
						
						addr_2MainMem = {instr_tag,instr_index, 6'b011000};
						wantRead_2MainMem = 1;
						main_cache_set1[instr_index][223:192]=data_FMainMem;
					end	
					cache_state = 8;
				end
		4'b1000:begin //8 last word loaded of block
					wantwrite_2MainMem = 0;
					wantRead_2MainMem = 0;
					if (main_cache_last_used[instr_index])begin
						if(dirty_Block_write)begin //if the block being overwritten is dirty, simutaneously write it to MainMem
							addr_2MainMem = {main_cache_tag2[instr_index],instr_index, 6'b011100};
							data_2MainMem = main_cache_set2[instr_index][255:224];
							wantwrite_2MainMem = 1;
							wantwrite_2MainMem = 0;
						end
						
						addr_2MainMem = {instr_tag,instr_index, 6'b011100};
						wantRead_2MainMem = 1;
						main_cache_set2[instr_index][255:224]=data_FMainMem;
						
						
					end	
					else begin
						if(dirty_Block_write)begin //if the block being overwritten is dirty, simutaneously write it to MainMem
							addr_2MainMem = {main_cache_tag1[instr_index],instr_index, 6'b011100};
							data_2MainMem = main_cache_set1[instr_index][255:224];
							wantwrite_2MainMem = 1;
							wantwrite_2MainMem = 0;
						end
						
						addr_2MainMem = {instr_tag,instr_index, 6'b011100};
						wantRead_2MainMem = 1;
						main_cache_set1[instr_index][255:224]=data_FMainMem;
					end
					wantRead_2MainMem = 0;

					if(handling_write)begin
						cache_state = 10; //finished handling write miss, no need to make cache transparent
					end
					else begin
						cache_state = 9; //finised handling load miss, make cache transparent
					end
					
				end
				//you can potentially combine states 9 and 10
		4'b1001:begin //9
					if (main_cache_last_used[instr_index])begin
						data_2MEM = main_cache_set2[instr_index][(instr_offset+4)*2-1:instr_offset*2];
						main_cache_valid2[instr_index] = 1; //the block is valid 
						main_cache_dirty2[instr_index] = 0; //just fetched block on load cannot be dirty
						main_cache_last_used[instr_index] = 0; //update LRU now that block fetch is done
					end
					else begin
						data_2MEM = main_cache_set1[instr_index][(instr_offset+4)*2-1:instr_offset*2];
						main_cache_valid1[instr_index] = 1; //the block is valid 
						main_cache_dirty1[instr1_index] = 0; //just fetched block on load cannot be dirty
						main_cache_last_used[instr_index] = 1;

					end
					cache_busy = 0;
					data_out_valid_2MEM = 1;
					cache_state = 0;
				end
		4'b1010:begin//10
					if (main_cache_last_used[instr_index])begin
						main_cache_set2[instr_index][(instr_offset+4)*2-1:instr_offset*2]=write_data;
						main_cache_valid2[instr_index] = 1; //the block is valid 
						main_cache_dirty2[instr_index] = 1; //just fetched block is dirty since did not write to main mem
						main_cache_last_used[instr_index] = 0; //update LRU now that block fetch is done

					end
					else begin
						main_cache_set1[instr_index][(instr_offset+4)*2-1:instr_offset*2]=write_data;
						main_cache_dirty1[instr_index] = 1;
						main_cache_valid2[instr_index] = 1; //the block is valid 
						main_cache_last_used[instr_index] = 1;						

					end
					cache_busy = 0;
					cache_state = 0;
				end		
				
		
		
		
	end
end

endmodule


