module btn_in(
    input               clock,
    input               n_reset,
    input               btn_in,
    output reg          btn_out
);

parameter max_cnt = 20'd1000; // for simulation
// paramter max_cnt = 20'd1000000 -> 10ms

reg [19:0] cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        cnt <= 0;
    else
        cnt <= (cnt == max_cnt) ? 20'b0 : cnt + 1;

// 2-clock delayed btn_in
reg btn_in_1d, btn_in_2d;
always@(negedge n_reset, posedge clock)
    if(!n_reset) begin
        btn_in_1d <= 0;
        btn_in_2d <= 0;
    end
    else begin
        btn_in_1d <= btn_in;
        btn_in_2d <= btn_in_1d;
    end

// btn1: present button
// btn2: 10ms earier button
reg btn1, btn2;
always@(negedge n_reset, posedge clock)
    if(!n_reset) begin
        btn1 <= 0;
        btn2 <= 0;
    end
    else begin
        btn1 <= (cnt == max_cnt) ? btn_in_2d : btn1;
        btn2 <= (cnt == max_cnt) ? btn1      : btn2;
    end

// btn_out
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        btn_out <= 0;
    else
        btn_out <= ((cnt == max_cnt) & btn1 & ~btn2) ? 1'b1 : 1'b0;

endmodule
