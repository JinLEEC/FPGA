module door_lock(
    input              clock,
    input              n_reset, 
    input              touch,
    input      [13:0]  password,
    output             sound,
    output reg [1:0]   chance
);

`define NUMBER 14'd9872

// Define states
reg [2:0] present_state, next_state;
parameter IDLE     = 3'd0;
parameter START    = 3'd1;
parameter PASSWORD = 3'd2;
parameter WRONG    = 3'd3;
parameter LOCK     = 3'd4;
parameter OPEN     = 3'd5;

// State flag
wire idle_flag     = (present_state == IDLE)     ? 1'b1 : 1'b0;
wire start_flag    = (present_state == START)    ? 1'b1 : 1'b0;
wire password_flag = (present_state == PASSWORD) ? 1'b1 : 1'b0;
wire wrong_flag    = (present_state == WRONG)    ? 1'b1 : 1'b0;
wire lock_flag     = (present_state == LOCK)     ? 1'b1 : 1'b0;
wire open_flag     = (present_state == OPEN)     ? 1'b1 : 1'b0;

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
        IDLE     : next_state = (idle_flag & touch_2d)               ? START : IDLE;
        START    : next_state = (start_flag & (start_cnt == 4'd5))   ? PASSWORD : START;
        PASSWORD : next_state = (password_flag & (correct == 1'b1))  ? OPEN : WRONG;
        WRONG    : next_state = (chance == 2'd2)                     ? LOCK : PASSWORD;
        LOCK     : next_state = (lock_flag & (lock_cnt == 12'd29))   ? IDLE : LOCK;
        OPEN     : next_state = (open_flag & (open_cnt == 11'd19))   ? IDLE : OPEN;
    endcase
end

// password 2-clock delay
reg [13:0] password_1d, password_2d;
always@(negedge n_reset, posedge clock)
    if(!n_reset) begin
        password_1d <= 0;
        password_2d <= 0;
    end
    else begin
        password_1d <= password;
        password_2d <= password_1d;
    end

// touch 2-clock delay
reg touch_1d, touch_2d;
always@(negedge n_reset, posedge clock)
    if(!n_reset) begin
        touch_1d <= 0;
        touch_2d <= 0;
    end
    else begin
        touch_1d <= touch;
        touch_2d <= touch_1d;
    end

// start state counter
reg [3:0] start_cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        start_cnt <= 0;
    else
        start_cnt <= (start_flag) ? start_cnt + 1 : 4'b0;

// lock state counter
reg [11:0] lock_cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        lock_cnt <= 0;
    else
        lock_cnt <= (lock_flag) ? lock_cnt + 1 : 12'b0;

// open state counter
reg [10:0] open_cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        open_cnt <= 0;
    else
        open_cnt <= (open_flag) ? open_cnt + 1 : 11'b0;

// compare password
reg correct;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        correct <= 0;
    else
        correct <= (password_2d == `NUMBER) ? 1'b1 : 1'b0;

// sound when wrong state
assign sound = (present_state == WRONG);

// 3 times to try 
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        chance <= 0;
    else 
        chance <= (wrong_flag) ? chance + 1 : chance;

endmodule
