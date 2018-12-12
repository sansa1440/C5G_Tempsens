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
	STATE_7seg
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

assign STATE_7seg = STATE;



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
parameter [22:0] t_42us 	= 22'd2016;		//42us 		== ~2016clks
parameter [22:0] t_100us 	= 22'd4800;		//100us		== ~4800clks
parameter [22:0] t_1640us 	= 22'd78720;	//1.64ms 	== ~78720clks
parameter [22:0] t_4100us 	= 22'd393600;	//4.1ms    	== ~393600clks
parameter [22:0] t_15000us	= 22'd720000;	//15ms 		== ~720000clks
parameter [22:0] t_50000us	= 22'd2500000;	//50ms 		== ~2500000clks

//===============================================================================================
//------------------------------Define the BASIC Command Set-------------------------------------
//===============================================================================================
parameter [7:0] SETUP		= 8'b00111100;	//Execution time = 42us, sets to 8-bit interface, 2-line display, 5x11 dots
parameter [7:0] DISP_ON		= 8'b00001110;	//Execution time = 42us, Turn ON Display
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
// input [22:0] wait_time, input flag_rst, input CLK, output flag_xs
//===============================================================================================

enable_delay enable_delay(wait_time, flag_rst, CLK, flag_xs, LCD_E);
reg flag_xs = 1'b1;	//Start with flag RST set. so that the counting has not started
reg [22:0] wait_time = 23'b0;

//##########################################################################################
//-----------------------------Create the STATE MACHINE------------------------------------
//##########################################################################################
reg [3:0] STATE=0;
reg [1:0] SUBSTATE=0;

always @(posedge CLK) begin
	case(STATE)
		//---------------------------------------------------------------------------------------
		0: begin //---------------Initiate Command Sequence (RS=LOW)-----------------------------
			LCD_RS	<=	1'b0;										//Indicate an instruction is to be sent soon
			LCD_RW	<= 	1'b0;										//Indicate a write operation
			LCD_DB 	<= 	8'b00000000;
			RDY		<= 	1'b0;										//Indicate that the module is busy
			wait_time	<= t_50000us;
			if(!flag_xs) begin										//WAIT 50ms...worst case scenario
				STATE				<=	STATE;						//Remain in current STATE
				flag_rst			<=	1'b0; 						//Start or Continue counting				
			end
			else begin 				
				STATE				<=	STATE+1;					//Go to next STATE
				flag_rst			<=	1'b1; 						//Stop counting				
			end		
		end
		//----------------initialization-------------------------------------------------------------------
		1: begin //-----------SET FUNCTION #1, 8-bit interface, 2-line display, 5x11 dots---------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 	1'b0;
			LCD_DB				<=	SETUP;
			wait_time			<= 	t_4100us;
			if(!flag_xs) begin										//WAIT 4100us...worst case scenario
				STATE				<=	STATE;						//Remain in current STATE
				flag_rst			<=	1'b0; 						//Start or Continue counting				
			end
			else begin 				
				STATE				<=	STATE+1;					//Go to next STATE
				flag_rst			<=	1'b1; 						//Stop counting				
			end
		end	
		2,3,4: begin //-----------2 special case function sets (for initialization)---------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 	1'b0;
			LCD_DB				<=	SETUP;
			wait_time			<= 	t_100us;
			if(!flag_xs) begin										//WAIT 100us...worst case scenario
				STATE				<=	STATE;						//Remain in current STATE
				flag_rst			<=	1'b0; 						//Start or Continue counting				
			end
			else begin 				
				STATE				<=	STATE+1;					//Go to next STATE
				flag_rst			<=	1'b1; 						//Stop counting				
			end	
		end
		//---------------------------------------------------------------------------------------
		5: begin //-----------Turn off display, cursor,and blinking of cursor---------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 	1'b0;
			LCD_DB				<=	ALL_OFF;
			wait_time			<= 	t_100us;
			if(!flag_xs) begin										//WAIT 4100us...worst case scenario
				STATE				<=	STATE;						//Remain in current STATE
				flag_rst			<=	1'b0; 						//Start or Continue counting				
			end
			else begin 				
				STATE				<=	STATE+1;					//Go to next STATE
				flag_rst			<=	1'b1; 						//Stop counting				
			end	
		end
		//---------------------------------------------------------------------------------------
		6: begin //-----------clear the display---------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 	1'b0;
			LCD_DB				<=	CLEAR;
			wait_time			<= 	t_4100us;
			if(!flag_xs) begin										//WAIT 4100us...worst case scenario
				STATE				<=	STATE;						//Remain in current STATE
				flag_rst			<=	1'b0; 						//Start or Continue counting				
			end
			else begin 				
				STATE				<=	STATE+1;					//Go to next STATE
				flag_rst			<=	1'b1; 						//Stop counting				
			end	
		end
		7: begin //-----------Entry Mode Set(cursor moving increment, entire display shift disable)---------
			LCD_RS				<=	1'b1;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 	1'b0;
			LCD_DB				<=	ENTRY_N;
			wait_time			<= 	t_42us;
			if(!flag_xs) begin										//WAIT 4100us...worst case scenario
				STATE				<=	STATE;						//Remain in current STATE
				flag_rst			<=	1'b0; 						//Start or Continue counting				
			end
			else begin 				
				STATE				<=	STATE+1;					//Go to next STATE
				flag_rst			<=	1'b1; 						//Stop counting				
			end	
		end
		8: begin //-----------Turn on display, cursor,and blinking of cursor---------
			LCD_RS				<=	1'b0;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 	1'b0;
			LCD_DB				<=	DISP_ON;
			wait_time			<= 	t_100us;
			if(!flag_xs) begin										//WAIT 4100us...worst case scenario
				STATE				<=	STATE;						//Remain in current STATE
				flag_rst			<=	1'b0; 						//Start or Continue counting				
			end
			else begin 				
				STATE				<=	STATE+1;					//Go to next STATE
				flag_rst			<=	1'b1; 						//Stop counting				
			end	
		end
		//----------------end of initialization-----------------------------------------------------------------------
		9: begin //-----------Write data---------
			LCD_RS				<=	1'b1;						//Indicate an instruction is to be sent soon
			LCD_RW				<=	1'b0;						//Indicate a write operation
			RDY					<= 	1'b0;
			LCD_DB				<=	"a";
			wait_time			<= 	t_100us;
			if(!flag_xs) begin										//WAIT 4100us...worst case scenario
				STATE				<=	STATE;						//Remain in current STATE
				flag_rst			<=	1'b0; 						//Start or Continue counting				
			end
			else begin 				
				STATE				<=	STATE+1;					//Go to next STATE
				flag_rst			<=	1'b1; 						//Stop counting				
			end	
		end
		//---------------------------------------------------------------------------------------

		

		default: begin//----------This is the IDLE STATE, DO NOTHING UNTIL OPER is set-----------
			if(ENB==1 && RST==0)begin
				case(OPER)
					0:STATE<=STATE; 	//IDLE
					1:STATE<=8;		//WRITE CHARACTER
					2:STATE<=9;		//WRITE INSTRUCTION (assumes 49us or less time to process instr)
					3:STATE<=0;			//RESET
				endcase
			end
			else if(RST==1)begin
				STATE<=6;
			end
		end
	endcase
end
endmodule

