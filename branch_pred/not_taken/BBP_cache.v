module BBP_cache(
	input [9:0] write_address,
	input write_data,
	input [9:0] read_address,
	output [1:0] read_data,
	input CLK,
	input RESET,
	input write
);

reg [1:0] BBP_block [0:1023];
reg [1:0] temp_data;
assign read_data = BBP_block[read_address];

always @(posedge CLK or negedge RESET)begin
	if(!RESET) begin
		// set whatever reset stuff we need here.
	end else begin
		if(write)begin
			temp_data = BBP_block[write_address];
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
					//current state is 01
					if(write_data)begin
						BBP_block[write_address] = 2'b11;
					end else begin
						BBP_block[write_address] = 2'b01;
					end
				end
				2'b11:begin
					//current state is 01
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
	
