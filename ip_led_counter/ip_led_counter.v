module ip_led_counter(
    input           clock,
    input           n_reset,
    input   [3:0]   sw,
    output  [3:0]   led
);

wire locked;
wire clk200, clk100, clk50, clk25;

// Instantiation IP
input_clk t0(
    .clk_out1       (clk200),     
    .clk_out2       (clk100),     
    .clk_out3       (clk50),     
    .clk_out4       (clk25),     
    .resetn         (n_reset), 
    .locked         (locked),      
    .clk_in1        (clock)
);

// counter for led1
reg [25:0] cnt1;
always@(negedge n_reset, posedge clk25)
    if(!n_reset)
        cnt1 <= 0;
    else
        cnt1 <= (cnt1 == 26'd50000000) ? 26'b0 : cnt1 + 1;

// led1 -> increase by 1 every 2s
reg [3:0] led1;
always@(negedge n_reset, posedge clk25)
    if(!n_reset)
        led1 <= 0;
    else
        led1 <= (cnt1 == 26'd50000000) ? led1 + 1 : led1;

// counter for led2
reg [25:0] cnt2;
always@(negedge n_reset, posedge clk50)
    if(!n_reset)
        cnt2 <= 0;
    else
        cnt2 <= (cnt2 == 26'd50000000) ? 26'b0 : cnt2 + 1;

// led2 -> increase by 1 every 1s
reg [3:0] led2;
always@(negedge n_reset, posedge clk50)
    if(!n_reset)
        led2 <= 0;
    else
        led2 <= (cnt2 == 26'd50000000) ? led2 + 1 : led2;

// counter for led3
reg [25:0] cnt3;
always@(negedge n_reset, posedge clk100)
    if(!n_reset)
        cnt3 <= 0;
    else
        cnt3 <= (cnt3 == 26'd50000000) ? 26'b0 : cnt3 + 1;

// led3 -> increase by 1 every 0.5s
reg [3:0] led3;
always@(negedge n_reset, posedge clk100)
    if(!n_reset)
        led3 <= 0;
    else
        led3 <= (cnt3 == 26'd50000000) ? led3 + 1 : led3;

// counter for led4
reg [25:0] cnt4;
always@(negedge n_reset, posedge clk200)
    if(!n_reset)
        cnt4 <= 0;
    else
        cnt4 <= (cnt4 == 26'd50000000) ? 26'b0 : cnt4 + 1;

// led4 -> increase by 1 every 0.25s
reg [3:0] led4;
always@(negedge n_reset, posedge clk200)
    if(!n_reset)
        led4 <= 0;
    else
        led4 <= (cnt4 == 26'd50000000) ? led4 + 1 : led4;

assign led = (sw == 4'b0001) ? led1 : (sw == 4'b0010) ? led2 : (sw == 4'b0100) ? led3 : (sw == 4'b1000) ? led4 : 4'b0;

endmodule
