
module router_sync(input [1:0]data_in,input detect_add,write_enb_reg,clk,rst,read_enb_0,read_enb_1,read_enb_2,
empty_1,empty_0,empty_2,full_0,full_1,full_2, 
			output reg[2:0] write_enb,
			output reg fifo_full,
			output vld_out_0,vld_out_1,vld_out_2,
			output reg soft_reset_0,soft_reset_1,soft_reset_2);
reg[1:0] fifo_address;      // 2bit intermediate reg to capture the destination address
reg [4:0] count_fifo_0_sft_rst,
			count_fifo_1_sft_rst,
			count_fifo_2_sft_rst;


// capture the data

always@(posedge clk)
begin
if(!rst)
fifo_address <= 2'd0;

else if(detect_add)
fifo_address<=data_in;
end

//Implementing the write anable logic 

always@(posedge clk)
begin
if(write_enb_reg)
begin
case(fifo_address)
	 2'b00: write_enb=3'b001;
         2'b01: write_enb=3'b010;
         2'b10: write_enb=3'b100;
         default: write_enb=3'b000;
	endcase
	end
	
else
	write_enb = 3'b000;
	end
	
	//FIFO full state
	
	always@(*)
begin
case(fifo_address)
	2'b00:fifo_full = full_0;
	2'b01:fifo_full = full_1;
	2'b10:fifo_full = full_2;
	default:fifo_full = 0;
	endcase
	end
//valid_out one bit of data is available which is ready for read the data if it is not empty based on the  we can say it is ready for the vld_out signal 
 assign vld_out_0 = !empty_0;
 assign vld_out_1 = !empty_1;
 assign vld_out_2 = !empty_2;
//FIFO time out
//timeout logic will say that once the valid data available  then destination should respond over the 30 clk cycles if doesnt read then softrst high

always@(posedge clk)
begin
if(!rst)
begin
soft_reset_0 <= 0;
count_fifo_0_sft_rst<=0;
end

else if(!vld_out_0)
begin
soft_reset_0 <= 0;
count_fifo_0_sft_rst<=0;
end

else if(read_enb_0)
begin
soft_reset_0 <= 0;
count_fifo_0_sft_rst<=0;
end

else if (count_fifo_0_sft_rst <= 5'd29)
begin
soft_reset_0 <=0;
count_fifo_0_sft_rst <= count_fifo_0_sft_rst+1;
end 

else
begin
soft_reset_0 <= 1;
count_fifo_0_sft_rst <= 0;
end
end

	
//fifo 1

always@(posedge clk)
begin
if(!rst)
begin
soft_reset_1 <= 0;
count_fifo_1_sft_rst<=0;
end

else if(!vld_out_1)
begin
soft_reset_1 <= 0;
count_fifo_1_sft_rst<=0;
end

else if(read_enb_1)
begin
soft_reset_1 <= 0;
count_fifo_1_sft_rst<=0;
end

else if (count_fifo_1_sft_rst <= 5'd29)
begin
soft_reset_1 <=0;
count_fifo_1_sft_rst <= count_fifo_1_sft_rst+1;
end 

else
begin
soft_reset_1 <= 1;
count_fifo_1_sft_rst <= 0;
end
end
	
	//fifo2
	
	always@(posedge clk)
begin
if(!rst)
begin
soft_reset_2 <= 0;
count_fifo_2_sft_rst<=0;
end

else if(!vld_out_2)
begin
soft_reset_2 <= 0;
count_fifo_2_sft_rst<=0;
end

else if(read_enb_2)
begin
soft_reset_2 <= 0;
count_fifo_2_sft_rst<=0;
end

else if (count_fifo_2_sft_rst <= 5'd29)
begin
soft_reset_2 <=0;
count_fifo_2_sft_rst <= count_fifo_2_sft_rst+1;
end 

else
begin
soft_reset_2 <= 1;
count_fifo_2_sft_rst <= 0;
end
end

endmodule	
