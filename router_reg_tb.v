
module router_reg_tb ();
    reg           clock;
    reg           resetn;
    reg           pkt_valid;
    reg           fifo_full;
    reg           rst_int_reg;
    reg           detect_add;
    reg           ld_state;
    reg           laf_state;
    reg           full_state;
    reg           lfd_state;
    reg[7:0]      data_in;
    wire          parity_done;
    wire          low_pkt_valid;
    wire          err;
    wire[7:0]     dout;
    
    integer i;

    router_reg DUT (
        .clk(clock),
        .rst(resetn),
        .pkt_valid(pkt_valid),
        .fifo_full(fifo_full),
        .rst_int_reg(rst_int_reg),
        .detect_add(detect_add),
        .ld_state(ld_state),
        .laf_state(laf_state),
        .full_state(full_state),
        .lfd_state(lfd_state),
        .data_in(data_in),
        .parity_done(parity_done),
        .low_pkt_valid(low_pkt_valid),
        .error(err),
        .dout(dout)
    ); 

    always  begin
        #5
        clock  = 0;
        #5
        clock  = 1;
    end

    task reset(); begin
        @ (negedge clock);
        resetn = 0;
        rst_int_reg=0;
        @ (negedge clock);
        resetn = 1;
    end
    endtask

    task gen_packet(input[5:0]k,input[1:0]l); begin: t1
        reg[7:0] header, payload, parity;
        reg[5:0] payld_len;
        reg[1:0] dest_addr;

        @(negedge clock);
        payld_len       =   k;
        dest_addr       =   l;
        parity          =   8'b0;
        detect_add      =   1'b1;
        pkt_valid       =   1'b1;
        lfd_state       =   1;
        header          =   {payld_len, dest_addr};
        data_in         =   header;
        parity          =   parity  ^   data_in;
        
        @(negedge clock);
        detect_add      =   1'b0;

        for (i = 0; i < payld_len; i = i + 1) begin
            @(negedge clock);
            lfd_state   =   0;
            ld_state    =   1;

            payload     =   {$random}%256;
            data_in     =   payload;
            parity      =   parity  ^   data_in;
            
        end
        @(negedge clock);
        pkt_valid       =   1'b0;
        data_in         =   parity;

        @(negedge clock);
        ld_state        =   1'b0;
    end  
    endtask

    task gen_pack_err(input[5:0]k,input[1:0]l); begin:t2
        reg[7:0] header, payload, parity;
        reg[5:0] payld_len;
        reg[1:0] dest_addr;
        @(negedge clock);
        payld_len       =   k;
        dest_addr       =   l;
        parity          =   8'b0;
        detect_add      =   1'b1;
        pkt_valid       =   1'b1;
        lfd_state       =   1;
        header          =   {payld_len, dest_addr};
        data_in         =   header;
        parity          =   parity  ^   data_in;

        @(negedge clock);
        detect_add      =   1'b0;

        for (i = 0; i < payld_len; i = i + 1) begin
            @(negedge clock);
            lfd_state   =   0;
            ld_state    =   1;

            payload     =   {$random}%256;
            data_in     =   payload;
            parity      =   parity  ^   data_in;
        end
        @(negedge clock);
        pkt_valid       =   1'b0;
        data_in         =   parity  +   5; // adding a number with parity so that to make a 
                                          // mismatch between internal parity and packet parity.
        @(negedge clock);
        ld_state        =   1'b0;
    end  
    endtask

    initial begin
        reset();
        fifo_full   =   1'b0;
        laf_state   =   1'b0;
        full_state  =   1'b0;
        @(negedge clock);
        @(negedge clock);
        gen_packet(6'h8, 2'h0);
        gen_pack_err(6'h5, 2'h2);
        @(negedge clock);
        $finish;
    end

endmodule



/*module router_reg_tb();
reg clock, resetn, pkt_valid, fifo_full, detect_add, ld_state, lfd_state,
laf_state, full_state, rst_int_reg;
reg [7:0] data_in;
wire err, parity_done, low_packet_valid;
wire [7:0] data_out;

router_reg DUT5(clock, resetn, pkt_valid, fifo_full, detect_add, ld_state,
lfd_state, laf_state, full_state, rst_int_reg, data_in, err, parity_done,
low_packet_valid, data_out);

task initialize();
begin
clock = 1'b0;
resetn = 1'b0;
end
endtask


always #10 clock = ~clock;


task rst_dut();
begin
@(negedge clock);
resetn = 1'b0;
@(negedge clock)
resetn = 1'b1;
end
endtask


task delay();
begin
#50;
end
endtask



task good_packet();
reg [7:0] payload_data, header;
reg [7:0] parity;
reg [5:0] payload_len;
reg [1:0] addr;
integer k;
begin
parity = 8'b0;
@(negedge clock)
payload_len = 6'd14;
addr = 2'b01;
header = {payload_len, addr};
data_in = header;
pkt_valid = 1'b1;
detect_add = 1'b1;
fifo_full = 1'b0;
@(negedge clock)
detect_add = 1'b0;
lfd_state = 1'b1;
parity = parity ^ header;
for(k = 0; k<payload_len; k = k+1)
begin
@(negedge clock);
lfd_state = 1'b0;
ld_state = 1'b1;
payload_data = {$random}%256;
data_in = payload_data;
parity = parity ^ data_in;
end
@(negedge clock)
pkt_valid = 1'b0;
data_in = parity;
@(negedge clock) ld_state = 1'b0;
rst_int_reg = 1'b1;
@(negedge clock) rst_int_reg = 1'b0;
end
endtask



task bad_packet();
reg [7:0] payload_data, header;
reg [7:0] parity;
reg [5:0] payload_len;
reg [1:0] addr;
integer k;
begin
parity = 8'b0;
@(negedge clock)
payload_len = 6'd14;
addr = 2'b01;
header = {payload_len, addr};
data_in = header;
pkt_valid = 1'b1;
detect_add = 1'b1;
fifo_full = 1'b0;
@(negedge clock)
detect_add = 1'b0;
lfd_state = 1'b1;
// parity = parity ^ header;
for(k = 0; k<payload_len; k = k+1)
begin
@(negedge clock);
lfd_state = 1'b0;
ld_state = 1'b1;
payload_data = {$random}%256;
data_in = payload_data;
//parity = parity ^ data_in;
end
@(negedge clock)
pkt_valid = 1'b0;
parity = {$random}%256;
data_in = parity;
@(negedge clock) ld_state = 1'b0;
@(negedge clock) rst_int_reg = 1'b1;
@(negedge clock) rst_int_reg = 1'b0;
end
endtask



initial
begin

initialize;
rst_dut;
full_state = 1'b0;
good_packet;
delay;
bad_packet;
delay;
end
endmodule */