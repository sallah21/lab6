module my_synchronizer_RDC2 #
(
)
(
  input                       i_rst, //global async reset
  
  input                       i_clk_a,

  input                       i_clk_b,

  input                       i_data_clk_a,   

  output                      o_data_clk_b


);

 reg  r_data_clk_a;
 reg  r_data_clk_b;

 //capture data in clock domain A
 always @(posedge i_clk_a or negedge i_rst)
  begin
    if (!i_rst)
        r_data_clk_a <= 1'b0;
    else
        r_data_clk_a <= i_data_clk_a; 
  end

 //capture data in clock domain B
 always @(posedge i_clk_b or negedge i_rst)
  begin
    if (!i_rst)
        r_data_clk_b <= 1'b0;
    else
        r_data_clk_b <= r_data_clk_a; 
  end

 assign o_data_clk_b = r_data_clk_b;
endmodule