module fifo_writer #
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

  //Fifo inrterface
  output                      o_wr_en,
  output [(DATA_WIDTH-1):0]   o_data,
  input                       i_fifo_full

);

 
 parameter  FSM_A_SIZE = 2;  
 
 localparam BUSY       = 2'd0; //waiting to check if the FIFO is full
 localparam READY      = 2'd1; //ready to receive data
 localparam WRITE_F    = 2'd2; //writing data to FIFO
 localparam FULL_F     = 2'd3; //waiting for space in FIFO
 
 reg [(FSM_A_SIZE-1):0] r_state;
 reg [(FSM_A_SIZE-1):0] next_state;
 
 reg  r_wr_en;
 reg  r_ready;
 
 reg [(DATA_WIDTH-1):0] r_data;

  always @ (*) 
    begin: FSM_COMBO
        case (r_state)
           BUSY: 
           begin
            next_state = READY;
            if (i_fifo_full)
                begin
                    next_state = FULL_F;
                end 
           end
           
           READY: 
           begin
            next_state = READY;
            if (i_fifo_full)
                begin
                    next_state = FULL_F;
                end
            else if (i_valid & o_ready)
                begin
                    next_state = WRITE_F;
                end    
           end
           
           WRITE_F: 
           begin
            next_state = BUSY;
            if (i_fifo_full)
                begin
                    next_state = FULL_F;
                end   
           end
           
           FULL_F: 
           begin
            next_state = READY;
            if (i_fifo_full)
                begin
                    next_state = FULL_F;
                end
           end
           
           default: 
           begin
            next_state = BUSY;
           end
        endcase
    end
  
  
   always @(posedge i_clk or negedge i_rst)
   begin: FSM_SEQ
    if (!i_rst)
        begin
            r_state <= BUSY;
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
            
            r_wr_en <= 1'b0;
            r_data  <= {DATA_WIDTH{1'b0}};
            r_ready <= 1'b0;
        end    
    else
        begin
           case (next_state)
                      BUSY: 
                      begin  
                        r_wr_en <= 1'b0;
                        r_data  <= {DATA_WIDTH{1'b0}};
                        r_ready <= 1'b0;
                      end
                      
                      READY: 
                      begin  
                        r_wr_en <= 1'b0;
                        r_data  <= {DATA_WIDTH{1'b0}};
                        r_ready <= 1'b1;
                      end
                      
                      WRITE_F: 
                      begin  
                        r_wr_en <= 1'b1;
                        r_data  <= i_data;
                        r_ready <= 1'b0;
                      end
                      
                      FULL_F: 
                      begin  
                        r_wr_en <= 1'b0;
                        r_data  <= {DATA_WIDTH{1'b0}};
                        r_ready <= 1'b0;
                      end
                      
                      default: 
                      begin
                        r_wr_en <= 1'b0;
                        r_data  <= {DATA_WIDTH{1'b0}};
                        r_ready <= 1'b0;
                      end
                   endcase
        end
     end
 
 
 //output signals
 assign o_ready  = r_ready;
 
 assign o_wr_en  = r_wr_en;
 assign o_data   = r_data;
  
  
endmodule