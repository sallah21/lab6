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
req_ack_sender_clk_a (
  .i_clk   (i_clk_a),
  .i_rst   (r_local_rst_a_sync),
  .i_valid (i_valid_clk_a),
  .o_ready (o_ready_clk_a),
  .i_data  (i_data_clk_a),
  .o_req   (req_clk_a),
  .i_ack   (ack_clk_a_sync), 
  .o_data  (data_clk_a)
);
  
  
req_ack_receiver #(
  .DATA_WIDTH (DATA_WIDTH)
)
req_ack_receiver_clk_b (
  .i_clk    (i_clk_b),
  .i_rst    (r_local_rst_b_sync ),
  .i_req    (req_clk_b_sync), 
  .o_ack    (ack_clk_b),
  .i_data   (data_clk_a),
  .o_valid  (o_valid_clk_b),
  .i_ready  (i_ready_clk_b), 
  .o_data   (o_data_clk_b)
);
  
// Two stage synchronizer for receiver o_ack (ack_clk_b) into i_clk_a domain
reg ack_clk_a_ff_1;
reg ack_clk_a_ff_2;
wire ack_clk_a_sync;
assign ack_clk_a_sync = ack_clk_a_ff_2;
always @(posedge i_clk_a or negedge r_local_rst_a_sync) begin
  if (!r_local_rst_a_sync) begin
    ack_clk_a_ff_1 <= 1'b0;
    ack_clk_a_ff_2 <= 1'b0;
  end else begin
    ack_clk_a_ff_1 <= ack_clk_b;
    ack_clk_a_ff_2 <= ack_clk_a_ff_1;
  end
end 

// Two stage synchronizer for sender o_req (req_clk_a) into i_clk_b domain
reg req_clk_b_ff_1;
reg req_clk_b_ff_2;
wire req_clk_b_sync;
assign req_clk_b_sync = req_clk_b_ff_2;
always @(posedge i_clk_b or negedge r_local_rst_b_sync) begin
  if (!r_local_rst_b_sync) begin
    req_clk_b_ff_1 <= 1'b0;
    req_clk_b_ff_2 <= 1'b0;
  end else begin
    req_clk_b_ff_1 <= req_clk_a;
    req_clk_b_ff_2 <= req_clk_b_ff_1;
  end
end

// Two stage synchronizer for sender o_ready
reg ready_clk_a_ff_1;
reg ready_clk_a_ff_2;
wire ready_clk_a_sync;
assign ready_clk_a_sync = ready_clk_a_ff_2;
always @(posedge i_clk_a or negedge r_local_rst_a_sync) begin
  if (!r_local_rst_a_sync) begin
    ready_clk_a_ff_1 <= 1'b0;
    ready_clk_a_ff_2 <= 1'b0;
  end else begin
    ready_clk_a_ff_1 <= o_ready_clk_a;
    ready_clk_a_ff_2 <= ready_clk_a_ff_1;
  end
end 

// 2-stage synchronizers for local resets
  reg r_local_rst_a_ff1, r_local_rst_a_ff2;
  reg r_local_rst_b_ff1, r_local_rst_b_ff2;

  wire r_local_rst_a_sync;
  wire r_local_rst_b_sync;
  assign r_local_rst_a_sync = r_local_rst_a_ff2;
  assign r_local_rst_b_sync = r_local_rst_b_ff2;
  // Synchronize global async reset to clk_a domain
  always @(posedge i_clk_a or negedge i_rst) begin
    if (!i_rst) begin
      r_local_rst_a_ff1 <= 1'b0;
      r_local_rst_a_ff2 <= 1'b0;
    end else begin
      r_local_rst_a_ff1 <= 1'b1;
      r_local_rst_a_ff2 <= r_local_rst_a_ff1;
    end
  end

  // Synchronize global async reset to clk_b domain
  always @(posedge i_clk_b or negedge i_rst) begin
    if (!i_rst) begin
      r_local_rst_b_ff1 <= 1'b0;
      r_local_rst_b_ff2 <= 1'b0;
    end else begin
      r_local_rst_b_ff1 <= 1'b1;
      r_local_rst_b_ff2 <= r_local_rst_b_ff1;
    end
  end


endmodule