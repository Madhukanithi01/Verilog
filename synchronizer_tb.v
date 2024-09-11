

module router_sync_tb();

reg clk,rst,detect_add,write_enb_reg,read_enb_0,read_enb_1,read_enb_2,empty_0,empty_1,empty_2,full_0,full_1,full_2;
reg [1:0]data_in;
wire vld_out_0,vld_out_1,vld_out_2;


wire soft_reset_0;
wire soft_reset_1;
wire soft_reset_2;
wire fifo_full;
wire [2:0] write_enb;

router_sync dut(.clk(clk),
        .rst(rst),
		.detect_add(detect_add),
        .write_enb_reg(write_enb_reg),
        
        .read_enb_0(read_enb_0),
        .read_enb_1(read_enb_1),
        .read_enb_2(read_enb_2),
        .empty_0(empty_0),
        .empty_1(empty_1),
        .empty_2(empty_2),
        .full_0(full_0),
        .full_1(full_1),
        .full_2(full_2),
        .data_in(data_in),
        .vld_out_0(vld_out_0),
        .vld_out_1(vld_out_1),
        .vld_out_2(vld_out_2),
        .soft_reset_0(soft_reset_0),
        .soft_reset_1(soft_reset_1),
        .soft_reset_2(soft_reset_2),
        .fifo_full(fifo_full),
        .write_enb(write_enb)
    );
//clk,rst,detect_add,write_enb_reg,read_enb_0,read_enb_1,read_enb_2,empty_0,empty_1,empty_2,full_0,full_1,full_2,
 //               data_in,vld_out_0,vld_out_1,vld_out_2,write_enb, fifo_full, soft_reset_0,soft_reset_1,soft_reset_2);
				
//clock generation 

initial
  begin
   clk=1'b0;
   forever #10 clk=~clk;
  end
  
  //reset generation
  
  task reset();
  begin
  @(negedge clk)
  rst = 1'b1;
  @(negedge clk)
  rst = 1'b0;
  end
  endtask
  
  //inputs generation
  task inputs(input [1:0]a);
  begin
  @(negedge clk)
  data_in = a;
  end
  endtask
  
  //task for full

  task full(input f0,
            input f1,
         input f2);
   begin
    full_0=f0;
    full_1=f1;
    full_2=f2;
  end
endtask

//task for empty

  task empty_e(input e0,
               input e1,
           input e2);
   begin
    empty_0=e0;
    empty_1=e1;
    empty_2=e2;
   end
  endtask
  
  //task for read

  task read(input r0,
            input r1,
         input r2);
   begin
    read_enb_0=r0;
    read_enb_1=r1;
    read_enb_2=r2;
   end
  endtask
  
  //task for detection of address

  task detect(input d0);
   begin
    @(negedge clk)
    detect_add=d0;
   end
  endtask
  
  
  //task for write enable register

  task write_e(input d1);
   begin
    @(negedge clk)
    write_enb_reg=d1;
   end
  endtask
  
   //always@(negedge clk)
       initial
   begin
    reset;
          detect(1);
    inputs(2'b01);
    //detect(1);
    write_e(1);
    full(0,1,0);
    empty_e(0,0,1);
    read(0,0,0);
    repeat(30)
    #100
    
    reset;
    inputs(2'b00);
    detect(1);
    write_e(1);
    full(1,0,0);
    empty_e(0,1,1);
    read(0,0,0);
           repeat(30)
    #100;
    reset;
    inputs(2'b10);
    detect(1);
    write_e(1);
    full(0,0,1);
    empty_e(1,1,0);
    read(0,0,0);
           repeat(30)
      #50;
     //read(0,1,1);
   
    #1000 $finish;
   end
endmodule
