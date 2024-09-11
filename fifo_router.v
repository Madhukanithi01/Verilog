module fifo_router (
    input           clock,
    input           resetn,
    input           write_enb,
    input           soft_reset,
    input           read_enb,
    input           lfd_state,
    input [7:0]     data_in,
    output          empty,
    output          full,
    output reg [7:0]data_out
);
    reg [8:0] mem [0:15];

    reg [4:0] wr_ptr, re_ptr;
    reg [7:0] fifo_counter;
    reg lfd_state_s;

    integer i;

    // First data state
    always @(posedge clock) begin
        if (!resetn) 
            lfd_state_s <= 1'b0;
        else
            lfd_state_s <= lfd_state;
    end

    // Pointer updation
    always @(posedge clock) begin
        if (!resetn) 
            {wr_ptr, re_ptr} <= 0;
        else if (soft_reset) 
            {wr_ptr, re_ptr} <= 0;
        else begin
            if (write_enb && !full)
                wr_ptr <= wr_ptr + 1; 
            else
                wr_ptr <= wr_ptr;
            
            if (read_enb && !empty) 
                re_ptr <= re_ptr + 1;
            else
                re_ptr <= re_ptr;
        end
    end

    // FIFO downcount logic
    always @(posedge clock) begin
        if (!resetn) begin
            fifo_counter <= 0;
        end
        else if (soft_reset) begin
            fifo_counter <= 0;
        end
        else if (read_enb && ! empty) begin
            if (mem[re_ptr[3:0]][8] == 1) begin
                fifo_counter <= mem [re_ptr[3:0]][7:2] + 1;
            end
            else if (fifo_counter != 0) begin
                fifo_counter <= fifo_counter - 1;
            end
        end
    end

    // Reading operation
    always @(posedge clock) begin
        if (!resetn) begin
            data_out <= 0;
        end
        else if (soft_reset) begin
            data_out <= 8'hz;
        end
        else if (fifo_counter == 0 && data_out != 0) begin
            data_out <= 8'hz;
        end
        else if (read_enb && !empty) begin
            data_out <= mem[re_ptr[3:0]];
        end
    end

    // Writing operation
    always @(posedge clock) begin
        if (!resetn) begin
            for (i = 0; i < 16; i = i + 1) begin
                mem[i] <= 0;
            end
        end
        else if (soft_reset) begin
            for (i = 0; i < 16; i = i + 1) begin
                mem[i] <= 0;
            end
        end
        else if (write_enb && !full) begin
            mem [wr_ptr[3:0]] <= {lfd_state_s, data_in};
        end
    end

    // Full and Empty conditions
    assign full = (wr_ptr == {~re_ptr[4], re_ptr[3:0]});
    assign empty = (wr_ptr == re_ptr);
    
endmodule



