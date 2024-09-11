
module router_reg(
    clk, rst, pkt_valid, data_in, fifo_full, rst_int_reg, detect_add, ld_state, 
    laf_state, full_state, lfd_state, parity_done, low_pkt_valid, error, dout
);
    input [7:0] data_in;
    input clk, rst, pkt_valid, fifo_full, rst_int_reg, detect_add, ld_state, laf_state, full_state, lfd_state;
    output reg parity_done, low_pkt_valid, error;
    output reg [7:0] dout;

    reg [7:0] header_byte, fifo_full_state_byte, internal_parity, packet_parity_byte;

    // Register header and FIFO full state byte
    always @(posedge clk) begin
        if (!rst) begin
            header_byte <= 0;
            fifo_full_state_byte <= 0;
        end else if (detect_add && pkt_valid && data_in[1:0] != 2'b11) begin
            header_byte <= data_in;
        end else if (ld_state && fifo_full) begin
            fifo_full_state_byte <= data_in;
        end
    end

    // DOUT logic
    always @(posedge clk) begin
        if (!rst) begin
            dout <= 0;
        end else if (lfd_state) begin
            dout <= header_byte;
        end else if (ld_state && !fifo_full) begin
            dout <= data_in; // Payload data driven out
        end else if (laf_state) begin
            dout <= fifo_full_state_byte;
        end else begin
            dout <= dout;
        end
    end

    // Calculate internal parity and packet parity register
    always @(posedge clk) begin
        if (!rst) begin
            packet_parity_byte <= 0;
            parity_done <= 0;
        end else if (detect_add) begin
            packet_parity_byte <= 0;
            parity_done <= 0;
        end else if (rst_int_reg) begin
            packet_parity_byte <= 0;
            parity_done <= 0;
        end else if ((ld_state && !fifo_full && !pkt_valid) || (laf_state && !parity_done && low_pkt_valid)) begin
            packet_parity_byte <= data_in;
            parity_done <= 1;
        end
    end

    // Low packet valid logic
    always @(posedge clk) begin
        if (!rst) begin
            low_pkt_valid <= 0;
        end else if (ld_state && !pkt_valid) begin
            low_pkt_valid <= 1;
        end
    end

    // Internal parity calculation
    always @(posedge clk) begin
        if (!rst) begin
            internal_parity <= 0;
        end else if (detect_add) begin
            internal_parity <= 0;
        end else if (rst_int_reg) begin
            internal_parity <= 0;  // Reset internal parity
        end else if (lfd_state) begin
            internal_parity <= internal_parity ^ header_byte;  // XOR with header byte
        end else if (ld_state && !fifo_full && pkt_valid) begin
            internal_parity <= internal_parity ^ data_in;  // XOR with incoming data
        end else begin
            internal_parity <= internal_parity;  // Remain the same
        end
    end

    // Error detection logic
    always @(posedge clk) begin
        if (!rst) begin
            error <= 0;
        end else if (!parity_done) begin
            error <= 0;
        end else if (internal_parity != packet_parity_byte) begin
            error <= 1;
        end else begin
            error <= 0;
        end
    end

endmodule


/*module router_reg(clk,rst,pkt_valid,data_in,fifo_full,rst_int_reg,detect_add,ld_state,laf_state,full_state,lfd_state,parity_done,low_pkt_valid,err,dout);
input [7:0] data_in;
input clk,rst,pkt_valid,fifo_full,rst_int_reg,detect_add,ld_state,laf_state,full_state,lfd_state;
output parity_done,low_pkt_valid,err;
output reg[7:0] dout;

reg [7:0] header_byte,fifo_full_state_byte,
       internal_parity,packet_parity_byte;
 
 //register header and fifo full state byte
 
 always@(posedge clk)
 begin
 if(!rst)
 begin
 header_byte <= 0;
 fifo_full_state_byte <= 0;
 end
 else if(detect_add && pkt_valid && data_in[1:0] != 2'b11)
 begin
 header_byte <= data_in;
 end
 else if(ld_state && fifo_full)
 begin
 fifo_full_state_byte <= data_in;
 end
 end
 
 //dout logic
 
 always@(posedge clk)
 begin
 if(!rst)
 dout <= 0;
 
 else if(lfd_state)
 dout<=header_byte;
 
 else if(ld_state && !fifo_full)
 dout <= data_in; // here payload data will be driven out
 
 else if (laf_state)
 dout <= fifo_full_state_byte;
 
 else
 dout <= dout;
 end
 
 
 // How to calculatee the internal parity or  how to write the logic to receive the packet parity register
 
 always@(posedge clk)
 begin
 if(!rst)
 begin
 packet_parity_byte <= 0;
 parity_done <= 0;
 end
 else if (detect_add)
 begin
 packet_parity_byte <= 0;
 parity_done <= 0;
 end
 else if (rst_int_reg)
 begin
 packet_parity_byte <= 0;
 parity_done <= 0;
 end
 else if ((ld_state && !fifo_full && !pkt_valid )||
			(laf_state && !parity_done && low_pkt_valid))
			 begin
			 packet_parity_byte <= data_in;
			 parity_done <= 1;
			 end
end			 
			 
	//Low packet valid

always@(posedge clk)
begin
if(!rst)
low_pkt_valid <= 0;
else if (ld_state && !pkt_valid)
low_pkt_valid <= 1;
end

//internal_parity   
//starting internal_parity = 0;
//internal_parity = header_byte ^internal_parity;
//internal_parity = payload ^internal_parity

//like header^o -> internal_parity
//internal_parity^p1^p2.....
always@(posedge clk)
begin
if(!rst)
internal_parity <= 0;

else if (detect_add)
internal_parity <= 0;

else if (rst_int_reg)
internal_parity <= 0;   //we do need retain the internal_parity when every we are going from the checkparityerror means like last state to again new  data item obviously not required

//where it will store the first packet  it is in load first data so ,actually here we are already store the data of header in headerbyte first register.
else if(lfd_state)//next statement header byte having the header reg we just take it for caluclation by xor 
internal_parity <= internal_parity^header_byte;
else if (ld_state && !fifo_full && pkt_valid) // packets are still coming fifo is not full these is the condition where we recieve the payloads

internal_parity <= internal_parity^data_in;

else

internal_parity <= internal_parity; //remians same
end

//error  when both internal_parity and packet_parity_byteparity both are mismacthed then error will comes //

always@(posedge clk)
begin
if(!rst)
err<=0;
//once packt parity recives then only perform next it means it should be high if not goes then error zero.
else if(!parity_done) 
err <= 0;

else if(internal_parity != packet_parity_byte)

err <= 1;
else
err <= 0;
end
 	
	endmodule */