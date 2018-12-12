module delay(
    wait_time,
    flag_rst,
    CLK,
    
    flag_xs
);

input   [22:0]  wait_time;
input           flag_rst, CLK;

output  flag_xs;

//===============================================================================================
//-----------------------------Create the counting mechanisms------------------------------------
//===============================================================================================
reg [22:0] cnt_timer = 22b'0;
reg flag_xs = 1b'0;
reg flag_rst; 

always @(posedge CLK) begin
	if(flag_rst) begin //unlatch the frag and clear the timer
		flag_xs 	<=	1'b0;	
		cnt_timer	<=	21'b0;	
	end
	else begin //latch the frag
		if(cnt_timer>=wait_time) begin			
			flag_xs 	<=	1'b1;
		end
		else begin			
			flag_xs 	<=	flag_xs;
		end
		cnt_timer	<= cnt_timer + 1;//The positive-edge-triggered clock increment cnt_timer by 1
	end
end

endmodule