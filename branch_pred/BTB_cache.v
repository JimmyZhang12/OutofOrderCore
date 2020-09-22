//JIMMY: sometimes does not write when supposed to? Branch test fetches invalid PC upon a hit, but I'm not sure where its happaening in the first place 
//JIMMY: the caches itself is decoding the write request correctly
//JIMMY: I don't think error is here

 module BTB_cache(
	input [31:0] write_PC, // PC to write into cache
	input [31:0] read_PC, // PC to read from cache
	input [31:0] write_data, // this is what branch target data to write to
	output read_hit, // if cache hit, set to 1
	output [31:0] read_data_out, // read data output
	input write_bit_ID, // if write bit is 1 then we request to write to cache. This comes from ID
	
	input CLK,
	input RESET,
	input dont_read

);
//JIMMY: these are ok
	reg [31:0] main_cache_set1 [511:0]; // main memory space for first set
	reg [31:0] main_cache_set2 [511:0]; // main memory space for second set
	reg main_cache_valid1 [511:0]; // valid bit for first set
	reg main_cache_valid2 [511:0]; // valid bit for second set
	reg [20:0] main_cache_tag1 [511:0]; // tag bits for first set
	reg [20:0] main_cache_tag2 [511:0]; // tag bits for second set
	reg main_cache_last_used [511:0]; // for Least Recently used. set to one if set ? was recently used, and 0 if other way around

	reg [20:0] write_cache_tag ; // this is tag bits from the input write_PC
	reg [20:0] read_cache_tag; // this is tag bits from the input read_PC
	reg [8:0] write_cache_index; // this is index bits from input write_PC
	reg [8:0] read_cache_index; // this is index bits from input read_PC

	wire set_valid1; // set this to 1 if valid bit for this block is 1 (set1)
	wire set_valid2; // set this to 1 if valid bit for this block is 1 (set2)
	wire [31:0] read_data_out1; // read data out for first set block
	wire [31:0] read_data_out2; // read data out for second set block
	wire tag_match1_20; // XOR result between tag bits from PC and tag bits from block set 1
	wire tag_match2_20; // XOR result between tag bits from PC and tag bits from block set 2 
	wire tag_match1; // set to 1 if tag matches
	wire tag_match2; // set to 1 if tag matches
	//wire write_PC_1[31:0];
	//assign write_PC_1 = write_PC;
	assign write_cache_tag = write_PC[31:11]; // grabbing writing tag from write PC
	assign read_cache_tag = read_PC[31:11]; // grabbing read tag from read PC
	assign write_cache_index = write_PC[10:2]; // grabbing write index from write PC
	assign read_cache_index = read_PC[10:2]; // grabbing read index from read PC

	assign tag_match1 = (main_cache_tag1[read_cache_index] == read_cache_tag)?1'b1:1'b0; // assigning tag match bit for set 1
	assign tag_match2 = (main_cache_tag2[read_cache_index] == read_cache_tag)?1'b1:1'b0; // assign tag match bit for set 2

	assign set_valid1 = dont_read?1'b0:(main_cache_valid1[read_cache_index]?1'b1:1'b0); // checking valid bit for set 1
	assign set_valid2 = dont_read?1'b0:(main_cache_valid2[read_cache_index]?1'b1:1'b0); // checking valid bit for set 2
	assign read_data_out1 = main_cache_set1[read_cache_index]; // the data read out from set 1
	assign read_data_out2 = main_cache_set2[read_cache_index]; // the data read out from set 2
	
	assign read_hit = (set_valid1 && tag_match1)||(set_valid2 && tag_match2); // if the (tag for set 1 matches and its valid) or (tag for set 2 matches and its valid), its a hit
	assign read_data_out = (set_valid1 && tag_match1)? read_data_out1 : ((set_valid2 && tag_match2)? read_data_out2:32'b0); // if set 1 is valid and tag matches, output data is from set 1. if set 2 is valid and tag matches, output is from set 2.
	
//JIMMY: This is ok too
//JIMMY: I'm still not convinced on that reading and writing the ID bit though

integer reset_index;
always @(posedge CLK or negedge RESET)begin
	if(!RESET) begin

		for(reset_index = 0; reset_index <= 511; reset_index = reset_index+1) begin
			main_cache_set1[reset_index]=32'b0;
			main_cache_set2[reset_index]=32'b0;
			main_cache_tag1[reset_index]=21'b0;
			main_cache_tag2[reset_index]=21'b0;
			main_cache_valid1[reset_index]=1'b0;
			main_cache_valid2[reset_index]=1'b0;
			main_cache_last_used [reset_index] = 1'b0;
		end
		$display("Fetch: Resetting BTB.");
		// set whatever reset stuff we need here.
		//
	end else begin
		$display("Fetch: BTB read index: %x, BTB read tag: %x", read_cache_index,read_cache_tag);
		$display("read_data_out1 = %x, read_data_out2 %x, set_valid1 = %b, set_valid2 = %b, tag_match1 = %b, tag_match2 = %b ",read_data_out1,read_data_out2,main_cache_valid1[read_cache_index], set_valid2, tag_match1, tag_match2);
		if ((set_valid1 && tag_match1))begin // only update most recent used bit upon clock change.
			main_cache_last_used[read_cache_index]=0; 
		end else if ((set_valid2 && tag_match2)) begin
			main_cache_last_used[read_cache_index]=1;
		end

		if(write_bit_ID)begin

			if (main_cache_tag1[write_cache_index] == write_cache_tag) begin // if the tag we're writing to already exist in the cache, replace that one, and it doesnt matter if its LRU or not
				main_cache_set1[write_cache_index] = write_data;
				main_cache_tag1[write_cache_index] = write_cache_tag;
				main_cache_valid1[write_cache_index] = 1'b1;
				$display("Fetch: Writing to BTB: BTB Set 1 address of %x is now %x. Valid bit: %b, tag: %x",write_cache_index,main_cache_set1[write_cache_index],main_cache_valid1[write_cache_index],main_cache_tag1[write_cache_index]);
			end else if (main_cache_tag2[write_cache_index] == write_cache_tag) begin // if the tag we're writing to already exist in the cache, replace that one, and it doesnt matter if its LRU or not
				main_cache_set2[write_cache_index] = write_data;
				main_cache_tag2[write_cache_index] = write_cache_tag;
				main_cache_valid2[write_cache_index] = 1'b1;
				$display("Fetch: Writing to BTB: BTB Set 2 address of %x is now %x. Valid bit: %b, tag: %x",write_cache_index,main_cache_set2[write_cache_index],main_cache_valid2[write_cache_index],main_cache_tag2[write_cache_index]);
			end else begin
				if (main_cache_last_used[write_cache_index]) begin // if cache_last_used == 0, meaning set 1 is last used, we kick set 2
					main_cache_set2[write_cache_index] = write_data;
					main_cache_tag2[write_cache_index] = write_cache_tag;
					main_cache_valid2[write_cache_index] = 1'b1;
					$display("Fetch: Writing to BTB: BTB Set 2 address of %x is now %x. Valid bit: %b, tag: %x",write_cache_index,main_cache_set2[write_cache_index],main_cache_valid2[write_cache_index],main_cache_tag2[write_cache_index]);
				end else begin
					main_cache_set1[write_cache_index] = write_data;
					main_cache_tag1[write_cache_index] = write_cache_tag;
					main_cache_valid1[write_cache_index] = 1'b1;
					$display("Fetch: Writing to BTB: BTB Set 1 address of %x is now %x. Valid bit: %b, tag: %x",write_cache_index,main_cache_set1[write_cache_index],main_cache_valid1[write_cache_index],main_cache_tag1[write_cache_index]);
				end
			end
			
		end
	end
end

endmodule
