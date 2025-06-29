module btn_in(
    input         n_reset, 
    input         clock,
    input         btn_in,
    output reg    btn_out
);

parameter max_cnt = 20'd1000000; // 10ms
// parameter max_cnt == 20'd1000; for simulation

// Timer, sampling every 10ms
reg [19:0] cnt; 
always@(negedge n_reset, posedge clock) 
    if(!n_reset)
        cnt <= 0;
    else
        cnt <= (cnt == max_cnt) ? 20'b0 : cnt + 1;

// use 2-clock delayed signal
reg btn_1d, btn_2d;
always@(negedge n_reset, posedge clock)
    if(!n_reset) begin
        btn_1d <= 0;
        btn_2d <= 0;
    end
    else begin
        btn_1d <= btn_in;
        btn_2d <= btn_1d;
    end

// btn1: current button state
// btn2: previous button state
reg btn1, btn2;
always@(negedge n_reset, posedge clock)
    if(!n_reset) begin
        btn1 <= 0;
        btn2 <= 0;
    end
    else begin
        btn1 <= (cnt == max_cnt) ? btn_2d : btn1;
        btn2 <= (cnt == max_cnt) ? btn1   : btn2;
    end

always@(negedge n_reset, posedge clock)
    if(!n_reset)
        btn_out <= 0;
    else
        btn_out <= ((cnt == max_cnt) & btn1 & ~btn2) ? 1'b1 : 1'b0; // btn1 = 1 & btn2 = 0 -> btn_out = 1 (rising edge)

endmodule