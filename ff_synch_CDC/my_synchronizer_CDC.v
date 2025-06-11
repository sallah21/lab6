module my_synchronizer_CDC #
(
)
(
  input                       i_clk_a,
  input                       i_rst_a,  

  input                       i_clk_b,
  input                       i_rst_b,  

  input                       i_data_clk_a,   

  output                      o_data_clk_b


);


 reg   r_data_clk_a;
 reg   r_data_clk_b;
 reg   r_data_clk_b_sync;

  //capture data in clock domain A
 always @(posedge i_clk_a or negedge i_rst_a)
  begin
    if (!i_rst_a)
        r_data_clk_a <= 1'b0;
    else
        r_data_clk_a <= i_data_clk_a; 
  end
 
  //capture data in clock domain B
  always @(posedge i_clk_b or negedge i_rst_b)
  begin
    if (!i_rst_b)
       r_data_clk_b_sync <= 1'b0;
    else
       r_data_clk_b_sync <= r_data_clk_a; 
  end

    //capture data in clock domain B
  always @(posedge i_clk_b or negedge i_rst_b)
  begin
    if (!i_rst_b)
       r_data_clk_b <= 1'b0;
    else
       r_data_clk_b <= r_data_clk_b_sync; 
  end
  
 assign o_data_clk_b = r_data_clk_b;
endmodule