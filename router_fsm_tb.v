
module router_fsm_tb ();
    reg           clock;
    reg           resetn;
    reg           pkt_valid;
    reg           parity_done;
    reg           soft_reset_0;
    reg           soft_reset_1;
    reg           soft_reset_2;
    reg           fifo_full;
    reg           low_pkt_valid;
    reg           fifo_empty_0;
    reg           fifo_empty_1;
    reg           fifo_empty_2;
    reg [1:0]     data_in;
    wire          busy;
    wire          detect_add;
    wire          ld_state;
    wire          laf_state;
    wire          full_state;
    wire          write_enb_reg;
    wire          rst_int_reg;
    wire          lfd_state;

    router_fsm DUT (
        .clock(clock),
        .resetn(resetn),
        .pkt_valid(pkt_valid),
        .parity_done(parity_done),
        .soft_reset_0(soft_reset_0),
        .soft_reset_1(soft_reset_1),
        .soft_reset_2(soft_reset_2),
        .fifo_full(fifo_full),
        .low_pkt_valid(low_pkt_valid),
        .fifo_empty_0(fifo_empty_0),
        .fifo_empty_1(fifo_empty_1),
        .fifo_empty_2(fifo_empty_2),
        .data_in(data_in),
        .busy(busy),
        .detect_add(detect_add),
        .ld_state(ld_state),
        .laf_state(laf_state),
        .full_state(full_state),
        .write_enb_reg(write_enb_reg),
        .rst_int_reg(rst_int_reg),
        .lfd_state(lfd_state)
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
        soft_reset_0 = 0;
        soft_reset_1 = 0;
        soft_reset_2 = 0;
        fifo_empty_0 = 0;
        fifo_empty_1 = 0;
        fifo_empty_2 = 0;
        @ (negedge clock);
        resetn = 1;
    end
    endtask

    task task1(); begin
        @ (negedge clock);
        pkt_valid       =   1'b1;
        data_in         =   2'b01;
        fifo_empty_1    =   1'b1;
        @ (negedge clock);
        @ (negedge clock);
        fifo_full       =   1'b0;
        pkt_valid       =   1'b0;
        @ (negedge clock);
        @ (negedge clock);
        fifo_full       =   1'b0;
    end
    endtask

    task task2(); begin
        @ (negedge clock);
        pkt_valid       =   1'b1;
        data_in         =   2'b10;
        fifo_empty_2    =   1'b1;
        @ (negedge clock);
        @ (negedge clock);
        fifo_full       =   1'b1;
        @ (negedge clock);
        fifo_full       =   1'b0;
        @ (negedge clock);
        parity_done     =   1'b0;
        low_pkt_valid   =   1'b1;
        @ (negedge clock);
        @ (negedge clock);
        fifo_full       =   1'b0;
    end
    endtask

    task task3(); begin
        @ (negedge clock);
        pkt_valid       =   1'b1;
        data_in         =   2'b10;
        fifo_empty_2    =   1'b1;
        @ (negedge clock);
        @ (negedge clock);
        fifo_full       =   1'b1;
        @ (negedge clock);
        fifo_full       =   1'b0;
        @ (negedge clock);
        parity_done     =   1'b0;
        low_pkt_valid   =   1'b0;
        @ (negedge clock);
        fifo_full       =   1'b0;
        pkt_valid       =   1'b0;
        @ (negedge clock);
        @ (negedge clock);
        fifo_full       =   1'b0;
    end
    endtask

    task task4(); begin
        @ (negedge clock);
        pkt_valid       =   1'b1;
        data_in         =   2'b01;
        fifo_empty_1    =   1'b1;
        @ (negedge clock);
        @ (negedge clock);
        fifo_full       =   1'b0;
        pkt_valid       =   1'b0;
        @ (negedge clock);
        @ (negedge clock);
        fifo_full       =   1'b1;
        @ (negedge clock);
        fifo_full       =   1'b0;
        @ (negedge clock);
        parity_done     =   1'b1;
    end
    endtask

    task task5(); begin
        @ (negedge clock);
        pkt_valid       =   1'b1;
        data_in         =   2'b01;
        fifo_empty_1    =   1'b0;
        @ (negedge clock);
        fifo_empty_1    =   1'b1;
        @ (negedge clock);
        @ (negedge clock);
        fifo_full       =   1'b0;
        pkt_valid       =   1'b0;
        @ (negedge clock);
        @ (negedge clock);
        fifo_full       =   1'b0;
    end
    endtask

    initial begin
        reset();
        task1;
        task2;
        task3;
        task4;
        task5;
        $finish;
    end

endmodule



/*module router_fsm_tb();
reg clk,resetn,pktvld,paritydone,fifofull,softreset0,softreset1,softreset2,lowpktvld,fifoempty0,fifoempty1,fifoempty2;
reg [1:0]data_in;
wire ld,lfd,laf,fullstate,detectadd,rstintreg,wren;
wire busy;

router_fsm f(clk,resetn,pktvld,paritydone,fifofull,softreset0,softreset1,softreset2,lowpktvld,
fifoempty0,fifoempty1,fifoempty2,data_in,ld,lfd,laf,fullstate,detectadd,rstintreg,wren,busy);


initial
clk=1'b1;
always #5 clk=~clk;



task initialize();
begin

{clk,resetn,pktvld,paritydone,fifofull,softreset0,softreset1,softreset2,lowpktvld,fifoempty0,fifoempty1,fifoempty2}=0;
data_in=0;
end
endtask


task rst();
begin
@(negedge clk)
resetn=1'b1;
@(negedge clk)
resetn=1'b0;
end
endtask


task inputt(input i,j,k,l);
begin

pktvld=i;
fifofull=j;
paritydone=k;
lowpktvld=l;
end
endtask


task empty(input a,b,c);
begin

fifoempty0=a;
fifoempty1=b;
fifoempty2=c;
end
endtask


task  sftrst(input d,e,f);
begin

softreset0=d;
softreset1=e;
softreset2=f;
end
endtask


task data(input [1:0]dt);
begin
data_in=dt;
end
endtask

initial
begin
initialize();
rst();
@(negedge clk)
sftrst(1,1,1);
@(negedge clk)
sftrst(0,0,0);


data(2'b00);
inputt(1,0,0,0);
empty(0,0,0);
repeat(2)
@(negedge clk)
empty(1,0,0);
repeat(16)
@(negedge clk)
inputt(1,1,0,0);
@(negedge clk)
inputt(1,0,0,0);
@(negedge clk)
inputt(0,0,0,1);
@(negedge clk)
inputt(0,0,1,0);
 

/*@(negedge clk);
begin
pktvld=1;
data_in=2'b00;
fifoempty0=1;
end

@(negedge clk);
@(negedge clk);
@(negedge clk);
begin
fifofull=0;
pktvld=0;
end
@(negedge clk);
@(negedge clk);
fifofull=0;

#1000 $finish;
end

endmodule */