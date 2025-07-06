module uart_tx(
    input               n_reset, 
    input               mclk,
    input   [15:0]      baudrate,
    input   [1:0]       parity_sel, // 0: none, 1: even, 2: odd
    input               stop_sel,   // 0: 1 stop bit, 1: 2 stop bit
    input   [7:0]       tdata,
    input               send_flag,
    output  reg         txd,
    output              done
);

// Define states
reg present_state, next_state;
parameter IDLE  = 1'd0;
parameter RUN   = 1'd1;

// State flag
wire idle_flag  = (present_state == IDLE)  ? 1'b1 : 1'b0;
wire run_flag   = (present_state == RUN)   ? 1'b1 : 1'b0;

// State update
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        present_state <= IDLE;
    else
        present_state <= next_state;

// State transition
always@(*) begin
    next_state = present_state;
    case(present_state)
        IDLE  : next_state = (idle_flag & send_flag) ? RUN : IDLE;
        RUN   : next_state = ((parity_sel == 2'b00) & (stop_sel == 1'b0)  & (cnt2 == 4'd10)  & (cnt1 == 16'd0)) ? IDLE :
                             ((parity_sel == 2'b00) & (stop_sel == 1'b1)  & (cnt2 == 4'd11)  & (cnt1 == 16'd0)) ? IDLE :
                             ((parity_sel != 2'b00) & (stop_sel == 1'b0)  & (cnt2 == 4'd11)  & (cnt1 == 16'd0)) ? IDLE :
                             ((parity_sel != 2'b00) & (stop_sel == 1'b1)  & (cnt2 == 4'd11)  & (cnt1 == 16'd0)) ? IDLE : RUN;
    endcase
end

// Counter for baudrate, 1-bit duration
reg [15:0] cnt1;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        cnt1 <= 0;
    else
        cnt1 <= (~run_flag) ? 16'b0 :
                (cnt1 == baudrate) ? 16'b0 : cnt1 + 1;

// Transmitting bit counter
reg [3:0] cnt2;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        cnt2 <= 0;
    else
        cnt2 <= (~run_flag) ? 16'b0 :
                (cnt1 == baudrate) ? cnt2 + 1 : cnt2;

// txd
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        txd <= 0;
    else
        txd <= (idle_flag) ? 1'b1 :
               ((cnt2 == 4'd0) & (cnt1 == 16'd0)) ? 1'b0 : // start bit
               ((cnt2 == 4'd1) & (cnt1 == 16'd0)) ? tdata[0] :
               ((cnt2 == 4'd2) & (cnt1 == 16'd0)) ? tdata[1] :
               ((cnt2 == 4'd3) & (cnt1 == 16'd0)) ? tdata[2] :
               ((cnt2 == 4'd4) & (cnt1 == 16'd0)) ? tdata[3] :
               ((cnt2 == 4'd5) & (cnt1 == 16'd0)) ? tdata[4] :
               ((cnt2 == 4'd6) & (cnt1 == 16'd0)) ? tdata[5] :
               ((cnt2 == 4'd7) & (cnt1 == 16'd0)) ? tdata[6] :
               ((cnt2 == 4'd8) & (cnt1 == 16'd0)) ? tdata[7] :

               ((parity_sel == 2'b00) & (stop_sel == 1'b0)  &  (cnt2 == 4'd9) & (cnt1 == 16'd0)) ? 1'b1 :

               ((parity_sel == 2'b00) & (stop_sel == 1'b1)  & (cnt2 == 4'd9)  & (cnt1 == 16'd0)) ? 1'b1 :
               ((parity_sel == 2'b00) & (stop_sel == 1'b1)  & (cnt2 == 4'd10) & (cnt1 == 16'd0)) ? 1'b1 :

               ((parity_sel != 2'b00) & (stop_sel == 1'b0)  & (cnt2 == 4'd9)  & (cnt1 == 16'd0)) ? parity :
               ((parity_sel != 2'b00) & (stop_sel == 1'b0)  & (cnt2 == 4'd10) & (cnt1 == 16'd0)) ? 1'b1 :

               ((parity_sel != 2'b00) & (stop_sel == 1'b1)  & (cnt2 == 4'd9)  & (cnt1 == 16'd0)) ? parity :
               ((parity_sel != 2'b00) & (stop_sel == 1'b1)  & (cnt2 == 4'd10) & (cnt1 == 16'd0)) ? 1'b1 :
               ((parity_sel != 2'b00) & (stop_sel == 1'b1)  & (cnt2 == 4'd11) & (cnt1 == 16'd0)) ? 1'b1 : txd;

// parity
wire tdata_xor = tdata[0]^tdata[1]^tdata[2]^tdata[3]^tdata[4]^tdata[5]^tdata[6]^tdata[7]; // calculate parity from tdata
reg parity;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        parity <= 0;
    else
        parity <= (parity_sel == 2'b01) ? tdata_xor : ~tdata_xor;

assign done = idle_flag;


endmodule
