module delay(wait_time, flag_rst, CLK, flag_xs);

input [22:0] wait_time;
input flag_rst;
input CLK;

output flag_xs;

//===============================================================================================
//-----------------------------Create the counting mechanisms------------------------------------
//===============================================================================================
reg [22:0] cnt_timer=0; 		
reg flag_250ns=0,flag_42us=0,flag_100us=0,flag_1640us=0,flag_4100us=0,flag_15000us=0, flag_50000us=0;
reg	flag_rst_delay=0;
reg flag_rst=1;					//Start with flag RST set. so that the counting has not started

always @(posedge CLK) begin
	if(flag_rst) begin  //Unlatch the flag
		flag_250ns	<=	1'b0;		
		flag_42us	<=	1'b0;		
		flag_100us	<=	1'b0;		
		flag_1640us	<=	1'b0;		
		flag_4100us	<=	1'b0;	
		flag_15000us    <=	1'b0;
		flag_50000us	<=	1'b0;
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


endmodule