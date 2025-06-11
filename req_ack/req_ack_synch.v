module req_ack_synch #
(
    parameter SYNCH_FF_LENGHT = 2,
    parameter DATA_WIDTH = 8         //Data Width of input/output
)
(
  
  input                       i_rst, // Global asyn active low reset
  
  // Write clock domain
  input                       i_clk_a,
  input                       i_valid_clk_a,
  output                      o_ready_clk_a,
  input [(DATA_WIDTH-1):0]    i_data_clk_a,

  // Read clock domain
  input                       i_clk_b,
  output                      o_valid_clk_b,
  input                       i_ready_clk_b,
  output [(DATA_WIDTH-1):0]   o_data_clk_b

);

 
 wire req_clk_a;
 wire ack_clk_b;
 
 wire [(DATA_WIDTH-1):0]   data_clk_a;

 
req_ack_sender #
(
    .DATA_WIDTH (DATA_WIDTH)
)
req_ack_sender_clk_a
(
  .i_clk   (i_clk_a),
  .i_rst   (i_rst),

  .i_valid (i_valid_clk_a),
  .o_ready (o_ready_clk_a),
  .i_data  (i_data_clk_a),

  .o_req   (req_clk_a),
  .i_ack   (ack_clk_b),
  .o_data  (data_clk_a)

);
  
  
req_ack_receiver #
(
  .DATA_WIDTH (DATA_WIDTH)
)
req_ack_receiver_clk_b
(
  .i_clk    (i_clk_b),
  .i_rst    (i_rst),
  

  .i_req    (req_clk_a),
  .o_ack    (ack_clk_b),
  .i_data   (data_clk_a),

  .o_valid  (o_valid_clk_b),
  .i_ready  (i_ready_clk_b),
  .o_data   (o_data_clk_b)

);
  


endmodule