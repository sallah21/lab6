module req_ack_sender #
(
  parameter DATA_WIDTH = 1
)
(
  input                       i_clk,
  input                       i_rst,  

  //input valid ready
  input                       i_valid,
  output                      o_ready,
  input  [(DATA_WIDTH-1):0]   i_data,

  //output synch interface
  output                      o_req,
  input                       i_ack,
  output [(DATA_WIDTH-1):0]   o_data

);

 parameter  FSM_A_SIZE = 2;  
 
 localparam ACK_WAIT_0 = 2'd0; //Waiting for the acknowledgment to be deasserted
 localparam VALID      = 2'd1; //Waiting for the transmitter's valid signal
 localparam CAPTURE    = 2'd2; //Capturing the data
 localparam ACK_WAIT_1 = 2'd3; //Waiting for acknowledgment of data reception
 
 reg [(FSM_A_SIZE-1):0] r_state;
 reg [(FSM_A_SIZE-1):0] next_state;
 
 reg  r_req;
 reg  r_ready;
 
 reg [(DATA_WIDTH-1):0] r_data;

  always @ (*) 
    begin: FSM_COMBO
        case (r_state)
           ACK_WAIT_0: 
           begin
            next_state = ACK_WAIT_0;
            if (i_ack == 1'b0) 
                begin
                    next_state = VALID;
                end    
           end
           
           VALID: 
           begin
            next_state = VALID;
            if ((i_valid) && (i_ack == 1'b0) && (o_ready))
                begin
                    next_state = CAPTURE;
                end    
           end
           
           CAPTURE: 
           begin
            next_state = ACK_WAIT_1; 
           end
           
           ACK_WAIT_1: 
           begin
            next_state = ACK_WAIT_1;
            if (i_ack == 1'b1)
                begin
                    next_state = ACK_WAIT_0;
                end    
           end
           
           default: 
           begin
            next_state = ACK_WAIT_0;
           end
        endcase
    end
  
  
   always @(posedge i_clk or negedge i_rst)
   begin: FSM_SEQ
    if (!i_rst)
        begin
            r_state <= ACK_WAIT_0;
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
            r_req <= 1'b0;
            r_data <= {DATA_WIDTH{1'b0}};
            r_ready <= 1'b0;
        end    
    else
        begin
           case (next_state)
                      ACK_WAIT_0: 
                      begin  
                        r_req   <= 1'b0;
                        r_data  <= r_data;
                        r_ready <= 1'b0;
                      end
                      
                      VALID: 
                      begin 
                        r_req   <= 1'b0;
                        r_data  <= r_data;
                        r_ready <= 1'b1;
                      end
                      
                      CAPTURE: 
                      begin 
                        r_req   <= 1'b0;
                        r_data  <= i_data;
                        r_ready <= 1'b0;
                      end
                      
                      ACK_WAIT_1: 
                      begin  
                        r_req   <= 1'b1;
                        r_data  <= r_data;
                        r_ready <= 1'b0;
                      end
                      
                      default: 
                      begin
                        r_req   <= 1'b0;
                        r_data  <= {DATA_WIDTH{1'b0}};
                        r_ready <= 1'b0;
                      end
                   endcase
        end
     end
 
 
 //output signals
 assign o_ready = r_ready;
 
 assign o_req  = r_req;
 assign o_data = r_data;
  
  
endmodule