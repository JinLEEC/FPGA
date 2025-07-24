module sram_rw_ctrl(
    input            clock,
    input            n_reset,
    input            btn,
    input    [3:0]   sw,
    output   [3:0]   led
);

wire btn_out_clear;

btn_in t0(
    .clock              (clock),
    .n_reset            (n_reset),
    .btn_in             (btn),
    .btn_out            (btn_out_clear)
);

// Define states
reg [2:0] present_state, next_state;
parameter IDLE     = 3'd0;
parameter ADDRESSW = 3'd1;
parameter WRITE    = 3'd2;
parameter ADDRESSR = 3'd3;
parameter READ     = 3'd5;

// State flag
wire idle_flag     = (present_state == IDLE)     ? 1'b1 : 1'b0;
wire addressw_flag = (present_state == ADDRESSW) ? 1'b1 : 1'b0;
wire write_flag    = (present_state == WRITE)    ? 1'b1 : 1'b0;
wire addressr_flag = (present_state == ADDRESSR) ? 1'b1 : 1'b0;
wire read_flag     = (present_state == READ)     ? 1'b1 : 1'b0;

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
        IDLE     : next_state = (idle_flag & btn_out_clear)     ? ADDRESSW : IDLE;
        ADDRESSW : next_state = (addressw_flag & btn_out_clear) ? WRITE : ADDRESSW;
        WRITE    : next_state = (write_flag & btn_out_clear)    ? ADDRESSR : WRITE;
        ADDRESSR : next_state = (addressr_flag & btn_out_clear) ? READ : ADDRESSR;
        READ     : next_state = (read_flag & btn_out_clear)     ? IDLE : READ;
    endcase
end

// Instantiation Memory IP
mem_gen t1(
    .clka           (clock),
    .dina           (wdata),
    .douta          (rdata_mem),
    .ena            (ena),
    .wea            (write_flag),
    .addra          (current_addr)
);

wire [3:0] current_addr;
assign current_addr = (addressw_flag) ? addressw :
                      (addressr_flag) ? addressr : 4'b0;

wire ena = (addressw_flag | write_flag | addressr_flag | read_flag);

// address for write
reg [3:0] addressw;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        addressw <= 0;
    else
        addressw <= (idle_flag) ? 4'b0 : (addressw_flag) ? sw : addressw;

// write data
reg [3:0] wdata;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        wdata <= 0;
    else
        wdata <= (idle_flag) ? 4'b0 : (write_flag) ? sw : wdata;

// address for read
reg [3:0] addressr;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        addressr <= 0;
    else
        addressr <= (idle_flag) ? 4'b0 : (addressr_flag) ? sw : addressr;

// read data
wire [3:0] rdata_mem;
reg [3:0] rdata;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        rdata <= 0;
    else
        rdata <= (idle_flag) ? 4'b0 : (read_flag) ? rdata_mem : rdata;

assign led = rdata;

endmodule
