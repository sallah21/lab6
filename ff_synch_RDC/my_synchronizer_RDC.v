module my_synchronizer_RDC #
(
)
(
  input                       i_clk,
  
  input                       i_rst_a,  

  input                       i_rst_b,  

  input                       i_data_a,   

  output                      o_data_b


);

 reg   r_data_a;
 reg   r_data_b;

 reg   i_rst_a_sync;
 reg   i_rst_b_sync;

 // reset A
 always @(posedge i_clk)
  begin
    if (!i_rst_a_sync)
        r_data_a <= 1'b0;
    else
        r_data_a <= i_data_a; 
  end

  
 // reset two stage synchronizer
  always @(posedge i_clk )
    begin
      i_rst_a_sync <= i_rst_a;
    end

   always @(posedge i_clk)
    begin
      i_rst_b_sync <= i_rst_b;
    end

 // reset B
 always @(posedge i_clk )
  begin
    if (!i_rst_b_sync)
       r_data_b <= 1'b0;
    else
       r_data_b <= r_data_a; 
  end
  
 assign o_data_b = r_data_b;
endmodule