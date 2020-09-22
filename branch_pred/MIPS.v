`include "config.v"
//-----------------------------------------
//            Pipelined MIPS
//-----------------------------------------
module MIPS (

	input RESET,
	input CLK,

	//The physical memory address we want to interact with
	output [31:0] data_address_2DM,
	//We want to perform a read?
	output MemRead_2DM,
	//We want to perform a write?
	output MemWrite_2DM,

	//Data being read
	input [31:0] data_read_fDM,
	//Data being written
	output [31:0] data_write_2DM,
	//How many bytes to write:
	// 1 byte: 1
	// 2 bytes: 2
	// 3 bytes: 3
	// 4 bytes: 0
	output [1:0] data_write_size_2DM,

	//Data being read
	input [255:0] block_read_fDM,
	//Data being written
	output [255:0] block_write_2DM,
	//Request a block read
	output dBlkRead,
	//Request a block write
	output dBlkWrite,
	//Block read is successful (meets timing requirements)
	input block_read_fDM_valid,
	//Block write is successful
	input block_write_fDM_valid,

	//Instruction to fetch
	output [31:0] Instr_address_2IM,
	//Instruction fetched at Instr_address_2IM    
	input [31:0] Instr1_fIM,
	//Instruction fetched at Instr_address_2IM+4 (if you want superscalar)
	input [31:0] Instr2_fIM,

    	//Cache block of instructions fetched
    	input [255:0] block_read_fIM,
    	//Block read is successfull
    	input block_read_fIM_valid,
    	//Request a block read
    	output iBlkRead,
    
	//Tell the simulator that everything's ready to go to process a syscall.
    	//Make sure that all register data is flushed to the register file, and that 
    	//all data cache lines are flushed and invalidated.
    	output SYS
    );
    

//Connecting wires between IF and ID
	wire [31:0] Instr1_IFID;
	wire [31:0] Instr_PC_IFID;
	wire [31:0] Instr_PC_Plus4_IFID;
	wire        STALL_IDIF;
	wire        Request_Alt_PC_IDIF;
	wire [31:0] Alt_PC_IDIF;
    
    
//Connecting wires between IC and IF
	wire [31:0] Instr_address_2IC/*verilator public*/;
	//Instr_address_2IC is verilator public so that sim_main can give accurate 
	//displays.
	//We could use Instr_address_2IM, but this way sim_main doesn't have to 
	//worry about whether or not a cache is present.
	wire [31:0] Instr1_fIC;
	wire [31:0] Instr2_fIC;
	assign Instr_address_2IM = Instr_address_2IC;
	assign Instr1_fIC = Instr1_fIM;
	assign Instr2_fIC = Instr2_fIM;
	assign iBlkRead = 1'b0;
	/*verilator lint_off UNUSED*/
	wire [255:0] unused_i1;
	wire unused_i2;
	/*verilator lint_on UNUSED*/
	assign unused_i1 = block_read_fIM;
	assign unused_i2 = block_read_fIM_valid;
`ifdef SUPERSCALAR
`else
	/*verilator lint_off UNUSED*/
	wire [31:0] unused_i3;
	/*verilator lint_on UNUSED*/
	assign unused_i3 = Instr2_fIC;
`endif


    //added by Hsin
	wire ID_flush_request_dummy1;


	wire [31:0] Instr1_dummy1;
	wire [31:0] Instr_PC_dummy1;
	wire [31:0] Instr_PC_Plus4_dummy1;
	wire [31:0] Instr1_dummy2;
	wire [31:0] Instr_PC_dummy2;
	wire [31:0] Instr_PC_Plus4_dummy2;
	wire [31:0] Instr1_dummy3;
	wire [31:0] Instr_PC_dummy3;
	wire [31:0] Instr_PC_Plus4_dummy3;
	wire [31:0] Instr1_dummy4;
	wire [31:0] Instr_PC_dummy4;
	wire [31:0] Instr_PC_Plus4_dummy4;
	wire [31:0] Instr1_dummy5;
	wire [31:0] Instr_PC_dummy5;
	wire [31:0] Instr_PC_Plus4_dummy5;
	wire [31:0] Instr1_dummy6;
	wire [31:0] Instr_PC_dummy6;
	wire [31:0] Instr_PC_Plus4_dummy6;
	wire [31:0] Instr1_dummy7;
	wire [31:0] Instr_PC_dummy7;
	wire [31:0] Instr_PC_Plus4_dummy7;
	wire [31:0] Alt_PC_MEMIF;
	wire Request_Alt_PC_MEMIF; 
    // defined by Hsin
	wire BBP_write_request_IDIF;
	wire [9:0] BBP_write_address_IDIF;
	wire BBP_write_data_IDIF;
    always@(*)begin
       $display("MIPS:Request_Alt_PC_MEMIF=%X",Request_Alt_PC_IDIF);
       $display("MIPS:Alt_PC_MEMIF=%X",Alt_PC_IDIF);
    end
    IF IF(
        .CLK(CLK),
        .RESET(RESET),
        .Instr1_OUT(Instr1_IFID),
        .Instr_PC_OUT(Instr_PC_IFID),
        .Instr_PC_Plus4(Instr_PC_Plus4_IFID),
        .STALL(STALL_IDIF),
        .Request_Alt_PC(Request_Alt_PC_IDIF),
        .Alt_PC(Alt_PC_IDIF),
        .Instr_address_2IM(Instr_address_2IC),
        .Instr1_fIM(Instr1_fIC),
// added by Hsin. BBP wires into IF stage
	.BBP_write_value(BBP_write_data_IDIF),
	//.BBP_write_address(Instr1_PC_IDEXE),
	.BBP_write_request(BBP_write_request_IDIF),

// added y Hsin. BTB wires into IF stage
	.BTB_write_PC(Instr1_PC_IDEXE),
	.BTB_write_data(Alt_PC_IDIF),
	.BTB_write_request_IDIF(Request_Alt_PC_IDIF), // if we request to write to BBP, that means  we request to write to BTB
// passing output for BBP and BTB to see if there is misprediction later.
	.BBP_read_result(BBP_read_result_IF_D1),
	.BTB_hit(BTB_hit_IF_D1),
	.misprediction(misprediction),
	.mis_return_PC(Instr1_PC_IDEXE_plus8),
	.BBP_BTB_PC_dummy(Instr_PC_IFID) // reason why the BBP and BTB output is sent to D2 is cuz D1 forwarded back its PC to make predictions
// therefore, it goes to D2 since these results are 1 cycle behind
    );
// added by Hsin. BTB and BBP results passing to dummy, later to ID to determine if there is misprediction
	wire [31:0] Instr1_PC_IDEXE_plus8;
	assign Instr1_PC_IDEXE_plus8 = Instr1_PC_IDEXE + 8;
	wire [1:0] BBP_read_result_IF_D1;
	wire [1:0] BBP_read_result_D1_D2;
	wire [1:0] BBP_read_result_D2_D3;
	wire [1:0] BBP_read_result_D3_D4;
	wire [1:0] BBP_read_result_D4_D5;
	wire [1:0] BBP_read_result_D5_D6;
	wire [1:0] BBP_read_result_D6_D7; // first dummy is just called Dummy. this is my oversight for naming covention. Let's just stick with this.
	wire [1:0] BBP_read_result_D7_ID;
	wire BTB_hit_IF_D1;
	wire BTB_hit_D1_D2;
	wire BTB_hit_D2_D3;
	wire BTB_hit_D3_D4;
	wire BTB_hit_D4_D5;
	wire BTB_hit_D5_D6;
	wire BTB_hit_D6_D7;
	wire BTB_hit_D7_ID;
	wire misprediction;


   dummy dummy(
           .CLK(CLK),
           .RESET(RESET),
	   .flush_command(ID_flush_request_dummy1),
           .Instr1_OUT(Instr1_dummy1),
           .Instr_PC_OUT(Instr_PC_dummy1),
           .Instr_PC_Plus4(Instr_PC_Plus4_dummy1),
           .STALL(STALL_IDIF),
           .Instr1_IF(Instr1_IFID),
           .Instr_PC_IF(Instr_PC_IFID),
           .Instr_PC_Plus4_IF(Instr_PC_Plus4_IFID),
	   //added by Hsin
	   .BBP_read_result(BBP_read_result_IF_D1),
	   .BTB_hit(BTB_hit_IF_D1),
	   .BBP_read_result_out(BBP_read_result_D1_D2),
	   .BTB_hit_out(BTB_hit_D1_D2)
          );
     
   dummy1 dummy1( 
           .CLK(CLK),
           .RESET(RESET),
	   .flush_command(ID_flush_request_dummy1),
           .Instr1_OUT(Instr1_dummy2),
           .Instr_PC_OUT(Instr_PC_dummy2),
           .Instr_PC_Plus4(Instr_PC_Plus4_dummy2),
           .STALL(STALL_IDIF),
           .Instr1_IF(Instr1_dummy1),
           .Instr_PC_IF(Instr_PC_dummy1),
           .Instr_PC_Plus4_IF(Instr_PC_Plus4_dummy1),
	   //added by Hsin
	   .BBP_read_result(BBP_read_result_D1_D2),
	   .BTB_hit(BTB_hit_D1_D2),
	   .BBP_read_result_out(BBP_read_result_D2_D3),
	   .BTB_hit_out(BTB_hit_D2_D3)
           );
       
    dummy2 dummy2(
           .CLK(CLK),
           .RESET(RESET),
    	   .flush_command(ID_flush_request_dummy1),
           .Instr1_OUT(Instr1_dummy3),
           .Instr_PC_OUT(Instr_PC_dummy3),
           .Instr_PC_Plus4(Instr_PC_Plus4_dummy3),
           .STALL(STALL_IDIF),
           .Instr1_IF(Instr1_dummy2),
           .Instr_PC_IF(Instr_PC_dummy2),
           .Instr_PC_Plus4_IF(Instr_PC_Plus4_dummy2),
	   //added by Hsin
	   .BBP_read_result(BBP_read_result_D2_D3),
	   .BTB_hit(BTB_hit_D2_D3),
	   .BBP_read_result_out(BBP_read_result_D3_D4),
	   .BTB_hit_out(BTB_hit_D3_D4)
           ); 
    dummy3 dummy3(
           .CLK(CLK),
           .RESET(RESET),
	   .flush_command(ID_flush_request_dummy1),
           .Instr1_OUT(Instr1_dummy4),
           .Instr_PC_OUT(Instr_PC_dummy4),
           .Instr_PC_Plus4(Instr_PC_Plus4_dummy4),
           .STALL(STALL_IDIF),
           .Instr1_IF(Instr1_dummy3),
           .Instr_PC_IF(Instr_PC_dummy3),
           .Instr_PC_Plus4_IF(Instr_PC_Plus4_dummy3),
	   //added by Hsin
	   .BBP_read_result(BBP_read_result_D3_D4),
	   .BTB_hit(BTB_hit_D3_D4),
	   .BBP_read_result_out(BBP_read_result_D4_D5),
	   .BTB_hit_out(BTB_hit_D4_D5)
           );
    dummy4 dummy4(
           .CLK(CLK),
           .RESET(RESET),
	   .flush_command(ID_flush_request_dummy1),
           .Instr1_OUT(Instr1_dummy5),
           .Instr_PC_OUT(Instr_PC_dummy5),
           .Instr_PC_Plus4(Instr_PC_Plus4_dummy5),
           .STALL(STALL_IDIF),
           .Instr1_IF(Instr1_dummy4),
           .Instr_PC_IF(Instr_PC_dummy4),
           .Instr_PC_Plus4_IF(Instr_PC_Plus4_dummy4),
	   //added by Hsin
	   .BBP_read_result(BBP_read_result_D4_D5),
	   .BTB_hit(BTB_hit_D4_D5),
	   .BBP_read_result_out(BBP_read_result_D5_D6),
	   .BTB_hit_out(BTB_hit_D5_D6)
           );
    dummy5 dummy5(
           .CLK(CLK),
           .RESET(RESET),
	   .flush_command(ID_flush_request_dummy1),
           .Instr1_OUT(Instr1_dummy6),
           .Instr_PC_OUT(Instr_PC_dummy6),
           .Instr_PC_Plus4(Instr_PC_Plus4_dummy6),
           .STALL(STALL_IDIF),
           .Instr1_IF(Instr1_dummy5),
           .Instr_PC_IF(Instr_PC_dummy5),
           .Instr_PC_Plus4_IF(Instr_PC_Plus4_dummy5),
	   //added by Hsin
	   .BBP_read_result(BBP_read_result_D5_D6),
	   .BTB_hit(BTB_hit_D5_D6),
	   .BBP_read_result_out(BBP_read_result_D6_D7),
	   .BTB_hit_out(BTB_hit_D6_D7)
           );
    
    dummy6 dummy6(
           .CLK(CLK),
           .RESET(RESET),
	   .flush_command(ID_flush_request_dummy1),
           .Instr1_OUT(Instr1_dummy7),
           .Instr_PC_OUT(Instr_PC_dummy7),
           .Instr_PC_Plus4(Instr_PC_Plus4_dummy7),
           .STALL(STALL_IDIF),
           .Instr1_IF(Instr1_dummy6),
           .Instr_PC_IF(Instr_PC_dummy6),
           .Instr_PC_Plus4_IF(Instr_PC_Plus4_dummy6),
	   //added by Hsin
	   .BBP_read_result(BBP_read_result_D6_D7),
	   .BTB_hit(BTB_hit_D6_D7),
	   .BBP_read_result_out(BBP_read_result_D7_ID),
	   .BTB_hit_out(BTB_hit_D7_ID)
           );

    wire [4:0]  WriteRegister1_MEMWB;
	wire [31:0] WriteData1_MEMWB;
	wire        RegWrite1_MEMWB;
	
	wire [31:0] Instr1_IDEXE;
    wire [31:0] Instr1_PC_IDEXE;
	wire [31:0] OperandA1_IDEXE;
	wire [31:0] OperandB1_IDEXE;
`ifdef HAS_FORWARDING
    wire [4:0]  RegisterA1_IDEXE;
    wire [4:0]  RegisterB1_IDEXE;
`endif
    wire [4:0]  WriteRegister1_IDEXE;
    wire [31:0] MemWriteData1_IDEXE;
    wire        RegWrite1_IDEXE;
    wire [5:0]  ALU_Control1_IDEXE;
    wire        MemRead1_IDEXE;
    wire        MemWrite1_IDEXE;
    wire [4:0]  ShiftAmount1_IDEXE;
    
`ifdef HAS_FORWARDING
    wire [4:0]  BypassReg1_EXEID;
    wire [31:0] BypassData1_EXEID;
    wire        BypassValid1_EXEID;
    
    wire [4:0]  BypassReg1_MEMID;
    wire [31:0] BypassData1_MEMID;
    wire        BypassValid1_MEMID;
`endif
    
	
	ID ID(
		.Flush_out(ID_flush_request_dummy1),
		.CLK(CLK),
		.RESET(RESET),
		.Instr_IN(Instr1_dummy7),
		.Instr1_PC_IN(Instr_PC_dummy7),
		.Instr1_PC_Plus4_IN(Instr_PC_Plus4_dummy7),
		.WriteRegister1_IN(WriteRegister1_MEMWB),
		.WriteData1_IN(WriteData1_MEMWB),
		.RegWrite1_IN(RegWrite1_MEMWB),
		.Alt_PC(Alt_PC_IDIF),
		.Request_Alt_PC(Request_Alt_PC_IDIF),
		.Instr1_OUT(Instr1_IDEXE),
        .Instr1_PC_OUT(Instr1_PC_IDEXE),
		.OperandA1_OUT(OperandA1_IDEXE),
		.OperandB1_OUT(OperandB1_IDEXE),
`ifdef HAS_FORWARDING
		.ReadRegisterA1_OUT(RegisterA1_IDEXE),
		.ReadRegisterB1_OUT(RegisterB1_IDEXE),
`else
/* verilator lint_off PINCONNECTEMPTY */
        .ReadRegisterA1_OUT(),
        .ReadRegisterB1_OUT(),
/* verilator lint_on PINCONNECTEMPTY */
`endif
		.WriteRegister1_OUT(WriteRegister1_IDEXE),
		.MemWriteData1_OUT(MemWriteData1_IDEXE),
		.RegWrite1_OUT(RegWrite1_IDEXE),
		.ALU_Control1_OUT(ALU_Control1_IDEXE),
		.MemRead1_OUT(MemRead1_IDEXE),
		.MemWrite1_OUT(MemWrite1_IDEXE),
		.ShiftAmount1_OUT(ShiftAmount1_IDEXE),
`ifdef HAS_FORWARDING
		.BypassReg1_EXEID(BypassReg1_EXEID),
		.BypassData1_EXEID(BypassData1_EXEID),
		.BypassValid1_EXEID(BypassValid1_EXEID),
		.BypassReg1_MEMID(BypassReg1_MEMID),
		.BypassData1_MEMID(BypassData1_MEMID),
		.BypassValid1_MEMID(BypassValid1_MEMID),
`endif
		.SYS(SYS),
		.WANT_FREEZE(STALL_IDIF),
		//added by Hsin
		.BBP_write_request_IDIF(BBP_write_request_IDIF),
		.BBP_write_data_IDIF(BBP_write_data_IDIF),

		//added by Hsin to determine if there is misprediction
		.BBP_read_result(BBP_read_result_D7_ID),
		.BTB_hit(BTB_hit_D7_ID),
		.Misprediction_out(misprediction),
		.predicted_PC(Instr_PC_dummy5)
	);
	
	wire [31:0] Instr1_EXEMEM;
	wire [31:0] Instr1_PC_EXEMEM;
	wire [31:0] ALU_result1_EXEMEM;
    wire [4:0]  WriteRegister1_EXEMEM;
    wire [31:0] MemWriteData1_EXEMEM;
    wire        RegWrite1_EXEMEM;
    wire [5:0]  ALU_Control1_EXEMEM;
    wire        MemRead1_EXEMEM;
    wire        MemWrite1_EXEMEM;
    wire [31:0] Alt_PC_IDEXE;
    wire Request_Alt_PC_IDEXE;
    wire [31:0] Alt_PC_EXEMEM;
    wire Request_Alt_PC_EXEMEM;
`ifdef HAS_FORWARDING
    wire [31:0] ALU_result_async1;
    wire        ALU_result_async_valid1;
`endif
	
	EXE EXE(
		.CLK(CLK),
		.RESET(RESET),
		.Instr1_IN(Instr1_IDEXE),
		.Instr1_PC_IN(Instr1_PC_IDEXE),
                .Request_Alt_PC(Request_Alt_PC_IDEXE),
                .Alt_PC(Alt_PC_IDEXE),
`ifdef HAS_FORWARDING
		.RegisterA1_IN(RegisterA1_IDEXE),
`endif
		.OperandA1_IN(OperandA1_IDEXE),
`ifdef HAS_FORWARDING
		.RegisterB1_IN(RegisterB1_IDEXE),
`endif
		.OperandB1_IN(OperandB1_IDEXE),
		.WriteRegister1_IN(WriteRegister1_IDEXE),
		.MemWriteData1_IN(MemWriteData1_IDEXE),
		.RegWrite1_IN(RegWrite1_IDEXE),
		.ALU_Control1_IN(ALU_Control1_IDEXE),
		.MemRead1_IN(MemRead1_IDEXE),
		.MemWrite1_IN(MemWrite1_IDEXE),
		.ShiftAmount1_IN(ShiftAmount1_IDEXE),
		.Instr1_OUT(Instr1_EXEMEM),
		.Instr1_PC_OUT(Instr1_PC_EXEMEM),
		.ALU_result1_OUT(ALU_result1_EXEMEM),
		.WriteRegister1_OUT(WriteRegister1_EXEMEM),
		.MemWriteData1_OUT(MemWriteData1_EXEMEM),
		.RegWrite1_OUT(RegWrite1_EXEMEM),
		.ALU_Control1_OUT(ALU_Control1_EXEMEM),
		.MemRead1_OUT(MemRead1_EXEMEM),
		.MemWrite1_OUT(MemWrite1_EXEMEM),
                .Alt_PC1(Alt_PC_EXEMEM),
                .Request_Alt_PC1(Request_Alt_PC_EXEMEM)
`ifdef HAS_FORWARDING
		,
		.BypassReg1_MEMEXE(WriteRegister1_MEMWB),
		.BypassData1_MEMEXE(WriteData1_MEMWB),
		.BypassValid1_MEMEXE(RegWrite1_MEMWB),
		.ALU_result_async1(ALU_result_async1),
		.ALU_result_async_valid1(ALU_result_async_valid1)
`endif
	);
	
`ifdef HAS_FORWARDING
    assign BypassReg1_EXEID = WriteRegister1_IDEXE;
    assign BypassData1_EXEID = ALU_result_async1;
    assign BypassValid1_EXEID = ALU_result_async_valid1;
`endif
     
    wire [31:0] data_write_2DC/*verilator public*/;
    wire [31:0] data_address_2DC/*verilator public*/;
    wire [1:0]  data_write_size_2DC/*verilator public*/;
    wire [31:0] data_read_fDC/*verilator public*/;
    wire        read_2DC/*verilator public*/;
    wire        write_2DC/*verilator public*/;
    //No caches, so:
    /* verilator lint_off UNUSED */
    wire        flush_2DC/*verilator public*/;
    /* verilator lint_on UNUSED */
    wire        data_valid_fDC /*verilator public*/;
    assign data_write_2DM = data_write_2DC;
    assign data_address_2DM = data_address_2DC;
    assign data_write_size_2DM = data_write_size_2DC;
    assign data_read_fDC = data_read_fDM;
    assign MemRead_2DM = read_2DC;
    assign MemWrite_2DM = write_2DC;
    assign data_valid_fDC = 1'b1;
     
    assign dBlkRead = 1'b0;
    assign dBlkWrite = 1'b0;
    assign block_write_2DM = block_read_fDM;
    /*verilator lint_off UNUSED*/
    wire unused_d1;
    wire unused_d2;
    /*verilator lint_on UNUSED*/
    assign unused_d1 = block_read_fDM_valid;
    assign unused_d2 = block_write_fDM_valid;
     
    MEM MEM(
        .CLK(CLK),
        .RESET(RESET),
        .Instr1_IN(Instr1_EXEMEM),
        .Instr1_PC_IN(Instr1_PC_EXEMEM),
        .Request_Alt_PC(Request_Alt_PC_EXEMEM),
        .Alt_PC(Alt_PC_EXEMEM),
        .ALU_result1_IN(ALU_result1_EXEMEM),
        .WriteRegister1_IN(WriteRegister1_EXEMEM),
        .MemWriteData1_IN(MemWriteData1_EXEMEM),
        .RegWrite1_IN(RegWrite1_EXEMEM),
        .ALU_Control1_IN(ALU_Control1_EXEMEM),
        .MemRead1_IN(MemRead1_EXEMEM),
        .MemWrite1_IN(MemWrite1_EXEMEM),
        .WriteRegister1_OUT(WriteRegister1_MEMWB),
        .RegWrite1_OUT(RegWrite1_MEMWB),
        .WriteData1_OUT(WriteData1_MEMWB),
        .data_write_2DM(data_write_2DC),
        .data_address_2DM(data_address_2DC),
        .data_write_size_2DM(data_write_size_2DC),
        .data_read_fDM(data_read_fDC),
        .MemRead_2DM(read_2DC),
        .Request_Alt_PC1(Request_Alt_PC_MEMIF),
        .Alt_PC1(Alt_PC_MEMIF),
        .MemWrite_2DM(write_2DC)
`ifdef HAS_FORWARDING
        ,
        .WriteData1_async(BypassData1_MEMID)
`endif
    );
     
`ifdef HAS_FORWARDING
    assign BypassReg1_MEMID = WriteRegister1_EXEMEM;
    assign BypassValid1_MEMID = RegWrite1_EXEMEM;
`endif
    
endmodule
