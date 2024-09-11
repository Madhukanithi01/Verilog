
module router_top (
    input           clock,
    input           resetn,
    input           read_enb_0,
    input           read_enb_1,
    input           read_enb_2,
    input           pkt_valid,
    input[7:0]      data_in,
    output          valid_out_0,
    output          valid_out_1,
    output          valid_out_2,
    output          error,
    output          busy,
    output[7:0]     data_out_0,
    output[7:0]     data_out_1,
    output[7:0]     data_out_2
);
    
    wire            fifo_full, rst_int_reg, detect_add, ld_state, laf_state, full_0, full_1, full_2;
    wire            full_state, lfd_state, parity_done, low_pkt_valid, write_enb_reg;
    wire [7:0]      dout;
    wire            soft_reset_0, soft_reset_1, soft_reset_2, fifo_empty_0, fifo_empty_1, fifo_empty_2;
    wire [2:0]      write_enb;

    // Instantiate the Register Module
    router_reg register (
        .clk          (clock),
        .rst         (resetn),
        .pkt_valid      (pkt_valid),
        .fifo_full      (fifo_full),
        .rst_int_reg    (rst_int_reg),
        .detect_add     (detect_add),
        .ld_state       (ld_state),
        .laf_state      (laf_state),
        .full_state     (full_state),
        .lfd_state      (lfd_state),
        .data_in        (data_in),
        .parity_done    (parity_done),
        .low_pkt_valid  (low_pkt_valid),
        .error            (error),
        .dout           (dout)
    );

    // Instantiate the FSM Module
    router_fsm fsm (
        .clock          (clock),
        .resetn         (resetn),
        .pkt_valid      (pkt_valid),
        .parity_done    (parity_done),
        .soft_reset_0   (soft_reset_0),
        .soft_reset_1   (soft_reset_1),
        .soft_reset_2   (soft_reset_2),
        .fifo_full      (fifo_full),
        .low_pkt_valid  (low_pkt_valid),
        .fifo_empty_0   (fifo_empty_0),
        .fifo_empty_1   (fifo_empty_1),
        .fifo_empty_2   (fifo_empty_2),
        .data_in        (data_in[1:0]),
        .busy           (busy),
        .detect_add     (detect_add),
        .ld_state       (ld_state),
        .laf_state      (laf_state),
        .full_state     (full_state),
        .write_enb_reg  (write_enb_reg),
        .rst_int_reg    (rst_int_reg),
        .lfd_state      (lfd_state)
    );

    // Instantiate the Synchronizer Module
    router_sync synchronizer (
        .detect_add     (detect_add),
        .write_enb_reg  (write_enb_reg),
        .clk         (clock),
        .rst         (resetn),
        .read_enb_0     (read_enb_0),
        .read_enb_1     (read_enb_1),
        .read_enb_2     (read_enb_2),
        .empty_0        (fifo_empty_0),
        .empty_1        (fifo_empty_1),
        .empty_2        (fifo_empty_2),
        .full_0         (full_0),
        .full_1         (full_1),
        .full_2         (full_2),
        .data_in        (data_in[1:0]),
        .vld_out_0      (valid_out_0),
        .vld_out_1      (valid_out_1),
        .vld_out_2      (valid_out_2),
        .soft_reset_0   (soft_reset_0),
        .soft_reset_1   (soft_reset_1),
        .soft_reset_2   (soft_reset_2),
        .fifo_full      (fifo_full),
        .write_enb      (write_enb)
    );

    // Instantiate the FIFO to the destination 0
    fifo_router fifo_0 (
        .clock          (clock),
        .resetn         (resetn),
        .write_enb      (write_enb[0]),
        .soft_reset     (soft_reset_0),
        .read_enb       (read_enb_0),
        .lfd_state      (lfd_state),
        .data_in        (dout),
        .full           (full_0),
        .empty          (fifo_empty_0),
        .data_out       (data_out_0)
    );

    // Instantiate the FIFO to the destination 1
    fifo_router fifo_1 (
        .clock          (clock),
        .resetn         (resetn),
        .write_enb      (write_enb[1]),
        .soft_reset     (soft_reset_1),
        .read_enb       (read_enb_1),
        .lfd_state      (lfd_state),
        .data_in        (dout),
        .full           (full_1),
        .empty          (fifo_empty_1),
        .data_out       (data_out_1)
    );

    // Instantiate the FIFO to the destination 2
    fifo_router fifo_2 (
        .clock          (clock),
        .resetn         (resetn),
        .write_enb      (write_enb[2]),
        .soft_reset     (soft_reset_2),
        .read_enb       (read_enb_2),
        .lfd_state      (lfd_state),
        .data_in        (dout),
        .full           (full_2),
        .empty          (fifo_empty_2),
        .data_out       (data_out_2)
    );

endmodule


/*module router_top(clk,rst,read_enb,din,pkt_valid,busy,error,valid_out,dout_0,dout_1,dout_2);

input clk,rst,pkt_valid;
input [2:0]read_enb;
input [7:0]din;
output [7:0]dout_0,dout_1,dout_2;
output busy;
output [2:0]valid_out;
output error;

//internal registers
//wire parity_done,fifo_full,low_packet_valid,detect_address,ld,laf,full_state,we_reg,rst_int_reg,lfd;
//wire [1:0]addr;
wire [2:0]soft_reset,write_enb;//synchronizer
wire [2:0]empty_fifo;
wire [2:0]full;//synchronizer
wire [7:0]reg_out;


//router_fsm instantiation
router_fsm rf1(clk,rst,pkt_valid,busy,parity_done,din[1:0],soft_reset,fifo_full,low_pkt_valid,empty_fifo,detect_addr,
ld_state,laf_state,full_state,we_reg,rst_int_reg,lfd_state);

//router_synchonizer instantiation
router_sync rs1(detect_addr,din[1:0],we_reg,clk,rst,valid_out,read_enb,full,soft_reset,empty_fifo,fifo_full,write_enb);

//router_register instantiation
router_register rr1(clk,rst,pkt_valid,din,fifo_full,rst_int_reg,detect_addr,ld_state,laf_state,full_state,
lfd_state,parity_done,low_pkt_valid,error,reg_out);

//router_fifo instantiation
router_fifo  rfifo_0(clk,rst,soft_reset[0],reg_out,write_enb[0],read_enb[0],lfd_state,full[0],empty_fifo[0],dout_0);

router_fifo  rfifo_1(clk,rst,soft_reset[1],reg_out,write_enb[1],read_enb[1],lfd_state,full[1],empty_fifo[1],dout_1);

router_fifo  rfifo_2(clk,rst,soft_reset[2],reg_out,write_enb[2],read_enb[2],lfd_state,full[2],empty_fifo[2],dout_2);

endmodule */


/*module router_top (input clk,rst,read_enb_0,read_enb_1,read_enb_2,pkt_valid,
				input [7:0]data_in,
				output valid_out_0,valid_out_1,valid_out_2,error,busy,
				output [7:0]data_out_0,[7:0]data_out_1,[7:0]data_out_2);

	wire [2:0] write_enb;
	wire [7:0] dout;
	
fifo_router  FIFo_0(.clk(clk),
					.wr(write_enb[0]),
					.rd(read_enb_0),
					.data_in(dout),
					.data_out(data_out_0),
					.empty (empty_0),
					.full (full_0),
					.rst(rst),
					.sft_rst(soft_reset_0),
					.lfd_state(lfd_state));
					
	
fifo_router  FIFo_1(.clk(clk),
					.wr(write_enb[1]),
					.rd(read_enb_1),
					.data_in(dout),
					.data_out(data_out_1),
					.empty (empty_1),
					.full (full_1),
					.rst(rst),
					.sft_rst(soft_reset_1),
					.lfd_state(lfd_state));	
					
fifo_router  FIFo_2(.clk(clk),
					.wr(write_enb[2]),
					.rd(read_enb_2),
					.data_in(dout),
					.data_out(data_out_2),
					.empty (empty_2),
					.full (full_2),
					.rst(rst),
					.sft_rst(soft_reset_2),
					.lfd_state(lfd_state));	

router_fsm  FSM(.clk (clk), .busy(busy),.fifo_empty_0(empty_0),.fifo_empty_1(empty_1),.fifo_empty_2(empty_2),
				.fifo_full(fifo_full),.pkt_valid(pkt_valid),.data_in(data_in[1:0]),
				.parity_done(parity_done),
				.low_packet_valid(low_packet_valid),
				.detect_add(detect_add),
				.write_enb_reg(write_enb_reg),
				.resetn(resetn),
				.ld_state(ld_state),
				.laf_state(laf_state),
				.lfd_state(lfd_state),
				.full_state(full_state),
				.reset_int_reg(reset_int_reg),
				.soft_reset_0(soft_reset_0),
				.soft_reset_1(soft_reset_1),
				.soft_reset_2(soft_reset_2));

router_sync  SYNCHRONIZER(.clk(clk),
							.rst(rst),
							.detect_add(detect_add),
							.empty_0(empty_0),
							.empty_1(empty_1),
							.empty_2(empty_2),
							.full_0(full_0),
							.full_1(full_1),
							.full_2(full_2),
							.write_enb_reg(write_enb_reg),
							.write_enb(write_enb),
							.fifo_full(fifo_full),
							.vld_out_0(valid_out_0),
							.valid_out_1(valid_out_1),
							.valid_out_2(valid_out_2),
							.soft_reset_0(soft_reset_0),
							.soft_reset_1(soft_reset_1),
							.soft_reset_2(soft_reset_2),
							.read_0(read_enb_0),
							.read_1(read_enb_1),
							.read_2(read_enb_2));


reg_router ROUTER_REGISTER(.clk(clk),
.rst(rst),
.pkt_valid(pkt_valid),
.data_in(data_in),
.fifo_full(fifo_full),
.detect_add(detect_add),
.lfd_state(lfd_state),
.full_state(full_state),
.rst_int_reg(reset_int_reg),
.parity_done (parity_done),
.low_packet_valid(low_packet_valid),
.dout(dout),
.err(err));

endmodule	*/			
					