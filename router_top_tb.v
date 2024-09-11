module router_top_tb ();
    reg           clock;
    reg           resetn;
    reg           read_enb_0;
    reg           read_enb_1;
    reg           read_enb_2;
    reg           pkt_valid;
    reg[7:0]      data_in;
    wire          valid_out_0;
    wire          valid_out_1;
    wire          valid_out_2;
    wire          error;
    wire          busy;
    wire[7:0]     data_out_0;
    wire[7:0]     data_out_1;
    wire[7:0]     data_out_2;
    integer       i;
    router_top DUT(
        .clock(clock),
        .resetn(resetn),
        .read_enb_0(read_enb_0),
        .read_enb_1(read_enb_1),
        .read_enb_2(read_enb_2),
        .pkt_valid(pkt_valid),
        .data_in(data_in),
        .valid_out_0(valid_out_0),
        .valid_out_1(valid_out_1),
        .valid_out_2(valid_out_2),
        .error(error),
        .busy(busy),
        .data_out_0(data_out_0),
        .data_out_1(data_out_1),
        .data_out_2(data_out_2)
    );

    always  begin
        #5
        clock  = 0;
        #5
        clock  = 1;
    end

    task reset(); begin
        @ (negedge clock);
        resetn          =   0;
        read_enb_0      =   0;
        read_enb_1      =   0;
        read_enb_2      =   0;
        pkt_valid       =   0;
        data_in         =   0;
        @ (negedge clock);
        resetn = 1;
    end
    endtask

    task gen_packet(input[5:0]k,input[1:0]l); begin: t1     //  gen_packet(payload length, Destination Address)
        reg[7:0] header, payload, parity;
        reg[5:0] payld_len;
        reg[1:0] dest_addr;

        wait(!busy)
        @(negedge clock);
        payld_len       =   k;
        dest_addr       =   l;
        parity          =   8'b0;
        pkt_valid       =   1'b1;
        header          =   {payld_len, dest_addr};
        data_in         =   header;
        parity          =   parity  ^   data_in;
        
        @(negedge clock);
        for (i = 0; i < payld_len; i = i + 1) begin
            wait(!busy)
            @(negedge clock);

            payload     =   {$random}%256;
            data_in     =   payload;
            parity      =   parity  ^   data_in;
            
        end
        wait(!busy)
        @(negedge clock);
        pkt_valid       =   1'b0;
        data_in         =   parity;
    end  
    endtask

    task gen_error(input[5:0]k,input[1:0]l); begin: t2     //  gen_error(payload length, Destination Address)
        reg[7:0] header, payload, parity;
        reg[5:0] payld_len;
        reg[1:0] dest_addr;

        wait(!busy)
        @(negedge clock);
        payld_len       =   k;
        dest_addr       =   l;
        parity          =   8'b0;
        pkt_valid       =   1'b1;
        header          =   {payld_len, dest_addr};
        data_in         =   header;
        parity          =   parity  ^   data_in;
        
        @(negedge clock);
        for (i = 0; i < payld_len; i = i + 1) begin
            wait(!busy)
            @(negedge clock);

            payload     =   {$random}%256;
            data_in     =   payload;
            parity      =   parity  ^   data_in;
            
        end
        wait(!busy)
        @(negedge clock);
        pkt_valid       =   1'b0;
        data_in         =   parity + 1;
    end  
    endtask
    
    initial begin
        reset();
        gen_packet(6'h23, 2'h1);
        read_enb_1      =   1;
        gen_packet(6'h4, 2'h2);
        gen_packet(6'h8, 2'h3);
        repeat(32)
            @(negedge clock);
        read_enb_2      =   1;
        $finish;
    end
    
    initial begin
        repeat(20)
            @(negedge clock);
        read_enb_0      =   1;
    end

endmodule

/*
module router_top_tb();

reg clk,rst,pkt_valid;
reg [2:0]read_enb;
reg [7:0]din;
wire [7:0]dout_0,dout_1,dout_2;
wire [2:0]valid_out;
wire busy;
wire error;

router_top rt_tb(clk,rst,read_enb,din,pkt_valid,busy,error,valid_out,dout_0,dout_1,dout_2);
 // clock generation
initial
clk=1'b0;
always
#10 clk=~clk;

// initialization 
task initialize();
begin{pkt_valid,din,read_enb} = 0;
end
endtask


// reset task
task value_reset();
begin
@(negedge clk)
rst=1'b0;
@(negedge clk)
rst=1'b1;
end
endtask

//good packet
task good_packet;
reg [7:0]payload_data,header,parity;
reg [5:0]payload_length;
reg [1:0]addr;

 integer i;
 begin
 @(negedge clk)
 wait(~busy)
 @(negedge clk)
 payload_length=6'd14;
 addr=2'd0; //valid packet
 header={payload_length,addr};
 din=header;
//@(negedge clk)
 parity=0;
 pkt_valid=1'b1;
 parity=parity^header; // whenever it generating the packet we  hvae to 
 
 @(negedge clk)
  wait(~busy)
  for(i=0; i < payload_length; i = i + 1)
  begin
  @(negedge clk)
  wait(~busy)
  payload_data={$random}%256;
  din=payload_data;
  //pkt_valid=1'b0;
  parity=parity^din;
  end

  @(negedge clk)
   wait(~busy)
   begin
   pkt_valid=1'b0;
   din=parity;
   end
end
endtask

initial
    begin
		initialize();
        value_reset();
        good_packet;
		//repeat(3)@(negedge clk)
        @(negedge clk)
        //@(negedge clk)
        @(negedge clk)
        read_enb=3'b001;
        @(negedge clk)
        wait(~valid_out[0])
        @(negedge clk)
        read_enb=3'b000;

        end

initial
#1000 $finish;
endmodule */