module enable_delay(
    wait_time,
    flag_rst,
    CLK,
    
    flag_xs,
    LCD_E
);


input   [22:0]  wait_time;
input           flag_rst, CLK;

output flag_xs, LCD_E;

delay delay(wait_time, flag_rst, CLK, flag_xs);



always @(CLK) begin

case(DELAY_STATE)				
    if(flag_rst) begin //unlatch the frag and clear the timer
		flag_xs 	<=	1'b0;	
		cnt_timer	<=	21'b0;	
	end
	else begin //latch the frag
        0:begin				
            LCD_E <= 1'b0;                                  //turn LCD_enable off
            DELAY_STATE			<=	DELAY_STATE+1;		    //Go to next SUBSTATE (wait)
        end
        1:begin					
            if(!flag_42us) begin						    //WAIT at least 42us (required for data)
                flag_rst		<=	1'b0; 					//Start or Continue counting									
            end
            else begin 				
                DELAY_STATE		<=	DELAY_STATE+1;		    //Go to next SUBSTATE (turn enable on)
                flag_rst		<=	1'b1; 					//Stop counting					
            end
        end
        2:begin
            LCD_E				<=	1'b1;					//turn LCD_enable on
            DELAY_STATE			<=	DELAY_STATE+1;          //Go to next SUBSTATE (wait)
        end
        3:begin
            if(!flag_1640us) begin						    //WAIT at least 1640us (required for data_valid)
                flag_rst		<=	1'b0; 					//Start or Continue counting									
            end
            else begin 		
                DELAY_STATE			<=	DELAY_STATE+1;		//Go to next STATE (turn enable on)
                flag_rst		<=	1'b1; 					//Stop counting	
            end		  
        end
        4:begin
            LCD_E			<=	1'b0;					    //Enable Bus						
            DELAY_STATE			<=	DELAY_STATE+1;			//Go to next STATE (next special function set)
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
    end
end
endmodule // 