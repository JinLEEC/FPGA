// Define Slave internal register
`define SLAVE_REG1 8'h10
`define SLAVE_REG2 8'h11
`define SLAVE_REG3 8'h12
`define SLAVE_REG4 8'h13

module spi_slave(
    input           clock,
    input           n_reset, 
    input           ss,
    input           sclk,
    input           mosi,
    output  reg     miso
);

// Parameter
parameter SLAVE_IDW = 8'hff;
parameter SLAVE_IDR = 8'h00;

// Define States
reg [2:0] present_state, next_state;
parameter IDLE    = 3'd0;
parameter SLAVEID = 3'd1;
parameter WADDR   = 3'd2;
parameter WDATA   = 3'd3;
parameter RADDR   = 3'd4;
parameter RDATA   = 3'd5;
parameter DONE    = 3'd6;

// State flag
wire idle_flag    = (present_state == IDLE)    ? 1'b1 : 1'b0;
wire slaveid_flag = (present_state == SLAVEID) ? 1'b1 : 1'b0;
wire waddr_flag   = (present_state == WADDR)   ? 1'b1 : 1'b0;
wire wdata_flag   = (present_state == WDATA)   ? 1'b1 : 1'b0;
wire raddr_flag   = (present_state == RADDR)   ? 1'b1 : 1'b0;
wire rdata_flag   = (present_state == RDATA)   ? 1'b1 : 1'b0;
wire done_flag    = (present_state == DONE)    ? 1'b1 : 1'b0;

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
        IDLE    : next_state = (idle_flag & ss_negedge)                 ? SLAVEID : IDLE;
        SLAVEID : next_state = (slaveid_flag & (sla_sclk_neg_cnt == 4'd8)) ? 
                               ((slave_id == SLAVE_IDW) ? WADDR : 
                                (slave_id == SLAVE_IDR) ? RADDR : IDLE) : SLAVEID;
        WADDR   : next_state = (waddr_flag & (wa_sclk_neg_cnt == 4'd8)) ? WDATA : WADDR;
        WDATA   : next_state = (wdata_flag & ss_posedge)                ? DONE : WDATA;
        RADDR   : next_state = (raddr_flag & ra_sclk_neg_cnt == 4'd8)   ? RDATA : RADDR;
        RDATA   : next_state = (rdata_flag & ss_posedge)                ? DONE : RDATA;
        DONE    : next_state = (done_flag & (done_cnt == 2'd3))         ? IDLE : DONE;
    endcase
end


// ss_posedge: IDLE -> SLAVEID
// ss_negedge: DONE -> IDLE
reg ss_1d, ss_2d;
wire ss_posedge = ss_1d & ~ss_2d;
wire ss_negedge = ~ss_1d & ss_2d;
always@(negedge n_reset, posedge clock)
    if(!n_reset) begin
        ss_1d <= 0;
        ss_2d <= 0;
    end
    else begin
        ss_1d <= ss;
        ss_2d <= ss_1d;
    end

// sclk positive, negative edge
reg sclk_1d, sclk_2d;
wire sclk_posedge = sclk_1d & ~sclk_2d;
wire sclk_negedge = ~sclk_1d & sclk_2d;
always@(negedge n_reset, posedge clock)
    if(!n_reset) begin
        sclk_1d <= 0;
        sclk_2d <= 0;
    end
    else begin
        sclk_1d <= sclk;
        sclk_2d <= sclk_1d;
    end

// mosi
reg mosi_1d, mosi_2d;
always@(negedge n_reset, posedge clock)
    if(!n_reset) begin
        mosi_1d <= 0;
        mosi_2d <= 0;
    end
    else begin
        mosi_1d <= mosi;
        mosi_2d <= mosi_1d;
    end

// Count sclk_negedge for slaveid state
reg [3:0] sla_sclk_neg_cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        sla_sclk_neg_cnt <= 0;
    else
        sla_sclk_neg_cnt <= (~slaveid_flag) ? 4'b0 :
                            (sclk_negedge) ? sla_sclk_neg_cnt + 1 : sla_sclk_neg_cnt;

// read slaveid from mosi
reg [7:0] slave_id;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        slave_id <= 0;
    else begin
        slave_id[7] <= (idle_flag) ? 8'b0 : (slaveid_flag & sclk_posedge & (sla_sclk_neg_cnt == 4'd0)) ? mosi_2d : slave_id[7];
        slave_id[6] <= (idle_flag) ? 8'b0 : (slaveid_flag & sclk_posedge & (sla_sclk_neg_cnt == 4'd1)) ? mosi_2d : slave_id[6];
        slave_id[5] <= (idle_flag) ? 8'b0 : (slaveid_flag & sclk_posedge & (sla_sclk_neg_cnt == 4'd2)) ? mosi_2d : slave_id[5];
        slave_id[4] <= (idle_flag) ? 8'b0 : (slaveid_flag & sclk_posedge & (sla_sclk_neg_cnt == 4'd3)) ? mosi_2d : slave_id[4];
        slave_id[3] <= (idle_flag) ? 8'b0 : (slaveid_flag & sclk_posedge & (sla_sclk_neg_cnt == 4'd4)) ? mosi_2d : slave_id[3];
        slave_id[2] <= (idle_flag) ? 8'b0 : (slaveid_flag & sclk_posedge & (sla_sclk_neg_cnt == 4'd5)) ? mosi_2d : slave_id[2];
        slave_id[1] <= (idle_flag) ? 8'b0 : (slaveid_flag & sclk_posedge & (sla_sclk_neg_cnt == 4'd6)) ? mosi_2d : slave_id[1];
        slave_id[0] <= (idle_flag) ? 8'b0 : (slaveid_flag & sclk_posedge & (sla_sclk_neg_cnt == 4'd7)) ? mosi_2d : slave_id[0];
    end

// Count sclk_negedge for waddr state
reg [3:0] wa_sclk_neg_cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        wa_sclk_neg_cnt <= 0;
    else
        wa_sclk_neg_cnt <= (~waddr_flag) ? 4'b0 :
                           (sclk_negedge) ? wa_sclk_neg_cnt + 1 : wa_sclk_neg_cnt;

// waddr from mosi
reg [7:0] waddr;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        waddr <= 0;
    else begin
        waddr[7] <= (idle_flag) ? 8'b0 : (waddr_flag & sclk_posedge & (wa_sclk_neg_cnt == 4'd0)) ? mosi_2d : waddr[7];
        waddr[6] <= (idle_flag) ? 8'b0 : (waddr_flag & sclk_posedge & (wa_sclk_neg_cnt == 4'd1)) ? mosi_2d : waddr[6];
        waddr[5] <= (idle_flag) ? 8'b0 : (waddr_flag & sclk_posedge & (wa_sclk_neg_cnt == 4'd2)) ? mosi_2d : waddr[5];
        waddr[4] <= (idle_flag) ? 8'b0 : (waddr_flag & sclk_posedge & (wa_sclk_neg_cnt == 4'd3)) ? mosi_2d : waddr[4];
        waddr[3] <= (idle_flag) ? 8'b0 : (waddr_flag & sclk_posedge & (wa_sclk_neg_cnt == 4'd4)) ? mosi_2d : waddr[3];
        waddr[2] <= (idle_flag) ? 8'b0 : (waddr_flag & sclk_posedge & (wa_sclk_neg_cnt == 4'd5)) ? mosi_2d : waddr[2];
        waddr[1] <= (idle_flag) ? 8'b0 : (waddr_flag & sclk_posedge & (wa_sclk_neg_cnt == 4'd6)) ? mosi_2d : waddr[1];
        waddr[0] <= (idle_flag) ? 8'b0 : (waddr_flag & sclk_posedge & (wa_sclk_neg_cnt == 4'd7)) ? mosi_2d : waddr[0];
    end

// Count sclk_negedge for wdata state
reg [3:0] wd_sclk_neg_cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)    
        wd_sclk_neg_cnt <= 0;
    else
        wd_sclk_neg_cnt <= (~wdata_flag) ? 4'b0 :
                           (sclk_negedge) ? wd_sclk_neg_cnt + 1 : wd_sclk_neg_cnt;

// wdata from mosi
reg [7:0] wdata;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        wdata <= 0;
    else begin
        wdata[7] <= (idle_flag) ? 8'b0 : (wdata_flag & sclk_posedge & (wd_sclk_neg_cnt == 4'd0)) ? mosi_2d : wdata[7];
        wdata[6] <= (idle_flag) ? 8'b0 : (wdata_flag & sclk_posedge & (wd_sclk_neg_cnt == 4'd1)) ? mosi_2d : wdata[6];
        wdata[5] <= (idle_flag) ? 8'b0 : (wdata_flag & sclk_posedge & (wd_sclk_neg_cnt == 4'd2)) ? mosi_2d : wdata[5];
        wdata[4] <= (idle_flag) ? 8'b0 : (wdata_flag & sclk_posedge & (wd_sclk_neg_cnt == 4'd3)) ? mosi_2d : wdata[4];
        wdata[3] <= (idle_flag) ? 8'b0 : (wdata_flag & sclk_posedge & (wd_sclk_neg_cnt == 4'd4)) ? mosi_2d : wdata[3];
        wdata[2] <= (idle_flag) ? 8'b0 : (wdata_flag & sclk_posedge & (wd_sclk_neg_cnt == 4'd5)) ? mosi_2d : wdata[2];
        wdata[1] <= (idle_flag) ? 8'b0 : (wdata_flag & sclk_posedge & (wd_sclk_neg_cnt == 4'd6)) ? mosi_2d : wdata[1];
        wdata[0] <= (idle_flag) ? 8'b0 : (wdata_flag & sclk_posedge & (wd_sclk_neg_cnt == 4'd7)) ? mosi_2d : wdata[0];
    end

// Counter sclk_negedge for raddr state
reg [3:0] ra_sclk_neg_cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        ra_sclk_neg_cnt <= 0;
    else    
        ra_sclk_neg_cnt <= (~raddr_flag) ? 4'b0 :
                           (sclk_negedge) ? ra_sclk_neg_cnt + 1 : ra_sclk_neg_cnt;

// raddr from mosi
reg[7:0] raddr;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        raddr <= 0;
    else begin
        raddr[7] <= (idle_flag) ? 8'b0 : (raddr_flag & sclk_posedge & (ra_sclk_neg_cnt == 4'd0)) ? mosi_2d : raddr[7];
        raddr[6] <= (idle_flag) ? 8'b0 : (raddr_flag & sclk_posedge & (ra_sclk_neg_cnt == 4'd1)) ? mosi_2d : raddr[6];
        raddr[5] <= (idle_flag) ? 8'b0 : (raddr_flag & sclk_posedge & (ra_sclk_neg_cnt == 4'd2)) ? mosi_2d : raddr[5];
        raddr[4] <= (idle_flag) ? 8'b0 : (raddr_flag & sclk_posedge & (ra_sclk_neg_cnt == 4'd3)) ? mosi_2d : raddr[4];
        raddr[3] <= (idle_flag) ? 8'b0 : (raddr_flag & sclk_posedge & (ra_sclk_neg_cnt == 4'd4)) ? mosi_2d : raddr[3];
        raddr[2] <= (idle_flag) ? 8'b0 : (raddr_flag & sclk_posedge & (ra_sclk_neg_cnt == 4'd5)) ? mosi_2d : raddr[2];
        raddr[1] <= (idle_flag) ? 8'b0 : (raddr_flag & sclk_posedge & (ra_sclk_neg_cnt == 4'd6)) ? mosi_2d : raddr[1];
        raddr[0] <= (idle_flag) ? 8'b0 : (raddr_flag & sclk_posedge & (ra_sclk_neg_cnt == 4'd7)) ? mosi_2d : raddr[0];
    end

// Count sclk_negedge for rdata state
reg [3:0] rd_sclk_neg_cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        rd_sclk_neg_cnt <= 0;
    else
        rd_sclk_neg_cnt <= (~rdata_flag) ? 4'b0 :
                           (sclk_negedge) ? rd_sclk_neg_cnt + 1 : rd_sclk_neg_cnt;

// sclk_negedge_1d
reg sclk_negedge_1d;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        sclk_negedge_1d <= 0;
    else
        sclk_negedge_1d <= sclk_negedge;

// sclk_posedge_1d
reg sclk_posedge_1d;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        sclk_posedge_1d <= 0;
    else
        sclk_posedge_1d <= sclk_posedge;

// miso
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        miso <= 0;
    else
        miso <= (idle_flag) ? 1'b0 :
                (sclk_negedge_1d & (rd_sclk_neg_cnt == 4'd0)) ? rdata[7] :
                (sclk_negedge_1d & (rd_sclk_neg_cnt == 4'd1)) ? rdata[6] :
                (sclk_negedge_1d & (rd_sclk_neg_cnt == 4'd2)) ? rdata[5] :
                (sclk_negedge_1d & (rd_sclk_neg_cnt == 4'd3)) ? rdata[4] :
                (sclk_negedge_1d & (rd_sclk_neg_cnt == 4'd4)) ? rdata[3] :
                (sclk_negedge_1d & (rd_sclk_neg_cnt == 4'd5)) ? rdata[2] :
                (sclk_negedge_1d & (rd_sclk_neg_cnt == 4'd6)) ? rdata[1] :
                (sclk_negedge_1d & (rd_sclk_neg_cnt == 4'd7)) ? rdata[0] : miso;

// done state counter
reg [1:0] done_cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)    
        done_cnt <= 0;
    else    
        done_cnt <= (done_flag) ? done_cnt + 1 : 2'b0;

// write data to slave internal register
reg [7:0] slave_reg1, slave_reg2, slave_reg3, slave_reg4;
always@(negedge n_reset, posedge clock)
    if(!n_reset) begin
        slave_reg1 <= 0;
        slave_reg2 <= 0;
        slave_reg3 <= 0;
        slave_reg4 <= 0;
    end
    else begin
        slave_reg1 <= (done_flag & (waddr == `SLAVE_REG1)) ? wdata : slave_reg1;
        slave_reg2 <= (done_flag & (waddr == `SLAVE_REG2)) ? wdata : slave_reg2;
        slave_reg3 <= (done_flag & (waddr == `SLAVE_REG3)) ? wdata : slave_reg3;
        slave_reg4 <= (done_flag & (waddr == `SLAVE_REG4)) ? wdata : slave_reg4;
    end

// read data from slave internal register
reg [7:0] rdata;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        rdata <= 0;
    else
        rdata <= (idle_flag) ? 8'b0 :
                 (raddr_flag & sclk_posedge_1d & (ra_sclk_neg_cnt == 4'd7) & (raddr == `SLAVE_REG1)) ? slave_reg1 :
                 (raddr_flag & sclk_posedge_1d & (ra_sclk_neg_cnt == 4'd7) & (raddr == `SLAVE_REG2)) ? slave_reg2 :
                 (raddr_flag & sclk_posedge_1d & (ra_sclk_neg_cnt == 4'd7) & (raddr == `SLAVE_REG3)) ? slave_reg3 :
                 (raddr_flag & sclk_posedge_1d & (ra_sclk_neg_cnt == 4'd7) & (raddr == `SLAVE_REG4)) ? slave_reg4 : rdata;

endmodule
