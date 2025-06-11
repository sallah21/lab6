module my_synchronizer_RDC2 #
(
)
(
  input                       i_rst, // global async reset
  input                       i_clk_a,
  input                       i_clk_b,
  input                       i_data_clk_a,   
  output                      o_data_clk_b
);

  // 2-stage synchronizers for local resets
  reg r_local_rst_a_ff1, r_local_rst_a_ff2;
  reg r_local_rst_b_ff1, r_local_rst_b_ff2;

  // Data synchronizer registers
  reg r_data_clk_a;
  reg r_data_clk_b_sync;
  reg r_data_clk_b;

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

  // Capture data in clock domain A
  always @(posedge i_clk_a or negedge r_local_rst_a_ff2) begin
    if (!r_local_rst_a_ff2)
      r_data_clk_a <= 1'b0;
    else
      r_data_clk_a <= i_data_clk_a; 
  end

  // 2-stage synchronizer for data in clock domain B
  always @(posedge i_clk_b or negedge r_local_rst_b_ff2) begin
    if (!r_local_rst_b_ff2)
      r_data_clk_b_sync <= 1'b0;
    else
      r_data_clk_b_sync <= r_data_clk_a; 
  end

  always @(posedge i_clk_b or negedge r_local_rst_b_ff2) begin
    if (!r_local_rst_b_ff2)
      r_data_clk_b <= 1'b0;
    else
      r_data_clk_b <= r_data_clk_b_sync; 
  end

  assign o_data_clk_b = r_data_clk_b;

endmodule