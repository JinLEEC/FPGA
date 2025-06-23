// send total 24-bit as mosi
module spi_master(
    input               n_reset,
    input               clock,
    input        [9:0]  freq, // freq = 100
    input               start_w,
    input               start_r,
    input        [7:0]  addr,
    input        [7:0]  wdata,
    output  reg  [7:0]  rdata,
    output  reg         done,
    output  reg         ss,
    output  reg         sck,
    output  reg         mosi,
    input               miso
);

parameter SLAVE_IDW = 8'h64;
parameter SLAVE_IDR = 8'h65;

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
        IDLE  : next_state = (idle_flag & (startw_posedge | startr_posedge))         ? READY : IDLE;
        READY : next_state = (ready_flag & (ready_cnt == freq))                      ? SEND : READY;
        SEND  : next_state = (send_flag & (sck_index == 6'd48) & (sck_cnt == 10'b0)) ? DONE : SEND;
        DONE  : next_state = (done_flag & (done_cnt == 4'd15))                       ? IDLE : DONE;
    endcase
end

// start_w pulse
reg startw_1d, startw_2d;
wire startw_posedge = startw_1d & ~startw_2d;
always@(negedge n_reset, posedge clock)
    if(!n_reset) begin
        startw_1d <= 0;
        startw_2d <= 0;
    end
    else begin
        startw_1d <= start_w;
        startw_2d <= startw_1d;
    end

// start_r pulse
reg startr_1d, startr_2d;
wire startr_posedge = startr_1d & ~startr_2d;
always@(negedge n_reset, posedge clock)
    if(!n_reset) begin
        startr_1d <= 0;
        startr_2d <= 0;
    end
    else begin
        startr_1d <= start_r;
        startr_2d <= startr_1d;
end

// read / write flag, 0: write , 1: read
reg rw_flag;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        rw_flag <= 0;
    else
        rw_flag <= (startw_posedge) ? 1'b0 :
                   (startr_posedge) ? 1'b1 : rw_flag;

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

// sck counter
reg [9:0] sck_cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        sck_cnt <= 0;
    else    
        sck_cnt <= (~send_flag) ? 1'b0 :
                   (sck_cnt == freq) ? 10'b0 : sck_cnt + 1;

// sck index
reg [5:0] sck_index;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        sck_index <= 0;
    else    
        sck_index <= (~send_flag) ? 6'b0 :
                     (sck_cnt == 10'b0) ? sck_index + 1 : sck_index;

// sck
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        sck <= 0;
    else
        sck <= (~send_flag) ? 1'b0 :
               ((sck_index < 6'd48) & (sck_cnt == 10'b0)) ? ~sck : sck;

// ss: slave select 
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        ss <= 1;
    else
        ss <= (idle_flag)                         ? 1'b1 :
              (ready_flag & (ready_cnt == 10'd0)) ? 1'b0 :
              (done_flag & (done_cnt == 4'd15))   ? 1'b1 : ss;

// mosi
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        mosi <= 0;
    else
        mosi <= (idle_flag) ? 1'b0 :
                (ready_flag & (ready_cnt == 10'd10)) ? (rw_flag ? SLAVE_IDR[7] : SLAVE_IDW[7]) :
                (send_flag & (sck_index == 6'd1) & (sck_cnt == 10'b0)) ? (rw_flag ? SLAVE_IDR[6] : SLAVE_IDW[6]) :
                (send_flag & (sck_index == 6'd3) & (sck_cnt == 10'b0)) ? (rw_flag ? SLAVE_IDR[5] : SLAVE_IDW[5]) :
                (send_flag & (sck_index == 6'd5) & (sck_cnt == 10'b0)) ? (rw_flag ? SLAVE_IDR[4] : SLAVE_IDW[4]) :
                (send_flag & (sck_index == 6'd7) & (sck_cnt == 10'b0)) ? (rw_flag ? SLAVE_IDR[3] : SLAVE_IDW[3]) :
                (send_flag & (sck_index == 6'd9) & (sck_cnt == 10'b0)) ? (rw_flag ? SLAVE_IDR[2] : SLAVE_IDW[2]) :
                (send_flag & (sck_index == 6'd11) & (sck_cnt == 10'b0)) ? (rw_flag ? SLAVE_IDR[1] : SLAVE_IDW[1]) :
                (send_flag & (sck_index == 6'd13) & (sck_cnt == 10'b0)) ? (rw_flag ? SLAVE_IDR[0] : SLAVE_IDW[0]) :
                (send_flag & (sck_index == 6'd15) & (sck_cnt == 10'b0)) ? addr[7] :
                (send_flag & (sck_index == 6'd17) & (sck_cnt == 10'b0)) ? addr[6] :
                (send_flag & (sck_index == 6'd19) & (sck_cnt == 10'b0)) ? addr[5] :
                (send_flag & (sck_index == 6'd21) & (sck_cnt == 10'b0)) ? addr[4] :
                (send_flag & (sck_index == 6'd23) & (sck_cnt == 10'b0)) ? addr[3] :
                (send_flag & (sck_index == 6'd25) & (sck_cnt == 10'b0)) ? addr[2] :
                (send_flag & (sck_index == 6'd27) & (sck_cnt == 10'b0)) ? addr[1] :
                (send_flag & (sck_index == 6'd29) & (sck_cnt == 10'b0)) ? addr[0] :
                (send_flag & (sck_index == 6'd31) & (sck_cnt == 10'b0)) ? (rw_flag ? 1'b0 : wdata[7]) :
                (send_flag & (sck_index == 6'd33) & (sck_cnt == 10'b0)) ? (rw_flag ? 1'b0 : wdata[6]) :
                (send_flag & (sck_index == 6'd35) & (sck_cnt == 10'b0)) ? (rw_flag ? 1'b0 : wdata[5]) :
                (send_flag & (sck_index == 6'd37) & (sck_cnt == 10'b0)) ? (rw_flag ? 1'b0 : wdata[4]) :
                (send_flag & (sck_index == 6'd39) & (sck_cnt == 10'b0)) ? (rw_flag ? 1'b0 : wdata[3]) :
                (send_flag & (sck_index == 6'd41) & (sck_cnt == 10'b0)) ? (rw_flag ? 1'b0 : wdata[2]) :
                (send_flag & (sck_index == 6'd43) & (sck_cnt == 10'b0)) ? (rw_flag ? 1'b0 : wdata[1]) :
                (send_flag & (sck_index == 6'd45) & (sck_cnt == 10'b0)) ? (rw_flag ? 1'b0 : wdata[0]) :
                (send_flag & (sck_index == 6'd47) & (sck_cnt == 10'b0)) ? 1'b0 : mosi;

// rdata
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        rdata <= 8'b0;
    else begin
        rdata[7] <= (send_flag & (sck_index == 6'd32) & (sck_cnt == 10'b0)) ? miso : rdata[7];
        rdata[6] <= (send_flag & (sck_index == 6'd34) & (sck_cnt == 10'b0)) ? miso : rdata[6];
        rdata[5] <= (send_flag & (sck_index == 6'd36) & (sck_cnt == 10'b0)) ? miso : rdata[5];
        rdata[4] <= (send_flag & (sck_index == 6'd38) & (sck_cnt == 10'b0)) ? miso : rdata[4];
        rdata[3] <= (send_flag & (sck_index == 6'd40) & (sck_cnt == 10'b0)) ? miso : rdata[3];
        rdata[2] <= (send_flag & (sck_index == 6'd42) & (sck_cnt == 10'b0)) ? miso : rdata[2];
        rdata[1] <= (send_flag & (sck_index == 6'd44) & (sck_cnt == 10'b0)) ? miso : rdata[1];
        rdata[0] <= (send_flag & (sck_index == 6'd46) & (sck_cnt == 10'b0)) ? miso : rdata[0];
    end

// done
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        done <= 0;
    else
        done <= (startw_posedge | startr_posedge) ? 1'b0 :
                (done_flag & (done_cnt == 4'd15)) ? 1'b1 : done;

endmodule





                






