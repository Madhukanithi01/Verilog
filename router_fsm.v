
module router_fsm (
    input           clock,              
    input           resetn,
    input           pkt_valid,
    input           parity_done,
    input           soft_reset_0,
    input           soft_reset_1,
    input           soft_reset_2,
    input           fifo_full,
    input           low_pkt_valid,
    input           fifo_empty_0,
    input           fifo_empty_1,
    input           fifo_empty_2,
    input [1:0]     data_in,
    output          busy,
    output          detect_add,
    output          ld_state,
    output          laf_state,
    output          full_state,
    output          write_enb_reg,
    output          rst_int_reg,
    output          lfd_state);

    reg [2:0]       present_state, next_state;
    reg [1:0]       fsm_addr;

    parameter       DECODE_ADDRESS      =   3'b000;
    parameter       LOAD_FIRST_DATA     =   3'b001;
    parameter       LOAD_DATA           =   3'b010;
    parameter       FIFO_FULL_STATE     =   3'b011;
    parameter       LOAD_AFTER_FULL     =   3'b100;
    parameter       LOAD_PARITY         =   3'b101;
    parameter       CHECK_PARITY_ERROR  =   3'b110;
    parameter       WAIT_TILL_EMPTY     =   3'b111;
    
//----- Capture Destination Address -----
    always @(posedge clock) begin
        if (!resetn) begin
            fsm_addr <= 2'b00;
        end
        else if (detect_add) begin
            fsm_addr <= data_in;
        end
    end
    
//----- Present State Logic ----------
    always @(posedge clock) begin
        if (!resetn) begin
            present_state <= DECODE_ADDRESS;
        end
        else if ((soft_reset_0 && fsm_addr == 2'b00) ||
                 (soft_reset_1 && fsm_addr == 2'b01) ||
                 (soft_reset_2 && fsm_addr == 2'b10)  ) begin
            present_state <= DECODE_ADDRESS;
        end
        else
            present_state <= next_state;
    end

//------- Next State Logic ------------
    always @(*) begin
        case (present_state)
            DECODE_ADDRESS    : begin
                                    if ((pkt_valid && (data_in[1:0] == 0) && fifo_empty_0) ||
                                        (pkt_valid && (data_in[1:0] == 1) && fifo_empty_1) ||
                                        (pkt_valid && (data_in[1:0] == 2) && fifo_empty_2) ) begin
                                        next_state     <=   LOAD_FIRST_DATA;
                                    end
                                    else if ((pkt_valid && (data_in[1:0] == 0) && !fifo_empty_0) ||
                                        (pkt_valid && (data_in[1:0] == 1) && !fifo_empty_1) ||
                                        (pkt_valid && (data_in[1:0] == 2) && !fifo_empty_2) ) begin
                                        next_state     <=   WAIT_TILL_EMPTY;
                                    end
                                    else
                                        next_state     <=   DECODE_ADDRESS;
                                end 
                                
            LOAD_FIRST_DATA   : begin
                                    next_state         <=  LOAD_DATA;
                                end

            LOAD_DATA         : begin
                                    if (fifo_full) begin
                                        next_state     <=   FIFO_FULL_STATE;
                                    end
                                    else if (!fifo_full && !pkt_valid) begin
                                        next_state     <=   LOAD_PARITY;
                                    end
                                    else
                                        next_state     <=   LOAD_DATA;
                                end

            FIFO_FULL_STATE   : begin
                                    if (!fifo_full) begin
                                        next_state     <=   LOAD_AFTER_FULL;
                                    end
                                    else
                                        next_state     <=   FIFO_FULL_STATE;
                                end

            LOAD_AFTER_FULL   : begin
                                    if (parity_done) begin
                                        next_state     <=   DECODE_ADDRESS;
                                    end
                                    else if (!parity_done && low_pkt_valid) begin
                                        next_state     <=   LOAD_PARITY;
                                    end
                                    else if (!parity_done && !low_pkt_valid) begin
                                        next_state     <=   LOAD_DATA;
                                    end
                                    else
                                        next_state     <=   LOAD_AFTER_FULL;
                                end

            LOAD_PARITY       : begin
                                        next_state     <=   CHECK_PARITY_ERROR;
                                end 

            CHECK_PARITY_ERROR: begin
                                    if (!fifo_full) begin
                                        next_state     <=   DECODE_ADDRESS;
                                    end
                                    else
                                        next_state     <=   CHECK_PARITY_ERROR;
                                end 

            WAIT_TILL_EMPTY   : begin
                                    if ((fifo_empty_0 && (fsm_addr == 0)) ||
                                        (fifo_empty_1 && (fsm_addr == 1)) ||
                                        (fifo_empty_2 && (fsm_addr == 2)) ) begin
                                        next_state     <=   LOAD_FIRST_DATA;
                                    end
                                    else
                                        next_state     <=   WAIT_TILL_EMPTY;
                                end 
            
            default           :         next_state     <=   DECODE_ADDRESS;

        endcase
    end

//------- Output Logic ---------------

    assign  busy        =   ((present_state ==  LOAD_FIRST_DATA) ||
                             (present_state ==  LOAD_PARITY) ||
                             (present_state ==  FIFO_FULL_STATE) ||
                             (present_state ==  LOAD_AFTER_FULL) ||
                             (present_state ==  WAIT_TILL_EMPTY) ||
                             (present_state ==  CHECK_PARITY_ERROR))    ? 1 : 0;
    assign  detect_add  =   ((present_state ==  DECODE_ADDRESS))        ? 1 : 0;
    assign  lfd_state   =   ((present_state ==  LOAD_FIRST_DATA))       ? 1 : 0;
    assign  ld_state    =   ((present_state ==  LOAD_DATA))             ? 1 : 0;
    assign  write_enb_reg=  ((present_state ==  LOAD_DATA) ||
                             (present_state ==  LOAD_AFTER_FULL) ||
                             (present_state ==  LOAD_PARITY))           ? 1 : 0;
    assign  full_state  =   ((present_state ==  FIFO_FULL_STATE))       ? 1 : 0;
    assign  laf_state   =   ((present_state ==  LOAD_AFTER_FULL))       ? 1 : 0;
    assign  rst_int_reg =   ((present_state ==  CHECK_PARITY_ERROR))    ? 1 : 0;

endmodule

/*
module router_fsm(clock,resetn,pkt_valid,data_in,parity_done,soft_reset_0,soft_reset_1,soft_reset_2,fifo_full,low_pkt_valid,fifo_empty_0,fifo_empty_1,fifo_empty_2,detect_add,ld_state,laf_state,full_state,write_enb_reg,rst_int_reg,lfd_state,busy);

input clock,resetn,pkt_valid,parity_done,soft_reset_0,soft_reset_1,soft_reset_2,fifo_full,low_pkt_valid,fifo_empty_0,fifo_empty_1,fifo_empty_2;
input [1:0]data_in;
output detect_add,ld_state,laf_state,full_state,write_enb_reg,rst_int_reg,lfd_state,busy;

reg [2:0]state,next_state;
reg [1:0]int_addr;

//DEFINING PARAMETERS 

parameter DECODE_ADDRESS=3'b000,
      LOAD_FIRST_DATA=3'b001,
      LOAD_DATA=3'b010,
      FIFO_FULL_STATE=3'b011,
      LOAD_AFTER_FULL=3'b100,
      LOAD_PARITY=3'b101,
      CHECK_PARITY_ERROR=3'b110,
      WAIT_TILL_EMPTY=3'b111;


//present state sequential always block
always@(posedge clock)
begin
    if(!resetn)
        int_addr<=2'b11;
    else if (soft_reset_0==1&&int_addr==2'b00|soft_reset_1==1&&int_addr==2'b01|soft_reset_2==1&&int_addr==2'b10)
        int_addr<=2'b11;
    else
        begin
        if(detect_add==1)
         int_addr<=data_in;
        end
end

always@(posedge clock)
begin
    if(!resetn)
        state<=DECODE_ADDRESS;
    else if (soft_reset_0==1&&int_addr==2'b00|soft_reset_1==1&&int_addr==2'b01|soft_reset_2==1&&int_addr==2'b10)
        state<=DECODE_ADDRESS;
    else
        state<=next_state;
end

//next state combinational block

always@(*)
begin
if(int_addr!==2'b11)
    begin
    next_state=DECODE_ADDRESS;
    case(state)
      DECODE_ADDRESS:if((pkt_valid&(data_in==0)&fifo_empty_0)|(pkt_valid&(data_in==1)&fifo_empty_1)|(pkt_valid&(data_in==2)&fifo_empty_2))
                next_state=LOAD_FIRST_DATA;
             else if ((pkt_valid&(int_addr==0)&!fifo_empty_0)|(pkt_valid&(int_addr==1)&!fifo_empty_1)|(pkt_valid&(int_addr==2)&!fifo_empty_2))
                next_state=WAIT_TILL_EMPTY;
              else
                next_state=DECODE_ADDRESS;

      LOAD_FIRST_DATA: next_state=LOAD_DATA;

      LOAD_DATA:if(fifo_full)
            next_state=FIFO_FULL_STATE;
            else if (!fifo_full&&!pkt_valid)
            next_state=LOAD_PARITY;    
            else
            next_state=LOAD_DATA;    

      FIFO_FULL_STATE:if(!fifo_full)
                next_state=LOAD_AFTER_FULL;
              else
                next_state=FIFO_FULL_STATE;
    
      LOAD_AFTER_FULL:if(!parity_done&&!low_pkt_valid)
                next_state=LOAD_DATA;
               else if(!parity_done&&low_pkt_valid)
                next_state=LOAD_PARITY;
               else
                next_state=DECODE_ADDRESS;

      LOAD_PARITY:next_state=CHECK_PARITY_ERROR;

      CHECK_PARITY_ERROR:if(!fifo_full)
                next_state=DECODE_ADDRESS;
              else
                next_state=FIFO_FULL_STATE;
      WAIT_TILL_EMPTY:if(((int_addr==0)&&fifo_empty_0) &&((int_addr==1)&&fifo_empty_1)&&((int_addr==2)&&fifo_empty_2))
                next_state=LOAD_FIRST_DATA;
                   else
                next_state=WAIT_TILL_EMPTY;

        endcase
    end
else
    next_state=DECODE_ADDRESS;
end
//OUTPUT COMBINATIONAL BLOCK

assign detect_add=(state==DECODE_ADDRESS)?1'b1:1'b0;
assign ld_state=(state==LOAD_DATA)?1'b1:1'b0;
assign laf_state=(state==LOAD_AFTER_FULL)?1'b1:1'b0;
assign full_state=(state==FIFO_FULL_STATE)?1'b1:1'b0;
assign write_enb_reg=(state==LOAD_DATA||state==LOAD_AFTER_FULL||state==LOAD_PARITY)?1'b1:1'b0;
assign rst_int_reg=(state==CHECK_PARITY_ERROR)?1'b1:1'b0;
assign lfd_state=(state==LOAD_FIRST_DATA)?1'b1:1'b0;
assign busy=(state==LOAD_FIRST_DATA||state==LOAD_PARITY||state==LOAD_AFTER_FULL||state==CHECK_PARITY_ERROR||state==WAIT_TILL_EMPTY||state==FIFO_FULL_STATE)?1'b1:1'b0;

endmodule










/*module router_fsm(clk,rst,pkt_valid,busy,parity_done,data_in,soft_reset_0,soft_reset_1,soft_reset_2,fifo_full,low_pkt_valid,fifo_empty_0,fifo_empty_1,fifo_empty_2,detect_add,ld_state,laf_state,full_state,write_enb_reg,rst_int_reg,lfd_state);
input clk,rst,pkt_valid,parity_done,soft_reset_0,soft_reset_1,soft_reset_2;
input [1:0] data_in;
output busy;
input low_pkt_valid,fifo_empty_0,fifo_empty_1,fifo_empty_2;
output detect_add,ld_state,laf_state,full_state,write_enb_reg,rst_int_reg,lfd_state;

 parameter DECODE_ADDRESS=3'b000,
      LOAD_FIRST_DATA=3'b001,
      LOAD_DATA=3'b010,
      FIFO_FULL_STATE=3'b011,
      LOAD_AFTER_FULL=3'b100,
      LOAD_PARITY=3'b101,
      CHECK_PARITY_ERROR=3'b110,
      WAIT_TILL_EMPTY=3'b111;
			
reg [2:0] present,next_state;
reg [1:0] int_addr; //to read the destination address
			
			// present state
			
	always (@posedge clk)
		begin
		if(!rst)
		present <= DECODE_ADDRESS;
		
		else if (soft_reset_0 && int_addr[1:0] == 2'b00||
		soft_reset_1 && int_addr[1:0] == 2'b01 || soft_reset_2 && int_addr[1:0] == 2'b10)

			present <= DECODE_ADDRESS;
			else
			present <= next_state;
		end	
			
	//capture the data

always@(posedge clk)
begin
    if(!rst)
        int_addr<=2'b11;
    else if (soft_reset_0==1&&int_addr==2'b00|soft_reset_1==1&&int_addr==2'b01|soft_reset_2==1&&int_addr==2'b10)
        int_addr<=2'b11;
    else
        begin
        if(detect_add==1)
         int_addr<=data_in;
        end
end




always@(posedge clk)
begin
if(!rst)
fifo_address <= 2'd0;

else if(detect_add)
fifo_address<=data_in;
end	//not consider this para code

next state logic



 always@(*)
 begin

if (int_addr != 2'b11)
		 begin
		 next_state <= DECODE_ADDRESS;
		 case(present)
		 
		 DECODE_ADDRESS:if((pkt_valid&(data_in==0)&fifo_empty_0)|
		 (pkt_valid&(data_in==1)&fifo_empty_1)|
		 (pkt_valid&(data_in==2)&fifo_empty_2))
		 next_state = LOAD_FIRST_DATA;
		 
		 else if ((pkt_valid&(int_addr==0)&!fifo_empty_0)|
		 (pkt_valid&(int_addr==1)&!fifo_empty_1)|
		 (pkt_valid&(int_addr==2)&!fifo_empty_2))
                next_state=WAIT_TILL_EMPTY;
              else
                next_state=DECODE_ADDRESS;
				
				
	LOAD_FIRST_DATA : next_state = LOAD_DATA;

LOAD_DATA : if (fifo_full)
next_state = FIFO_FULL_STATE;

else if (!fifo_full&&!pkt_valid)	
next_state = LOAD_PARITY;

else
next_state = LOAD_DATA;


            FIFO_FULL_STATE:if(!fifo_full)
                next_state=LOAD_AFTER_FULL;
              else
                next_state=FIFO_FULL_STATE;
				
			
      LOAD_AFTER_FULL:if(!parity_done&&!low_pkt_valid)
                next_state=LOAD_DATA;
               else if(!parity_done&&low_pkt_valid)
                next_state=LOAD_PARITY;
               else
                next_state=DECODE_ADDRESS;
				

LOAD_PARITY:next_state=CHECK_PARITY_ERROR;

    CHECK_PARITY_ERROR:if(!fifo_full)
                next_state=DECODE_ADDRESS;
              else
                next_state=FIFO_FULL_STATE;
				
				
				
				
      WAIT_TILL_EMPTY:if(((int_addr==0)&&fifo_empty_0) &&
	  ((int_addr==1)&&fifo_empty_1) &&((int_addr==2)&&fifo_empty_2))
                next_state=LOAD_FIRST_DATA;
                   else
                next_state=WAIT_TILL_EMPTY;

        endcase
    end

	else
    next_state=DECODE_ADDRESS;
end

//OUTPUT COMBINATIONAL BLOCK

assign detect_add=(present==DECODE_ADDRESS)?1'b1:1'b0;
assign ld_state=(present==LOAD_DATA)?1'b1:1'b0;
assign laf_state=(present==LOAD_AFTER_FULL)?1'b1:1'b0;
assign full_state=(present==FIFO_FULL_STATE)?1'b1:1'b0;
assign write_enb_reg=(present==LOAD_DATA||present==LOAD_AFTER_FULL||present==LOAD_PARITY)?1'b1:1'b0;
assign rst_int_reg=(present==CHECK_PARITY_ERROR)?1'b1:1'b0;
assign lfd_state=(present==LOAD_FIRST_DATA)?1'b1:1'b0;
assign busy=(present==LOAD_FIRST_DATA||present==LOAD_PARITY||present==LOAD_AFTER_FULL||present==CHECK_PARITY_ERROR||present==WAIT_TILL_EMPTY||present==FIFO_FULL_STATE)?1'b1:1'b0;

endmodule	*/		

		 