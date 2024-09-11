module fifo_router_tb ();
    reg clock, resetn, write_enb, soft_reset, read_enb, lfd_state;
    reg [7:0] data_in;
    wire full, empty;
    wire [7:0] data_out;

    fifo_router dut (
        .clock(clock),
        .resetn(resetn),
        .write_enb(write_enb),
        .soft_reset(soft_reset),
        .read_enb(read_enb),
        .lfd_state(lfd_state),
        .data_in(data_in),
        .full(full),
        .empty(empty),
        .data_out(data_out)
    );

    parameter CYCLE = 10;
    integer k;

//----  CLOCK GENERATION   ----
    initial begin
        clock = 1'b0;
        forever #(CYCLE/2) clock = ~clock;
    end

//------ Reset enabling task -----
    task rst();begin
        @(negedge clock)
        resetn=1'b0;
        @(negedge clock)
        resetn=1'b1;
    end
    endtask

//------ Soft reset enabling task -----
    task soft_rst();begin
        @(negedge clock)
        soft_reset=1'b1;
        @(negedge clock)
        soft_reset=1'b0;
    end
    endtask

//-----  Writing Input to router ----
    task write;
        reg [7:0] payload_data, parity, header;
        reg [5:0] payload_len;
        reg [1:0] addr;
        begin
            @(negedge clock);
            lfd_state = 1'b1;
            @(negedge clock);
            payload_len = 6'd9;
            addr = 2'b01;
            header = {payload_len, addr};
            data_in = header;
            lfd_state = 1'b0;
            write_enb = 1'b1;
            for (k = 0; k < payload_len; k = k + 1) begin
                @(negedge clock);
                payload_data = {$random} % 256;
                data_in = payload_data;
            end
            @(negedge clock);
            parity = {$random} % 256;
            data_in = parity;
        end
    endtask

    initial begin
        rst();
        soft_rst();
        write;
        write;
        write_enb = 1'b0;
        data_in = 0;
        #CYCLE;
        @(negedge clock);
        read_enb = 1'b1;
        repeat(5)
            #CYCLE;
        write;
        write;
        write_enb = 1'b0;
        data_in = 0;
        wait(empty)
            read_enb = 1'b0;
        #CYCLE;
        $finish;
    end
endmodule




