//=======================================================
//  Clock_generator
//=======================================================



module slowClock(clk, reset, clk_270kHz);
input clk, reset;
output clk_270kHz;

reg clk_270kHz = 1'b0;
reg [27:0] counter = 0;

always@(posedge reset or posedge clk)
begin
    if (reset)
        begin
            clk_270kHz <= 0;
            counter <= 0;
        end
    else
        begin
            counter <= counter + 1;
            if ( counter == 135_000)
                begin
                    counter <= 0;
                    clk_270kHz <= ~clk_270kHz;
                end
        end
end

endmodule   