module fifo_reader #
(
  parameter DATA_WIDTH = 1,
  parameter PTR_WIDTH  = 3              //Pointer Width
)
(
  input                       i_clk,
  input                       i_rst,  

  //FIFO reader interface
  input  [(PTR_WIDTH-1):0]    i_wr_ptr_gray,
  input  [(DATA_WIDTH-1):0]   i_data,
  output [(PTR_WIDTH-1):0]    o_rd_ptr_gray,
  
  //output valid ready
  output                      o_valid,
  input                       i_ready,
  output  [(DATA_WIDTH-1):0]  o_data

);
 
 parameter FSM_A_SIZE = 2;  


 localparam BUSY          = 2'd0; //waiting to check if the FIFO is empty
 localparam VALID         = 2'd1; //ready to send data
 localparam READ_F        = 2'd2; //incrementing FIFO read pointer
 localparam EMPTY_F       = 2'd3; //waiting for write to FIFO
 
 reg [(FSM_A_SIZE-1):0] r_state;
 reg [(FSM_A_SIZE-1):0] next_state;
 
 //Read pointer and its gray version
 reg [(PTR_WIDTH-1):0] r_rd_ptr_bin;
 reg [(PTR_WIDTH-1):0] r_rd_ptr_gray; 
 
 reg  [(DATA_WIDTH-1):0] r_data;
 reg                     r_valid;
 
 wire fifo_empty;
 
 wire [(PTR_WIDTH-1):0] rd_ptr_bin_inc;
 wire [(PTR_WIDTH-1):0] rd_ptr_gray_inc;
 
 assign rd_ptr_bin_inc = r_rd_ptr_bin + 1;
 //Conversion from binary to Gray code
 assign rd_ptr_gray_inc = (rd_ptr_bin_inc) ^ ((rd_ptr_bin_inc) >> 1);
 
  always @ (*) 
    begin: FSM_COMBO
        case (r_state)
           BUSY: 
           begin
            next_state = VALID;
            if (fifo_empty)
                begin
                    next_state = EMPTY_F;
                end
           end     
           
           VALID: 
           begin
            next_state = VALID;
            if (fifo_empty)
                begin
                    next_state = EMPTY_F;
                end
            else if (i_ready & o_valid)
                begin
                    next_state = READ_F;
                end 
           end     
           
           READ_F: 
           begin
            next_state = BUSY;
            if (fifo_empty)
                begin
                    next_state = EMPTY_F;
                end 
           end
           
           EMPTY_F: 
           begin
            next_state = VALID;
            if (fifo_empty)
                begin
                    next_state = EMPTY_F;
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
            r_rd_ptr_bin <= 0;
            r_rd_ptr_gray <= 0;
            r_data <= {DATA_WIDTH{1'b0}};
            r_valid <= 1'b0;
        end    
    else
        begin
           case (next_state)
                      BUSY: 
                      begin  
                        r_rd_ptr_bin <= r_rd_ptr_bin;
                        r_rd_ptr_gray <= r_rd_ptr_gray;
                        r_data  <= r_data;
                        r_valid <= 1'b0;
                      end
                      
                      VALID: 
                      begin  
                        r_rd_ptr_bin <= r_rd_ptr_bin;
                        r_rd_ptr_gray <= r_rd_ptr_gray;
                        r_data  <= i_data;
                        r_valid <= 1'b1;
                      end
                      
                      READ_F: 
                      begin 
                        r_rd_ptr_bin <= rd_ptr_bin_inc;
                        r_rd_ptr_gray <= rd_ptr_gray_inc;
                        r_data  <= r_data;
                        r_valid <= 1'b0;
                      end
                      
                      EMPTY_F: 
                      begin  
                        r_rd_ptr_bin <= r_rd_ptr_bin;
                        r_rd_ptr_gray <= r_rd_ptr_gray;
                        r_data  <= r_data;
                        r_valid <= 1'b0;
                      end
                      
                      default: 
                      begin
                        r_rd_ptr_bin <= r_rd_ptr_bin;
                        r_rd_ptr_gray <= r_rd_ptr_gray;
                        r_data  <= r_data;
                        r_valid <= 1'b0;
                      end
                   endcase
        end
     end

 //if the read and write pointers are equal, it means the FIFO is empty
 assign fifo_empty = (r_rd_ptr_gray == i_wr_ptr_gray);

 //output signals
 assign o_rd_ptr_gray = r_rd_ptr_gray;
 
 assign o_valid = r_valid;
 assign o_data  = r_data;
  
  
endmodule