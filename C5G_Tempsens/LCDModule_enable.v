module delay_enable(flag_rst, CLK, flag_delay, LCD_E);

input flag_rst, CLK;

output flag_delay, LCD_E;

reg flag_delay=1'b0;
reg flag_42us=1'b0, flag_1640us=1'b0, flag_4100us=1'b0;
reg LCD_E = 1'b0;



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
//------------------------------Create the delay times-------------------------------------
//===============================================================================================
delay delay42us(t_42us, flag_rst_42us, CLK, flag_42us);
delay delay1640us(t_1640us, flag_rst_1640us, CLK, flag_1640us);
delay delay4100us(t_4100us, flag_rst_4100us, CLK, flag_4100us);

//===============================================================================================
//------------------------------Create the enable signal-------------------------------------
//===============================================================================================
reg [2:0] DELAY_STATE = 0;

always @(posedge CLK) begin
    case(DELAY_STATE)				
        0:begin//write command (turn enable on)					
            LCD_E <= 1'b0;
            DELAY_STATE			<=	DELAY_STATE+1;
        end
        1:begin//write command (turn enable on)					
            if(!flag_42us) begin						    //Hold enable for 250 ns
                flag_rst_42us		<=	1'b0; 					//Start or Continue counting									
            end
            else begin 				
                DELAY_STATE			<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
                flag_rst_42us		<=	1'b1; 					//Stop counting					
            end
        end
        2:begin //wait for LCD to process
            LCD_E				<=	1'b1;					//Disable Bus, Triggers LCD to read BUS
            DELAY_STATE			<=	DELAY_STATE+1;	
        end
        3:begin
            if(!flag_1640us) begin						    //WAIT at least 4100us (required for Initialization)
                flag_rst_1640us		<=	1'b0; 					//Start or Continue counting									
            end
            else begin 		
                DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
                flag_rst_1640us		<=	1'b1; 					//Stop counting	
            end		  
        end
        4:begin
            LCD_E			<=	1'b0;					//Enable Bus						
            DELAY_STATE			<=	DELAY_STATE+1;				//Go to next STATE (next special function set)
        end
        5:begin
            if(!flag_4100us) begin						    //Hold enable for 250 ns
                flag_rst_4100us		<=	1'b0; 					//Start or Continue counting									
            end
            else begin 				
                DELAY_STATE		<=	DELAY_STATE+1;				//Go to next SUBSTATE (disable bus, wait)
                flag_rst_4100us		<=	1'b1;					//Stop counting					
                flag_delay <= 1'b1;
            end
        end
        default:begin
            if (flag_rst) begin
                DELAY_STATE <= 1'b0;
                flag_delay <=1'b0;
            end else begin
                DELAY_STATE		<= DELAY_STATE;
            end
        end
    endcase
end 

endmodule
