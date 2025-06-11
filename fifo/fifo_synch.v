// fifo_synch: Dual-clock FIFO with async active-low reset and valid-ready interface
module fifo_synch #
(
    parameter SYNCH_FF_LENGHT = 2,
    parameter DATA_WIDTH      = 8,        // Width of data bus
    parameter PTR_WIDTH       = 3        // Address pointer width (FIFO depth = 2^PTR_WIDTH)
)
(
    input                       i_rst,    // Global asyn active low reset
    
    // Write clock domain
    input                       i_clk_a,
    input                       i_valid_clk_a,
    output                      o_ready_clk_a,
    input  [DATA_WIDTH-1:0]     i_data_clk_a,

    // Read clock domain
    input                       i_clk_b,
    output                      o_valid_clk_b,
    input                       i_ready_clk_b,
    output [DATA_WIDTH-1:0]     o_data_clk_b
);

wire                        wr_en;
wire [(DATA_WIDTH-1):0]     data_i;
wire                        fifo_full;

wire [(DATA_WIDTH-1):0]     data_o;
wire [(PTR_WIDTH-1):0]      wr_ptr_gray_clk_a;
wire [(PTR_WIDTH-1):0]      rd_ptr_gray_clk_b;

fifo_writer #
(
  .DATA_WIDTH (DATA_WIDTH)
)
fifo_writer_a
(
  //source clock
  .i_clk (i_clk_a),
  .i_rst (r_local_rst_a_sync),

  //input valid ready
  .i_valid   (i_valid_clk_a),
  .o_ready   (o_ready_clk_a),
  .i_data    (i_data_clk_a),

  //Fifo inrterface
  .o_wr_en     (wr_en),
  .o_data      (data_i),
  .i_fifo_full (fifo_full)

);

fifo_mem #
(
    .DATA_WIDTH (DATA_WIDTH),         
    .PTR_WIDTH  (PTR_WIDTH)
)
fifo_mem_i
(
  //source clock
  .i_clk               (i_clk_a),
  .i_rst               (r_local_rst_a_sync), 

  //FIFO writer interface
  .i_wr_en             (wr_en),
  .i_data              (data_i),
  .o_fifo_full         (fifo_full),
  
  //FIFO reader interface
  .o_wr_ptr_gray       (wr_ptr_gray_clk_a),
  .o_data              (data_o),
  .i_rd_ptr_gray       (rd_ptr_gray_clk_a_synch), 
  .i_rd_ptr_gray_clk_b (rd_ptr_gray_clk_b)
);


fifo_reader #
(
  .DATA_WIDTH     (DATA_WIDTH),
  .PTR_WIDTH      (PTR_WIDTH) 
)
fifo_reader_b
(
  .i_clk          (i_clk_b),
  .i_rst          (r_local_rst_b_sync),  

  //FIFO reader interface
  .i_wr_ptr_gray  (wr_ptr_gray_clk_b_synch),
  .i_data         (data_o),
  .o_rd_ptr_gray  (rd_ptr_gray_clk_b),
  
  //output valid ready
  .o_valid        (o_valid_clk_b),
  .i_ready        (i_ready_clk_b),
  .o_data         (o_data_clk_b)

);

// Fifo reader 2 step synchronizer for wr_ptr_gray_clk_a
reg [(PTR_WIDTH-1):0]  wr_ptr_gray_clk_ff1;
reg [(PTR_WIDTH-1):0]  wr_ptr_gray_clk_ff2;
wire [(PTR_WIDTH-1):0] wr_ptr_gray_clk_b_synch;
assign wr_ptr_gray_clk_b_synch = wr_ptr_gray_clk_ff2;
always @(posedge i_clk_b or negedge r_local_rst_b_sync) begin
  if (!r_local_rst_b_sync) begin
    wr_ptr_gray_clk_ff1 <= {(PTR_WIDTH){1'b0}};
    wr_ptr_gray_clk_ff2 <= {(PTR_WIDTH){1'b0}};
  end else begin
    wr_ptr_gray_clk_ff1 <= wr_ptr_gray_clk_a;
    wr_ptr_gray_clk_ff2 <= wr_ptr_gray_clk_ff1;
  end
end

// Fifo writer 2 step synchronizer for rd_ptr_gray_clk_b
reg [(PTR_WIDTH-1):0]  rd_ptr_gray_clk_ff1;
reg [(PTR_WIDTH-1):0]  rd_ptr_gray_clk_ff2;
wire [(PTR_WIDTH-1):0] rd_ptr_gray_clk_a_synch;
assign rd_ptr_gray_clk_a_synch = rd_ptr_gray_clk_ff2;
always @(posedge i_clk_a or negedge r_local_rst_a_sync) begin
  if (!r_local_rst_a_sync) begin
    rd_ptr_gray_clk_ff1 <= {(PTR_WIDTH){1'b0}};
    rd_ptr_gray_clk_ff2 <= {(PTR_WIDTH){1'b0}};
  end else begin
    rd_ptr_gray_clk_ff1 <= rd_ptr_gray_clk_b;
    rd_ptr_gray_clk_ff2 <= rd_ptr_gray_clk_ff1;
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
