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

 // reset A
 always @(posedge i_clk or negedge i_rst_a)
  begin
    if (!i_rst_a)
        r_data_a <= 1'b0;
    else
        r_data_a <= i_data_a; 
  end
 
 // reset B
 always @(posedge i_clk or negedge i_rst_b)
  begin
    if (!i_rst_b)
       r_data_b <= 1'b0;
    else
       r_data_b <= r_data_a; 
  end
  
 assign o_data_b = r_data_b;
endmodule