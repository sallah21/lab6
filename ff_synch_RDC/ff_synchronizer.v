module ff_synchronizer #
(
    parameter SYNCH_FF_LENGHT = 2,
    parameter DATA_WIDTH = 1
)
(
  input                       i_clk,
  input                       i_rst,  

  input  [(DATA_WIDTH-1):0]   i_in,  //unsynchronized to clk out
  output [(DATA_WIDTH-1):0]   o_out  //synchronized to clk out

);

 generate
    //no synchronization
    if (SYNCH_FF_LENGHT == 0)
        begin: ff_lenght_0
            assign o_out = i_in;
        end
    
    //single filp-flop
    else if (SYNCH_FF_LENGHT == 1)
        begin: ff_lenght_1
             reg [(DATA_WIDTH-1):0] r_req_clk_out;
             
             always @(posedge i_clk or negedge i_rst)
               if (!i_rst)
                   begin
                       r_req_clk_out <= {DATA_WIDTH{1'b0}};
                   end   
               else
                   begin
                       r_req_clk_out <= i_in;
                   end   
             assign o_out = r_req_clk_out;     
        end
        
    else
        //two or more filp-flops
        begin: ff_lenght_2or_more
         reg [((SYNCH_FF_LENGHT*DATA_WIDTH)-1):0] r_req_clk_out;
         
         always @(posedge i_clk or negedge i_rst)
             if (!i_rst)
                 begin
                     r_req_clk_out <= {(SYNCH_FF_LENGHT*DATA_WIDTH){1'b0}};
                 end   
             else
                 begin
                     r_req_clk_out <= {r_req_clk_out[(SYNCH_FF_LENGHT-1)*DATA_WIDTH-1:0],i_in};
                 end   
        
         assign o_out = r_req_clk_out[((SYNCH_FF_LENGHT*DATA_WIDTH)-1) : ((SYNCH_FF_LENGHT*(DATA_WIDTH))-DATA_WIDTH)];
        end
 endgenerate

endmodule 