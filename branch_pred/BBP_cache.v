
//JIMMY: I checked this and it seems fine but when I run it sometimes its not saturating when it should be, but i dont think its here

module BBP_cache(
	input [31:0] PC_write_address,
	input write_data,
	input [31:0] PC_read_address,
	output [1:0] read_data,
	input CLK,
	input RESET,
	input write,
	input dont_read
);
wire [9:0]write_address;
assign write_address = PC_write_address[11:2];
wire [9:0]read_address;
assign read_address = PC_read_address[11:2];
reg [1:0] BBP_block [0:1023];
reg [1:0] temp_data;
assign read_data = dont_read?(2'b00):BBP_block[read_address];
integer reset_index;
always @(posedge CLK or negedge RESET)begin
	if(!RESET) begin
		for(reset_index = 0; reset_index <= 1023; reset_index = reset_index+1) begin
			BBP_block[reset_index]=2'b00;
		end
		$display("Fetch: Resetting BBP.");
		// set whatever reset stuff we need here.
	end else begin
		$display("IF: oc7 result is: %b, dont_read = %b", BBP_block[10'h0c7],dont_read);
		if(write)begin
			temp_data = BBP_block[write_address];
			$display("IF: before update: temp_data: %b, BBP_block[write_address]: %b",temp_data,BBP_block[write_address]);
			case(temp_data)
				2'b00:begin
					//current state is 00
					if(write_data)begin
						BBP_block[write_address] = 2'b01;
					end else begin
						BBP_block[write_address] = 2'b00;
					end
				end
				2'b01:begin
					//current state is 01
					if(write_data)begin
						BBP_block[write_address] = 2'b10;
					end else begin
						BBP_block[write_address] = 2'b00;
					end
				end
				2'b10:begin
					//current state is 10
					if(write_data)begin
						BBP_block[write_address] = 2'b11;
					end else begin
						BBP_block[write_address] = 2'b01;
					end
				end
				2'b11:begin
					//current state is 11
					if(write_data)begin
						BBP_block[write_address] = 2'b11;
					end else begin
						BBP_block[write_address] = 2'b10;
					end
				end
			endcase
		$display("IF: Bimodel Predictor Input write address: %x, Input write Data After Update: %d",write_address,BBP_block[write_address]);
		
		end
		
	end
end

endmodule
	
