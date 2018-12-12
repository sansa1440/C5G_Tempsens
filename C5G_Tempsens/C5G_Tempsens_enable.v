module enable_delay(
    wait_time_enable,
    flag_rst_enable,
    CLK,
    
    flag_xs_enable,
    LCD_E
);


input   [22:0]  wait_time_enable;
input           flag_rst_enable, CLK;

output flag_xs_enable, LCD_E;

reg [2:0] DELAY_STATE = 0; // STATE register 3bit
reg flag_xs_enable = 0;


delay delay(wait_time, flag_rst, CLK, flag_xs);

always @(CLK) begin
    if(flag_rst_enable) begin //unlatch the frag and clear the timer
		flag_xs_enable	<=	1'b0;
        DELAY_STATE <=  1'b0;	
		cnt_timer	<=	21'b0;	
	end
	else begin //latch the frag
        case(DELAY_STATE)				
            0:begin				
                LCD_E <= 1'b0;                                  //turn LCD_enable off
                wait_time           <=  22'd2016;               //decide wait_time at 42us 	
                DELAY_STATE			<=	DELAY_STATE+1;		    //Go to next SUBSTATE (wait)	
            end
            1:begin
                if(!flag_xs) begin						        //WAIT at least 42us (required for data)
                    flag_rst		<=	1'b0; 					//Start or Continue counting									
                end
                else begin 				
                    DELAY_STATE		<=	DELAY_STATE+1;		    //Go to next SUBSTATE (turn enable on)
                    flag_rst		<=	1'b1; 					//Stop counting					
                end
            end
            2:begin
                LCD_E				<=	1'b1;					//turn LCD_enable on
                wait_time           <=  22'd78720;              //decide wait_time at 1620us 
                DELAY_STATE			<=	DELAY_STATE+1;          //Go to next SUBSTATE (wait)  
            end
            3:begin
                if(!flag_xs) begin						        //WAIT at least 1640us (required for data_valid)
                    flag_rst		<=	1'b0; 					//Start or Continue counting									
                end
                else begin 		
                    DELAY_STATE			<=	DELAY_STATE+1;		//Go to next STATE (turn enable on)
                    flag_rst		<=	1'b1; 					//Stop counting	
                end		  
            end
            4:begin
                LCD_E               <=	1'b0;					//Enable Bus	
                wait_time           <=  wait_time_enable;       //decide wait_time at input "wait_time_inable"					
                DELAY_STATE			<=	DELAY_STATE+1;			//Go to next STATE (turn enable off)
            end
            5:begin
                if(!flag_xs) begin						        //WAIT at least "wait_time" (required for execution time)
                    flag_rst		<=	1'b0; 					//Start or Continue counting									
                end
                else begin 				
                    DELAY_STATE		<=	DELAY_STATE+1;			//Go to next SUBSTATE (end state)
                    flag_rst		<=	1'b1;					//Stop counting					
                end
            end
            default:begin
                DELAY_STATE		<= DELAY_STATE;	
            end
        endcase
    end
endmodule // 