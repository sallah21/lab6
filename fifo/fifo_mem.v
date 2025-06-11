module fifo_mem #
(
    parameter DATA_WIDTH = 8,              //FIFO Data width
    parameter PTR_WIDTH  = 3,              //Pointer Width
    parameter FIFO_DEPTH = 2 ** PTR_WIDTH  //Fifo depth
)
(
  //source clock
  input                       i_clk,
  input                       i_rst, 

  //FIFO writer interface
  input                       i_wr_en,
  input  [(DATA_WIDTH-1):0]   i_data,
  output                      o_fifo_full,
  
  //FIFO reader interface
  output [(PTR_WIDTH-1):0]    o_wr_ptr_gray,
  output [(DATA_WIDTH-1):0]   o_data,
  input  [(PTR_WIDTH-1):0]    i_rd_ptr_gray,
  input  [(PTR_WIDTH-1):0]    i_rd_ptr_gray_clk_b


);
    integer i;
    // Memory
    reg [DATA_WIDTH-1:0] m_mem [0:FIFO_DEPTH-1];

    // Write pointer and its gray version
    reg [(PTR_WIDTH-1):0] r_wr_ptr_bin;
    reg [(PTR_WIDTH-1):0] r_wr_ptr_gray;
    
    wire [(PTR_WIDTH-1):0] rd_ptr_bin;
    wire [(PTR_WIDTH-1):0] wr_ptr_bin_inc;
    wire [(PTR_WIDTH-1):0] wr_ptr_gray_inc;
    
    assign wr_ptr_bin_inc = r_wr_ptr_bin + 1;
    //Conversion from binary to Gray code
    assign wr_ptr_gray_inc = (wr_ptr_bin_inc) ^ ((wr_ptr_bin_inc) >> 1);

    // Write logic
    always @(posedge i_clk or negedge i_rst) 
    begin
        if (!i_rst) 
            begin
                for (i = 0; i < FIFO_DEPTH ; i = i +1 ) 
                    m_mem[i] <= {DATA_WIDTH{1'b0}};
                
                r_wr_ptr_bin <= {PTR_WIDTH{1'b0}};
                r_wr_ptr_gray <= {PTR_WIDTH{1'b0}};
            end 
                else if (i_wr_en && !o_fifo_full) 
            begin
                m_mem[r_wr_ptr_gray] <= i_data;
                
                r_wr_ptr_bin <= wr_ptr_bin_inc;
                r_wr_ptr_gray <= wr_ptr_gray_inc;  
            end
    end

    //output ports
    
    //reading data from memory
    assign o_data = m_mem[i_rd_ptr_gray_clk_b];
    
    //FIFO is full when next write pointer equals read pointer
    assign o_fifo_full = (wr_ptr_gray_inc == i_rd_ptr_gray);  
    
    assign o_wr_ptr_gray = r_wr_ptr_gray;                             

endmodule