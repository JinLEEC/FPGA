module spi_master(
    input              n_reset,
    input              clock,
    input      [9:0]   freq,
    input      [7:0]   addr,
    input      [7:0]   wdata,
    output reg [7:0]   rdata,    
    input              start_wr, // trigger write
    input              start_re, // trigger read
    output  reg        ss,
    output  reg        sclk,
    output  reg        mosi,
    output  reg        done,
    input              miso
); 

// Parameters
parameter SLAVE_IDW = 8'hff;
parameter SLAVE_IDR = 8'h00;

// Define states
reg [1:0] present_state, next_state;
parameter IDLE  = 2'd0;
parameter READY = 2'd1;
parameter SEND  = 2'd2;
parameter DONE  = 2'd3;

// State flag
wire idle_flag  = (present_state == IDLE)  ? 1'b1 : 1'b0;
wire ready_flag = (present_state == READY) ? 1'b1 : 1'b0;
wire send_flag  = (present_state == SEND)  ? 1'b1 : 1'b0;
wire done_flag  = (present_state == DONE)  ? 1'b1 : 1'b0;

// State update
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        present_state <= IDLE;
    else
        present_state <= next_state;

// State transition
always@(*) begin
    next_state = present_state;
    case(present_state)
        IDLE  : next_state = (idle_flag & (start_wr_posedge | start_re_posedge))        ? READY : IDLE;
        READY : next_state = (ready_flag & (ready_cnt == freq))                         ? SEND : READY;
        SEND  : next_state = (send_flag & (sclk_index == 6'd48) & (sclk_cnt == 10'd10)) ? DONE : SEND;
        DONE  : next_state = (done_flag & (done_cnt == 4'd15))                          ? IDLE : DONE;
    endcase
end

// start_wr positive edge
reg start_wr_1d, start_wr_2d;
wire start_wr_posedge = start_wr_1d & ~start_wr_2d;
always@(negedge n_reset, posedge clock)
    if(!n_reset) begin
        start_wr_1d <= 0;
        start_wr_2d <= 0;
    end
    else begin
        start_wr_1d <= start_wr;
        start_wr_2d <= start_wr_1d;
    end

// start_re positive edge
reg start_re_1d, start_re_2d;
wire start_re_posedge = start_re_1d & ~start_re_2d;
always@(negedge n_reset, posedge clock)
    if(!n_reset) begin
        start_re_1d <= 0;
        start_re_2d <= 0;
    end
    else begin
        start_re_1d <= start_re;
        start_re_2d <= start_re_1d;
    end

reg rw_flag; // write: 1, read: 0
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        rw_flag <= 0;
    else
        rw_flag <= (start_re_posedge) ? 1'b0 : 
                   (start_wr_posedge) ? 1'b1 : rw_flag;

// READY state counter
reg [9:0] ready_cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        ready_cnt <= 0;
    else
        ready_cnt <= (ready_flag) ? ready_cnt + 1 : 10'b0;

// DONE state counter
reg [3:0] done_cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        done_cnt <= 0;
    else
        done_cnt <= (done_flag) ? done_cnt + 1 : 4'b0;

// counter for sclk
reg [9:0] sclk_cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        sclk_cnt <= 0;
    else
        sclk_cnt <= (~send_flag)     ? 1'b0 :
                   (sclk_cnt == freq) ? 10'b0 : sclk_cnt + 1;

reg [5:0] sclk_index;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        sclk_index <= 0;
    else
        sclk_index <= (~send_flag) ? 6'b0 :
                     (sclk_cnt == freq) ? sclk_index + 1 : sclk_index;

// ss: slave select (Active Low)
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        ss <= 1;
    else
        ss <= (idle_flag) ? 1'b1 :
              (ready_flag & (ready_cnt == 10'd0)) ? 1'b0 :
              (done_flag & (done_cnt == 4'd15))   ? 1'b1 : ss;

// sclk
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        sclk <= 0;
    else
        sclk <= (~send_flag) ? 1'b0 :
               ((sclk_index < 6'd48) && (sclk_cnt == 10'd0)) ? ~sclk : sclk;

// mosi
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        mosi <= 0;
    else
        mosi <= (idle_flag) ? 1'b0 :
                (ready_flag & (ready_cnt == 10'd10)) ? ((rw_flag) ? SLAVE_IDW[7] : SLAVE_IDR[7]) :
                (send_flag & (sclk_index == 6'd1) & (sclk_cnt == 10'd0))  ? ((rw_flag) ? SLAVE_IDW[6] : SLAVE_IDR[6]) :
                (send_flag & (sclk_index == 6'd3) & (sclk_cnt == 10'd0))  ? ((rw_flag) ? SLAVE_IDW[5] : SLAVE_IDR[5]) :
                (send_flag & (sclk_index == 6'd5) & (sclk_cnt == 10'd0))  ? ((rw_flag) ? SLAVE_IDW[4] : SLAVE_IDR[4]) :
                (send_flag & (sclk_index == 6'd7) & (sclk_cnt == 10'd0))  ? ((rw_flag) ? SLAVE_IDW[3] : SLAVE_IDR[3]) :
                (send_flag & (sclk_index == 6'd9) & (sclk_cnt == 10'd0))  ? ((rw_flag) ? SLAVE_IDW[2] : SLAVE_IDR[2]) :
                (send_flag & (sclk_index == 6'd11) & (sclk_cnt == 10'd0)) ? ((rw_flag) ? SLAVE_IDW[1] : SLAVE_IDR[1]) :
                (send_flag & (sclk_index == 6'd13) & (sclk_cnt == 10'd0)) ? ((rw_flag) ? SLAVE_IDW[0] : SLAVE_IDR[0]) :
                (send_flag & (sclk_index == 6'd15) & (sclk_cnt == 10'd0)) ? addr[7] :
                (send_flag & (sclk_index == 6'd17) & (sclk_cnt == 10'd0)) ? addr[6] :
                (send_flag & (sclk_index == 6'd19) & (sclk_cnt == 10'd0)) ? addr[5] :
                (send_flag & (sclk_index == 6'd21) & (sclk_cnt == 10'd0)) ? addr[4] :
                (send_flag & (sclk_index == 6'd23) & (sclk_cnt == 10'd0)) ? addr[3] :
                (send_flag & (sclk_index == 6'd25) & (sclk_cnt == 10'd0)) ? addr[2] :
                (send_flag & (sclk_index == 6'd27) & (sclk_cnt == 10'd0)) ? addr[1] :
                (send_flag & (sclk_index == 6'd29) & (sclk_cnt == 10'd0)) ? addr[0] :
                (send_flag & (sclk_index == 6'd31) & (sclk_cnt == 10'd0)) ? ((rw_flag) ? wdata[7] : 1'b0) :
                (send_flag & (sclk_index == 6'd33) & (sclk_cnt == 10'd0)) ? ((rw_flag) ? wdata[6] : 1'b0) :
                (send_flag & (sclk_index == 6'd35) & (sclk_cnt == 10'd0)) ? ((rw_flag) ? wdata[5] : 1'b0) :
                (send_flag & (sclk_index == 6'd37) & (sclk_cnt == 10'd0)) ? ((rw_flag) ? wdata[4] : 1'b0) :
                (send_flag & (sclk_index == 6'd39) & (sclk_cnt == 10'd0)) ? ((rw_flag) ? wdata[3] : 1'b0) :
                (send_flag & (sclk_index == 6'd41) & (sclk_cnt == 10'd0)) ? ((rw_flag) ? wdata[2] : 1'b0) :
                (send_flag & (sclk_index == 6'd43) & (sclk_cnt == 10'd0)) ? ((rw_flag) ? wdata[1] : 1'b0) :
                (send_flag & (sclk_index == 6'd45) & (sclk_cnt == 10'd0)) ? ((rw_flag) ? wdata[0] : 1'b0) :
                (send_flag & (sclk_index == 6'd47) & (sclk_cnt == 10'd0)) ? 1'b0 : mosi;

// rdata
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        rdata <= 8'b0;
    else begin
        rdata[7] <= (send_flag & (sclk_index == 6'd32) & (sclk_cnt == 10'd0)) ? miso : rdata[7];
        rdata[6] <= (send_flag & (sclk_index == 6'd34) & (sclk_cnt == 10'd0)) ? miso : rdata[6];
        rdata[5] <= (send_flag & (sclk_index == 6'd36) & (sclk_cnt == 10'd0)) ? miso : rdata[5];
        rdata[4] <= (send_flag & (sclk_index == 6'd38) & (sclk_cnt == 10'd0)) ? miso : rdata[4];
        rdata[3] <= (send_flag & (sclk_index == 6'd40) & (sclk_cnt == 10'd0)) ? miso : rdata[3];
        rdata[2] <= (send_flag & (sclk_index == 6'd42) & (sclk_cnt == 10'd0)) ? miso : rdata[2];
        rdata[1] <= (send_flag & (sclk_index == 6'd44) & (sclk_cnt == 10'd0)) ? miso : rdata[1];
        rdata[0] <= (send_flag & (sclk_index == 6'd46) & (sclk_cnt == 10'd0)) ? miso : rdata[0];
    end

// done
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        done <= 0;
    else
        done <= (start_wr_posedge | start_re_posedge) ? 1'b0 :
                (done_flag & (done_cnt == 4'd15))     ? 1'b1 : done;

endmodule
