module req_ack_receiver #
(
  parameter DATA_WIDTH = 1
)
(
  input                       i_clk,
  input                       i_rst,  

  //input synch to i_clk interface
  input                       i_req,
  output                      o_ack,
  input  [(DATA_WIDTH-1):0]   i_data,
  
  //output valid ready
  output                      o_valid,
  input                       i_ready,
  output  [(DATA_WIDTH-1):0]  o_data

);
 
 parameter FSM_A_SIZE = 2;  

 localparam REQ_WAIT_1 = 2'd0; //Waiting for a request
 localparam READY      = 2'd1; //Waiting for the receiver's ready signal
 localparam REQ_WAIT_0 = 2'd2; //Waiting for the request line to be deasserted
 
 reg [(FSM_A_SIZE-1):0] r_state;
 reg [(FSM_A_SIZE-1):0] next_state;
 
 
 reg                     r_ack;
 reg  [(DATA_WIDTH-1):0] r_data;
 reg                     r_valid;
  
  always @ (*) 
    begin: FSM_COMBO
        case (r_state)
           REQ_WAIT_1: 
           begin
            next_state = REQ_WAIT_1;
            if (i_req == 1'b1) 
                begin
                    next_state = READY;
                end               
           end
           
           READY: 
           begin
            next_state = READY;
            if (i_ready && o_valid) 
                begin
                    next_state = REQ_WAIT_0;
                end     
           end
           
           REQ_WAIT_0: 
           begin
            next_state = REQ_WAIT_0;
            if (i_req == 1'b0)  
                begin
                    next_state = REQ_WAIT_1;
                end 
           end
           
           
           default: 
           begin
            next_state = REQ_WAIT_1;
           end
        endcase
    end
  
  
   always @(posedge i_clk or negedge i_rst)
   begin: FSM_SEQ
    if (!i_rst)
        begin
            r_state <= REQ_WAIT_1;
        end    
    else
        begin 
            r_state <= next_state;
        end
   end 
  
  
   always @(posedge i_clk or negedge i_rst)
   begin: OUTPUT_LOGIC
    if (!i_rst)
        begin
            r_ack <= 1'b0;
            r_data <= {DATA_WIDTH{1'b0}};
            r_valid <= 1'b0;
        end    
    else
        begin
           case (next_state)
                      REQ_WAIT_1: 
                      begin  
                        r_ack   <= 1'b0;
                        r_data  <= r_data;
                        r_valid <= 1'b0;
                      end
                      
                      READY: 
                      begin 
                        r_ack   <= 1'b0;
                        r_data <= i_data;
                        r_valid <= 1'b1;
                      end
                      
                      REQ_WAIT_0: 
                      begin  
                        r_ack   <= 1'b1;
                        r_data  <= r_data;
                        r_valid <= 1'b0;
                      end
                      
                      default: 
                      begin
                        r_ack <= 1'b0;
                        r_data <= r_data;
                        r_valid <= 1'b0;
                      end
                   endcase
        end
     end

 //output signals
 assign o_ack   = r_ack;
 assign o_valid = r_valid;
 assign o_data  = r_data;
  
  
endmodule