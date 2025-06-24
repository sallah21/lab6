module my_synchronizer_CDC #
(
)
(
  input                       i_clk_a,
  input                       i_rst_a,  

  input                       i_clk_b,
  input                       i_rst_b,  

  input                       i_data_clk_a,   

  output                      o_data_clk_b,
  
  // New output to control next_data_clk_a
  output                      o_next_data_clk_a
);


 reg   r_data_clk_a;
 reg   r_data_clk_b;
 reg   r_data_clk_b_sync;
 
 // Toggle flip-flops for handshaking
 reg   r_req_toggle_clk_a;    // Request toggle in clock domain A
 reg   r_req_toggle_sync1;    // Request toggle synchronized to clock domain B (1st FF)
 reg   r_req_toggle_sync2;    // Request toggle synchronized to clock domain B (2nd FF)
 reg   r_req_toggle_b;        // Captured request toggle in clock domain B
 
 reg   r_ack_toggle_clk_b;    // Acknowledge toggle in clock domain B
 reg   r_ack_toggle_sync1;    // Acknowledge toggle synchronized to clock domain A (1st FF)
 reg   r_ack_toggle_sync2;    // Acknowledge toggle synchronized to clock domain A (2nd FF)
 reg   r_ack_toggle_a;        // Captured acknowledge toggle in clock domain A
 
 wire  w_req_toggle_changed;  // Indicates new data has arrived in domain B
 wire  w_ack_match_req;       // Indicates data has been acknowledged in domain A

  //capture data in clock domain A
 always @(posedge i_clk_a or negedge i_rst_a)
  begin
    if (!i_rst_a)
        r_data_clk_a <= 1'b0;
    else if (o_next_data_clk_a)  // Only capture new data when it's safe to do so
        r_data_clk_a <= i_data_clk_a; 
  end
 
 // Request toggle FF in domain A - toggles when new data is captured
 always @(posedge i_clk_a or negedge i_rst_a)
  begin
    if (!i_rst_a)
        r_req_toggle_clk_a <= 1'b0;
    else if (o_next_data_clk_a)
        r_req_toggle_clk_a <= ~r_req_toggle_clk_a;  // Toggle when new data is captured
  end
 
 // Synchronize request toggle to domain B 
 always @(posedge i_clk_b or negedge i_rst_b)
  begin
    if (!i_rst_b) begin
        r_req_toggle_sync1 <= 1'b0;
        r_req_toggle_sync2 <= 1'b0;
    end
    else begin
        r_req_toggle_sync1 <= r_req_toggle_clk_a;
        r_req_toggle_sync2 <= r_req_toggle_sync1;
    end
  end

 // Capture request toggle in domain B
 always @(posedge i_clk_b or negedge i_rst_b)
  begin
    if (!i_rst_b)
        r_req_toggle_b <= 1'b0;
    else
        r_req_toggle_b <= r_req_toggle_sync2;
  end
  
 // Detect change in request toggle, indicating new data
 assign w_req_toggle_changed = r_req_toggle_b != r_req_toggle_sync2;
 
 // Acknowledge toggle FF in domain B - toggles when new data is detected
 always @(posedge i_clk_b or negedge i_rst_b)
  begin
    if (!i_rst_b)
        r_ack_toggle_clk_b <= 1'b0;
    else if (w_req_toggle_changed)
        r_ack_toggle_clk_b <= ~r_ack_toggle_clk_b;  // Toggle to acknowledge data reception
  end
  
 // Synchronize acknowledge toggle to domain A
 always @(posedge i_clk_a or negedge i_rst_a)
  begin
    if (!i_rst_a) begin
        r_ack_toggle_sync1 <= 1'b0;
        r_ack_toggle_sync2 <= 1'b0;
    end
    else begin
        r_ack_toggle_sync1 <= r_ack_toggle_clk_b;
        r_ack_toggle_sync2 <= r_ack_toggle_sync1;
    end
  end
  
 // Capture acknowledge toggle in domain A
 always @(posedge i_clk_a or negedge i_rst_a)
  begin
    if (!i_rst_a)
        r_ack_toggle_a <= 1'b0;
    else
        r_ack_toggle_a <= r_ack_toggle_sync2;
  end
  
 // Safe to send new data when acknowledge matches request in domain A
 assign w_ack_match_req = r_ack_toggle_a == r_req_toggle_clk_a;
 
 // Output control signal for next_data_clk_a
 assign o_next_data_clk_a = w_ack_match_req;
  
  //capture data in clock domain B - synchronizes r_data_clk_a to domain B
  always @(posedge i_clk_b or negedge i_rst_b)
  begin
    if (!i_rst_b)
       r_data_clk_b_sync <= 1'b0;
    else
       r_data_clk_b_sync <= r_data_clk_a; 
  end

    //capture data in clock domain B - double FF synchronizer
  always @(posedge i_clk_b or negedge i_rst_b)
  begin
    if (!i_rst_b)
       r_data_clk_b <= 1'b0;
    else
       r_data_clk_b <= r_data_clk_b_sync; 
  end
  
 assign o_data_clk_b = r_data_clk_b;
endmodule