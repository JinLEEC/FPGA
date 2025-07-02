`timescale 1ns / 1ps
module vending(
    input             clock,
    input             n_reset,
    input      [10:0] money,
    input      [2:0]  sel,     
    input             refund, 
    output reg        done
);

// Define states
reg [10:0] present_state, next_state;
parameter IDLE     = 11'd0;
parameter DISPENSE = 11'd1;
parameter won_100  = 11'd100;
parameter won_200  = 11'd200;
parameter won_300  = 11'd300;
parameter won_400  = 11'd400;
parameter won_500  = 11'd500;
parameter won_600  = 11'd600;
parameter won_700  = 11'd700;
parameter won_800  = 11'd800;
parameter won_900  = 11'd900;
parameter won_1000 = 11'd1000;

// State flag
wire idle_flag     = (present_state == IDLE)      ? 1'b1 : 1'b0;
wire dispense_flag = (present_state == DISPENSE)  ? 1'b1 : 1'b0;
wire won_100_flag  = (present_state == won_100)   ? 1'b1 : 1'b0;
wire won_200_flag  = (present_state == won_200)   ? 1'b1 : 1'b0;
wire won_300_flag  = (present_state == won_300)   ? 1'b1 : 1'b0;
wire won_400_flag  = (present_state == won_400)   ? 1'b1 : 1'b0;
wire won_500_flag  = (present_state == won_500)   ? 1'b1 : 1'b0;
wire won_600_flag  = (present_state == won_600)   ? 1'b1 : 1'b0;
wire won_700_flag  = (present_state == won_700)   ? 1'b1 : 1'b0;
wire won_800_flag  = (present_state == won_800)   ? 1'b1 : 1'b0;
wire won_900_flag  = (present_state == won_900)   ? 1'b1 : 1'b0;
wire won_1000_flag = (present_state == won_1000)  ? 1'b1 : 1'b0;


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
        IDLE : begin
            next_state =     (tot_money == 11'd100)  ? won_100  : 
                             (tot_money == 11'd200)  ? won_200  : 
                             (tot_money == 11'd300)  ? won_300  : 
                             (tot_money == 11'd400)  ? won_400  : 
                             (tot_money == 11'd500) ? ((sel == 3'd0) ? DISPENSE : won_500) : 
                             (tot_money == 11'd600) ? ((sel == 3'd1) ? DISPENSE : won_600) : 
                             (tot_money == 11'd700) ? ((sel == 3'd2) ? DISPENSE : won_700) : 
                             (tot_money == 11'd800) ? ((sel == 3'd3) ? DISPENSE : won_800) : 
                             (tot_money == 11'd900) ? ((sel == 3'd4) ? DISPENSE : won_900) : 
                             (tot_money == 11'd1000) ? ((sel == 3'd5) ? DISPENSE : won_1000) : IDLE;
        end

        won_100 :  begin
            next_state =    (tot_money == 11'd100) ? won_200 : 
                            (tot_money == 11'd200) ? won_300 : 
                            (tot_money == 11'd300) ? won_400 : 
                            (tot_money == 11'd400) ? ((sel == 3'd0) ? DISPENSE : won_500) : 
                            (tot_money == 11'd500) ? ((sel == 3'd1) ? DISPENSE : won_600) : 
                            (tot_money == 11'd600) ? ((sel == 3'd2) ? DISPENSE : won_700) : 
                            (tot_money == 11'd700) ? ((sel == 3'd3) ? DISPENSE : won_800) : 
                            (tot_money == 11'd800) ? ((sel == 3'd4) ? DISPENSE : won_900) : 
                            (tot_money == 11'd900) ? ((sel == 3'd5) ? DISPENSE : won_1000) : 
                            (refund) ? IDLE : won_100;
        end

        won_200 :  begin 
            next_state =    (tot_money == 11'd100) ? won_300 :
                            (tot_money == 11'd200) ? won_400 : 
                            (tot_money == 11'd300) ? ((sel == 3'd0) ? DISPENSE : won_500) : 
                            (tot_money == 11'd400) ? ((sel == 3'd1) ? DISPENSE : won_600) : 
                            (tot_money == 11'd500) ? ((sel == 3'd2) ? DISPENSE : won_700) : 
                            (tot_money == 11'd600) ? ((sel == 3'd3) ? DISPENSE : won_800) :
                            (tot_money == 11'd700) ? ((sel == 3'd4) ? DISPENSE : won_900) : 
                            (tot_money == 11'd800) ? ((sel == 3'd5) ? DISPENSE : won_1000) : 
                            (refund) ? IDLE : won_200;
        end

        won_300 : begin
            next_state =    (tot_money == 11'd100) ? won_400 :
                            (tot_money == 11'd200) ? ((sel == 3'd0) ? DISPENSE : won_500) : 
                            (tot_money == 11'd300) ? ((sel == 3'd1) ? DISPENSE : won_600) : 
                            (tot_money == 11'd400) ? ((sel == 3'd2) ? DISPENSE : won_700) : 
                            (tot_money == 11'd500) ? ((sel == 3'd3) ? DISPENSE : won_800) : 
                            (tot_money == 11'd600) ? ((sel == 3'd4) ? DISPENSE : won_900) : 
                            (tot_money == 11'd700) ? ((sel == 3'd5) ? DISPENSE : won_1000) : 
                            (refund) ? IDLE : won_300;
        end
        
        won_400 : begin
             next_state =   (tot_money == 11'd100) ? ((sel == 3'd0) ? DISPENSE : won_500) : 
                            (tot_money == 11'd200) ? ((sel == 3'd1) ? DISPENSE : won_600) : 
                            (tot_money == 11'd300) ? ((sel == 3'd2) ? DISPENSE : won_700) : 
                            (tot_money == 11'd400) ? ((sel == 3'd3) ? DISPENSE : won_800) : 
                            (tot_money == 11'd500) ? ((sel == 3'd4) ? DISPENSE : won_900) : 
                            (tot_money == 11'd600) ? ((sel == 3'd5) ? DISPENSE : won_1000) : 
                            (refund) ? IDLE : won_400;
        end
        
        won_500 : begin 
            next_state =    (sel == 3'd0) ? DISPENSE : 
                            (tot_money == 11'd100) ? ((sel == 3'd1) ? DISPENSE : won_600) : 
                            (tot_money == 11'd200) ? ((sel == 3'd2) ? DISPENSE : won_700) : 
                            (tot_money == 11'd300) ? ((sel == 3'd3) ? DISPENSE : won_800) : 
                            (tot_money == 11'd400) ? ((sel == 3'd4) ? DISPENSE : won_900) : 
                            (tot_money == 11'd500) ? ((sel == 3'd5) ? DISPENSE : won_1000) : 
                            (refund) ? IDLE : won_500;
        end
        
        won_600 : begin 
            next_state =    (sel == 3'd1) ? DISPENSE : 
                            (tot_money == 11'd100) ? ((sel == 3'd2) ? DISPENSE : won_700) : 
                            (tot_money == 11'd200) ? ((sel == 3'd3) ? DISPENSE : won_800) : 
                            (tot_money == 11'd300) ? ((sel == 3'd4) ? DISPENSE : won_900) : 
                            (tot_money == 11'd400) ? ((sel == 3'd5) ? DISPENSE : won_1000) : 
                            (refund) ? IDLE : won_600;
        end
        
        won_700 : begin
             next_state =   (sel == 3'd2) ? DISPENSE : 
                            (tot_money == 11'd100) ? ((sel == 3'd3) ? DISPENSE : won_800) :
                            (tot_money == 11'd200) ? ((sel == 3'd4) ? DISPENSE : won_900) : 
                            (tot_money == 11'd300) ? ((sel == 3'd5) ? DISPENSE:  won_1000) : 
                            (refund) ? IDLE : won_700;
        end
        
        won_800 : begin 
            next_state =    (sel == 3'd3) ? DISPENSE : 
                            (tot_money == 11'd100) ? ((sel == 3'd4) ? DISPENSE : won_900) : 
                            (tot_money == 11'd200) ? ((sel == 3'd5) ? DISPENSE : won_1000) : 
                            (refund) ? IDLE : won_800;
        end
        
        won_900 : begin 
             next_state =   (sel == 3'd4) ? DISPENSE : 
                            (tot_money == 11'd100) ? ((sel == 3'd5) ? DISPENSE : won_1000) : 
                            (refund) ? IDLE : won_1000;
        end
        
        won_1000 : next_state = (sel == 3'd5) ? DISPENSE : 
                                (refund) ? IDLE : won_1000;

        DISPENSE : next_state = IDLE;
    endcase
end

always@(negedge n_reset, posedge clock)
    if(!n_reset) 
        done <= 0;
    else
        done <= (present_state == DISPENSE) ? 1'b1 : 1'b0;

reg [10:0] tot_money;
always@(negedge n_reset, posedge clock)
    if(!n_reset)    
        tot_money <= 0;
    else
       tot_money <= ((present_state == DISPENSE) | refund) ? 11'b0 : tot_money + money;

endmodule
