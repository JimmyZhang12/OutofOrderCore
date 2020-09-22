 module i_cache(
	input [31:0] write_address, // PC to write into cache
	input [31:0] read_address, // PC to read from cache
	input [31:0] write_data, // this is what branch target data to write to
	output read_hit, // if cache hit, set to 1
	output [31:0] read_data_out, // read data output
	input write_request,
	
	input CLK,
	input RESET,

);
//JIMMY: these are ok
	reg [31:0] main_cache_set1 [32767:0]; // main memory space for first set
	reg main_cache_valid1 [32767:0]; // valid bit for first set
	reg [16:0] main_cache_tag1 [32767:0]; // tag bits for first set
	// 32768 entries, we need 15 bits for index. that leaves us with 32-2-15 = 15 bits for tag.
	

	wire [16:0] write_cache_tag ; // this is tag bits from the input write_PC
	wire [16:0] read_cache_tag; // this is tag bits from the input read_PC
	wire [9:0] write_cache_index; // this is index bits from input write_PC
	wire [9:0] read_cache_index; // this is index bits from input read_PC
	wire [4:0] read_offset;
	wire [4:0] write_offset;



	wire set_valid1; // set this to 1 if valid bit for this block is 1 (set1)
	wire [31:0] read_data_out1; // read data out for first set block
	wire tag_match1; // set to 1 if tag matches

	assign write_cache_tag = write_PC[31:15]; // grabbing writing tag from write PC
	assign read_cache_tag = read_PC[31:15]; // grabbing read tag from read PC
	assign write_cache_index = write_PC[14:5]; // grabbing write index from write PC
	assign read_cache_index = read_PC[14:5]; // grabbing read index from read PC

	assign tag_match1 = (main_cache_tag1[read_cache_index] == read_cache_tag)?1'b1:1'b0; // assigning tag match bit for set 1

	assign set_valid1 = 1'b0:(main_cache_valid1[read_cache_index]?1'b1; // checking valid bit for set 1
	assign read_data_out1 = main_cache_set1[read_cache_index]; // the data read out from set 1
	
	assign read_hit = (set_valid1 && tag_match1);
	assign read_data_out = (set_valid1 && tag_match1)? read_data_out1:32'b0; // if set 1 is valid and tag matches, output data is from set 1. if set 2 is valid and tag matches, output is from set 2.
	
//JIMMY: This is ok too
//JIMMY: I'm still not convinced on that reading and writing the ID bit though

integer reset_index;
always @(posedge CLK or negedge RESET)begin
	if(!RESET) begin

		for(reset_index = 0; reset_index <= 511; reset_index = reset_index+1) begin
			main_cache_set1[reset_index]=32'b0;
			main_cache_tag1[reset_index]=21'b0;
			main_cache_valid1[reset_index]=1'b0;
		end
		$display("Fetch: Resetting i-cache.");
		// set whatever reset stuff we need here.
		//
	end else begin
		$display("Fetch: cache read index: %x, cache read tag: %x", read_cache_index,read_cache_tag);
		$display("read_data_out1 = %x, read_data_out2 %x, set_valid1 = %b, set_valid2 = %b, tag_match1 = %b, tag_match2 = %b ",read_data_out1,read_data_out2,main_cache_valid1[read_cache_index], set_valid2, tag_match1, tag_match2);

		if(write_request)begin
			main_cache_set1[write_cache_index] = write_data;
			main_cache_tag1[write_cache_index] = write_cache_tag;
			main_cache_valid1[write_cache_index] = 1'b1;
			$display("Fetch: Writing to cache: cache Set 1 address of %x is now %x. Valid bit: %b, tag: %x",write_cache_index,main_cache_set1[write_cache_index],main_cache_valid1[write_cache_index],main_cache_tag1[write_cache_index]);
		end
	end
end

endmodule
