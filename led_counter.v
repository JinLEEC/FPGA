module led_counter(
    input       n_reset, 
    input       clock,
    output reg [3:0] led
);

reg [30:0] cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        cnt <= 0;
    else
        cnt <= (cnt == 30'd100000000) ? 26'd0 : cnt+1;

// led
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        led <= 0;
    else
        led <= (cnt == 30'd100000000) ? led + 1 : led;

endmodule
