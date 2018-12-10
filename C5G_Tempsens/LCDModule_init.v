//////////////////////////////////////////////////////////////////////////////////
//出展：https://gist.github.com/jjcarrier/1529101
//////////////////////////////////////////////////////////////////////////////////


module lcdctrl_init(
	CLK, 			// in
	LCD_RW,  		// out			
	LCD_RS,			// out			 		 
	LCD_E,  		// out			
	LCD_DB,  		// out			
	RDY, 			// out
	DATA, 			// in
	OPER, 			// in
	ENB, 			// in
	RST,			// in
	STATE_7seg,
	GPIO_TEST
);
input CLK;			// For this code to work without modification, CLK should equal 24MHz
input DATA;			// The Data to send to the LCD Module
input OPER;			// The Type of operation to perform (data or instruction) 
input ENB;			// Tells the module that the data is valid and start reading DATA and OPER
input RST;

output RDY;			// Indicates that the module is Idle and ready to take more data
output LCD_RS, LCD_RW, LCD_E;
output [7:0] LCD_DB;
output [3:0] STATE_7seg;
output [8:0] GPIO_TEST;

assign STATE_7seg = STATE;
assign GPIO_TEST = {LCD_E,LCD_DB};


wire [7:0] DATA;
wire [1:0] OPER;

wire ENB;
reg RDY;
reg [7:0] LCD_DB=0;
reg LCD_RW=0;			// always write to (and never read from) the LCD
reg LCD_RS=0;			// HI means Data, LOW means Instruction/Command
reg LCD_E=0;

//===============================================================================================
//------------------------------Define the Timing Parameters-------------------------------------
//===============================================================================================
parameter [22:0] t_40ns 	= 22'd2;		//40ns 		== ~2clk
parameter [22:0] t_250ns 	= 22'd12;		//250ns 	== ~12clks
parameter [22:0] t_42us 	= 22'd2100;		//42us 		== ~2016clks
parameter [22:0] t_100us 	= 22'd5000;		//100us		== ~4800clks
parameter [22:0] t_1640us 	= 22'd78720;	//1.64ms 	== ~78720clks
parameter [22:0] t_4100us 	= 22'd205000;	//4.1ms    	== ~393600clks
parameter [22:0] t_15000us	= 22'd750000;	//15ms 		== ~720000clks
parameter [22:0] t_50000us	= 22'd2500000;	//50ms 		== ~2500000clks

//===============================================================================================
//------------------------------Define the BASIC Command Set-------------------------------------
//===============================================================================================
parameter [7:0] SETUP		= 8'b00111100;	//Execution time = 42us, sets to 8-bit interface, 2-line display, 5x11 dots
parameter [7:0] DISP_ON		= 8'b00001100;	//Execution time = 42us, Turn ON Display
parameter [7:0] ALL_ON		= 8'b00001111;	//Execution time = 42us, Turn ON All Display
parameter [7:0] ALL_OFF		= 8'b00001000;	//Execution time = 42us, Turn OFF All Display
parameter [7:0] CLEAR 		= 8'b00000001; 	//Execution time = 1.64ms, Clear Display
parameter [7:0] ENTRY_N		= 8'b00000110;	//Execution time = 42us, Normal Entry, Cursor increments, Display is not shifted
parameter [7:0] HOME 		= 8'b00000010; 	//Execution time = 1.64ms, Return Home
parameter [7:0] C_SHIFT_L 	= 8'b00010000; 	//Execution time = 42us, Cursor Shift
parameter [7:0] C_SHIFT_R 	= 8'b00010100; 	//Execution time = 42us, Cursor Shift
parameter [7:0] D_SHIFT_L 	= 8'b00011000; 	//Execution time = 42us, Display Shift
parameter [7:0] D_SHIFT_R 	= 8'b00011100; 	//Execution time = 42us, Display Shift


//===============================================================================================
//-----------------------------Create the counting mechanisms------------------------------------
//===============================================================================================
reg [22:0] cnt_timer=0; 			//39360 clks, used to delay the STATEmachine during a command execution (SEE above command set)
reg flag_250ns=0,flag_42us=0,flag_100us=0,flag_1640us=0,flag_4100us=0,flag_15000us=0, flag_50000us=0;
reg	flag_rst_delay=0;
reg flag_rst=1;					//Start with flag RST set. so that the counting has not started

always @(posedge CLK) begin
	if(flag_rst) begin
		flag_250ns	<=	1'b0;		//Unlatch the flag
		flag_42us	<=	1'b0;		//Unlatch the flag
		flag_100us	<=	1'b0;		//Unlatch the flag
		flag_1640us	<=	1'b0;		//Unlatch the flag
		flag_4100us	<=	1'b0;		//Unlatch the flag
		flag_15000us    <=	1'b0;		//Unlatch the flag
		flag_50000us	<=	1'b0;		//Unlatch the flag
		cnt_timer	<=	21'b0;		
	end
	else begin
		if(cnt_timer>=t_250ns) begin			
			flag_250ns	<=	1'b1;
		end
		else begin			
			flag_250ns	<=	flag_250ns;
		end
		//----------------------------
		if(cnt_timer>=t_42us) begin			
			flag_42us	<=	1'b1;
		end
		else begin			
			flag_42us	<=	flag_42us;
		end
		//----------------------------
		if(cnt_timer>=t_100us) begin			
			flag_100us	<=	1'b1;
		end
		else begin			
			flag_100us	<=	flag_100us;
		end
		//----------------------------
		if(cnt_timer>=t_1640us) begin			
			flag_1640us	<=	1'b1;
		end
		else begin			
			flag_1640us	<=	flag_1640us;
		end
		//----------------------------
		if(cnt_timer>=t_4100us) begin			
			flag_4100us	<=	1'b1;
		end
		else begin			
			flag_4100us	<=	flag_4100us;
		end
		//----------------------------
		if(cnt_timer>=t_15000us) begin			
			flag_15000us	<=	1'b1;
		end
		else begin			
			flag_15000us	<=	flag_15000us;
		end
		//----------------------------
		if(cnt_timer>=t_50000us) begin			
			flag_50000us	<=	1'b1;
		end
		else begin			
			flag_50000us	<=	flag_50000us;
		end
		//----------------------------		
		cnt_timer	<= cnt_timer + 1;
	end
end

delay delay50000us(t_50000us, flag_rst, CLK, flag_50000us);
delay_enable delay_enable(flag_rst_delay, CLK, flag_delay, LCD_E);


//##########################################################################################
//-----------------------------Create the STATE MACHINE------------------------------------
//##########################################################################################
reg [3:0] STATE=0, DELAY_STATE = 0;
reg [1:0] SUBSTATE=0;


always @(posedge CLK) begin
	case(STATE)
		//---------------------------------------------------------------------------------------
		0: begin //---------------Initiate Command Sequence (RS=LOW)-----------------------------
			LCD_RS	<=	1'b0;										//Indicate an instruction is to be sent soon
			LCD_RW	<= 	1'b0;										//Indicate a write operation
			LCD_E	<=	1'b0;										//We are in the initial setup, keep low until 250ns has past
			LCD_DB 	<= 	8'b00000000;
			RDY		<= 	1'b0;										//Indicate that the module is busy
			if(!flag_50000us) begin									//WAIT 50ms...worst case scenario
				flag_rst			<=	1'b0; 						//Start or Continue counting				
			end
			else begin 				
				STATE				<=	STATE+1;					//Go to next STATE
				flag_rst			<=	1'b1; 						//Stop counting				
			end		
		end
		//---------------------------------------------------------------------------------------
		1:begin //-----------SET FUNCTION #1, 8-bit interface, 2-line display, 5x11 dots---------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 	1'b0;						//Indicate that the module is busy
			LCD_DB 				<=	SETUP;	
			if(!flag_delay) begin									//WAIT 50ms...worst case scenario
				flag_rst			<=	1'b0; 						//Start or Continue counting				
			end
			else begin 				
				STATE				<=	STATE+1;					//Go to next STATE
				flag_rst			<=	1'b1; 						//Stop counting				
			end	
		end
		2,3,4:begin //-----------SET FUNCTION #1, 8-bit interface, 2-line display, 5x11 dots---------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 	1'b0;						//Indicate that the module is busy
			LCD_DB 				<=	SETUP;	
			case(DELAY_STATE)				
				0:begin//write command (turn enable on)					
					LCD_E <= 1'b0;
					DELAY_STATE			<=	DELAY_STATE+1;
				end
				1:begin//write command (turn enable on)					
					if(!flag_42us) begin						    //Hold enable for 250 ns
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 				
						DELAY_STATE			<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
						flag_rst		<=	1'b1; 					//Stop counting					
					end
				end
				2:begin //wait for LCD to process
					LCD_E				<=	1'b1;					//Disable Bus, Triggers LCD to read BUS
					DELAY_STATE			<=	DELAY_STATE+1;	
				end
				3:begin
					if(!flag_1640us) begin						    //WAIT at least 4100us (required for Initialization)
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 		
						DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
						flag_rst		<=	1'b1; 					//Stop counting	
					end		  
				end
				4:begin
					LCD_E			<=	1'b0;					//Enable Bus						
					DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
				end
				5:begin
					if(!flag_1640us) begin						    //Hold enable for 250 ns
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 				
						DELAY_STATE		<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
						flag_rst		<=	1'b1;					//Stop counting					
					end
				end
				default:begin
					STATE			<=	STATE+1;
					DELAY_STATE		<= 1'b0;	
				end
			endcase
		end
		5:begin //-----------SET FUNCTION #1, 8-bit interface, 2-line display, 5x11 dots---------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 	1'b0;						//Indicate that the module is busy
			LCD_DB 				<=	ALL_OFF;	
			case(DELAY_STATE)				
				0:begin//write command (turn enable on)					
					LCD_E <= 1'b0;
					DELAY_STATE			<=	DELAY_STATE+1;
				end
				1:begin//write command (turn enable on)					
					if(!flag_42us) begin						    //Hold enable for 250 ns
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 				
						DELAY_STATE			<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
						flag_rst		<=	1'b1; 					//Stop counting					
					end
				end
				2:begin //wait for LCD to process
					LCD_E				<=	1'b1;					//Disable Bus, Triggers LCD to read BUS
					DELAY_STATE			<=	DELAY_STATE+1;	
				end
				3:begin
					if(!flag_1640us) begin						    //WAIT at least 4100us (required for Initialization)
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 		
						DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
						flag_rst		<=	1'b1; 					//Stop counting	
					end		  
				end
				4:begin
					LCD_E			<=	1'b0;					//Enable Bus						
					DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
				end
				5:begin
					if(!flag_1640us) begin						    //Hold enable for 250 ns
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 				
						DELAY_STATE		<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
						flag_rst		<=	1'b1;					//Stop counting					
					end
				end
				default:begin
					STATE			<=	STATE+1;
					DELAY_STATE		<= 1'b0;	
				end
			endcase
		end
		6:begin //-----------SET FUNCTION #1, 8-bit interface, 2-line display, 5x11 dots---------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 	1'b0;						//Indicate that the module is busy
			LCD_DB 				<=	CLEAR;	
			case(DELAY_STATE)				
				0:begin//write command (turn enable on)					
					LCD_E <= 1'b0;
					DELAY_STATE			<=	DELAY_STATE+1;
				end
				1:begin//write command (turn enable on)					
					if(!flag_42us) begin						    //Hold enable for 250 ns
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 				
						DELAY_STATE			<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
						flag_rst		<=	1'b1; 					//Stop counting					
					end
				end
				2:begin //wait for LCD to process
					LCD_E				<=	1'b1;					//Disable Bus, Triggers LCD to read BUS
					DELAY_STATE			<=	DELAY_STATE+1;	
				end
				3:begin
					if(!flag_1640us) begin						    //WAIT at least 4100us (required for Initialization)
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 		
						DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
						flag_rst		<=	1'b1; 					//Stop counting	
					end		  
				end
				4:begin
					LCD_E			<=	1'b0;					//Enable Bus						
					DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
				end
				5:begin
					if(!flag_4100us) begin						    //Hold enable for 250 ns
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 				
						DELAY_STATE		<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
						flag_rst		<=	1'b1;					//Stop counting					
					end
				end
				default:begin
					STATE			<=	STATE+1;
					DELAY_STATE		<= 1'b0;	
				end
			endcase
		end
		7:begin //-----------SET FUNCTION #1, 8-bit interface, 2-line display, 5x11 dots---------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 	1'b0;						//Indicate that the module is busy
			LCD_DB 				<=	ENTRY_N;	
			case(DELAY_STATE)				
				0:begin//write command (turn enable on)					
					LCD_E <= 1'b0;
					DELAY_STATE			<=	DELAY_STATE+1;
				end
				1:begin//write command (turn enable on)					
					if(!flag_42us) begin						    //Hold enable for 250 ns
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 				
						DELAY_STATE			<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
						flag_rst		<=	1'b1; 					//Stop counting					
					end
				end
				2:begin //wait for LCD to process
					LCD_E				<=	1'b1;					//Disable Bus, Triggers LCD to read BUS
					DELAY_STATE			<=	DELAY_STATE+1;	
				end
				3:begin
					if(!flag_1640us) begin						    //WAIT at least 4100us (required for Initialization)
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 		
						DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
						flag_rst		<=	1'b1; 					//Stop counting	
					end		  
				end
				4:begin
					LCD_E			<=	1'b0;					//Enable Bus						
					DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
				end
				5:begin
					if(!flag_1640us) begin						    //Hold enable for 250 ns
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 				
						DELAY_STATE		<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
						flag_rst		<=	1'b1;					//Stop counting					
					end
				end
				default:begin
					STATE			<=	STATE+1;
					DELAY_STATE		<= 1'b0;	
				end
			endcase
		end
		8:begin //-----------SET FUNCTION #1, 8-bit interface, 2-line display, 5x11 dots---------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 	1'b0;						//Indicate that the module is busy
			LCD_DB 				<=	DISP_ON;	
			case(DELAY_STATE)				
				0:begin//write command (turn enable on)					
					LCD_E <= 1'b0;
					DELAY_STATE			<=	DELAY_STATE+1;
				end
				1:begin//write command (turn enable on)					
					if(!flag_42us) begin						    //Hold enable for 250 ns
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 				
						DELAY_STATE			<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
						flag_rst		<=	1'b1; 					//Stop counting					
					end
				end
				2:begin //wait for LCD to process
					LCD_E				<=	1'b1;					//Disable Bus, Triggers LCD to read BUS
					DELAY_STATE			<=	DELAY_STATE+1;	
				end
				3:begin
					if(!flag_1640us) begin						    //WAIT at least 4100us (required for Initialization)
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 		
						DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
						flag_rst		<=	1'b1; 					//Stop counting	
					end		  
				end
				4:begin
					LCD_E			<=	1'b0;					//Enable Bus						
					DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
				end
				5:begin
					if(!flag_4100us) begin						    //Hold enable for 250 ns
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 				
						DELAY_STATE		<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
						flag_rst		<=	1'b1;					//Stop counting					
					end
				end
				default:begin
					STATE			<=	STATE+1;
					DELAY_STATE		<= 1'b0;	
				end
			endcase
		end	
		9:begin //-----------SET FUNCTION #1, 8-bit interface, 2-line display, 5x11 dots---------
			LCD_RS				<=	1'b1;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 	1'b0;						//Indicate that the module is busy
			LCD_DB 				<=	8'h66;	
			case(DELAY_STATE)				
				0:begin//write command (turn enable on)					
					LCD_E <= 1'b0;
					DELAY_STATE			<=	DELAY_STATE+1;
				end
				1:begin//write command (turn enable on)					
					if(!flag_42us) begin						    //Hold enable for 250 ns
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 				
						DELAY_STATE			<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
						flag_rst		<=	1'b1; 					//Stop counting					
					end
				end
				2:begin //wait for LCD to process
					LCD_E				<=	1'b1;					//Disable Bus, Triggers LCD to read BUS
					DELAY_STATE			<=	DELAY_STATE+1;	
				end
				3:begin
					if(!flag_1640us) begin						    //WAIT at least 4100us (required for Initialization)
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 		
						DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
						flag_rst		<=	1'b1; 					//Stop counting	
					end		  
				end
				4:begin
					LCD_E			<=	1'b0;					//Enable Bus						
					DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
				end
				5:begin
					if(!flag_4100us) begin						    //Hold enable for 250 ns
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 				
						DELAY_STATE		<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
						flag_rst		<=	1'b1;					//Stop counting					
					end
				end
				default:begin
					STATE			<=	STATE+1;
					DELAY_STATE		<= 1'b0;	
				end
			endcase
		end
		10,11:begin //-----------SET FUNCTION #1, 8-bit interface, 2-line display, 5x11 dots---------
			LCD_RS				<=	1'b1;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 	1'b0;						//Indicate that the module is busy
			LCD_DB 				<=	8'h78;	
			case(DELAY_STATE)				
				0:begin//write command (turn enable on)					
					LCD_E <= 1'b0;
					DELAY_STATE			<=	DELAY_STATE+1;
				end
				1:begin//write command (turn enable on)					
					if(!flag_42us) begin						    //Hold enable for 250 ns
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 				
						DELAY_STATE			<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
						flag_rst		<=	1'b1; 					//Stop counting					
					end
				end
				2:begin //wait for LCD to process
					LCD_E				<=	1'b1;					//Disable Bus, Triggers LCD to read BUS
					DELAY_STATE			<=	DELAY_STATE+1;	
				end
				3:begin
					if(!flag_1640us) begin						    //WAIT at least 4100us (required for Initialization)
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 		
						DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
						flag_rst		<=	1'b1; 					//Stop counting	
					end		  
				end
				4:begin
					LCD_E			<=	1'b0;					//Enable Bus						
					DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
				end
				5:begin
					if(!flag_4100us) begin						    //Hold enable for 250 ns
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 				
						DELAY_STATE		<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
						flag_rst		<=	1'b1;					//Stop counting					
					end
				end
				default:begin
					STATE			<=	STATE+1;
					DELAY_STATE		<= 1'b0;	
				end
			endcase
		end
		12:begin //-----------SET FUNCTION #1, 8-bit interface, 2-line display, 5x11 dots---------
			LCD_RS				<=	1'b1;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 	1'b0;						//Indicate that the module is busy
			LCD_DB 				<=	"A";	
			case(DELAY_STATE)				
				0:begin//write command (turn enable on)					
					LCD_E <= 1'b0;
					DELAY_STATE			<=	DELAY_STATE+1;
				end
				1:begin//write command (turn enable on)					
					if(!flag_42us) begin						    //Hold enable for 250 ns
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 				
						DELAY_STATE			<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
						flag_rst		<=	1'b1; 					//Stop counting					
					end
				end
				2:begin //wait for LCD to process
					LCD_E				<=	1'b1;					//Disable Bus, Triggers LCD to read BUS
					DELAY_STATE			<=	DELAY_STATE+1;	
				end
				3:begin
					if(!flag_1640us) begin						    //WAIT at least 4100us (required for Initialization)
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 		
						DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
						flag_rst		<=	1'b1; 					//Stop counting	
					end		  
				end
				4:begin
					LCD_E			<=	1'b0;					//Enable Bus						
					DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
				end
				5:begin
					if(!flag_4100us) begin						    //Hold enable for 250 ns
						flag_rst		<=	1'b0; 					//Start or Continue counting									
					end
					else begin 				
						DELAY_STATE		<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
						flag_rst		<=	1'b1;					//Stop counting					
					end
				end
				default:begin
					STATE			<=	STATE+1;
					DELAY_STATE		<= 1'b0;	
				end
			endcase
		end		

		default: begin//----------This is the IDLE STATE, DO NOTHING UNTIL OPER is set-----------
			if(RST==0)begin
				case(OPER)
					0:STATE<=STATE; 	//IDLE
					1:STATE<=8;		//WRITE CHARACTER
					2:STATE<=9;		//WRITE INSTRUCTION (assumes 49us or less time to process instr)
					3:STATE<=0;			//RESET
				endcase
			end
			else begin
				STATE<=0;
			end
		end
	endcase





end
endmodule

