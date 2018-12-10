
module clock_devide( 
    input flag_rst,
    input [22:0] wait_time,
    input CLK,

    output wire flag_xs
);



//===============================================================================================
//-----------------------------Create the counting mechanisms------------------------------------
//===============================================================================================
reg [22:0] cnt_timer=0; 			//39360 clks, used to delay the STATEmachine during a command execution (SEE above command set)
reg flag_xs=0;

always @(posedge CLK) begin
	if(flag_rst) begin
		flag_xs	<=	1'b0;		    //Unlatch the flag
		cnt_timer	<=	22'b0;	    //Clear the timer	
	end
	else begin
        if(cnt_timer>=wait_time) begin
            flag_xs <= 1'b0;
        end
        else begin
            flag_xs <= 1'b1;
        end
        cnt_timer   <= cnt_timer + 1;
    end
end

endmodule