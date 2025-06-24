`timescale 1ns/1ps

module scenario_slow2fast();

// Parameters
localparam DATA_WIDTH = 8;
localparam PTR_WIDTH = 3;  // For FIFO depth of 8
localparam SYNCH_FF_LENGHT = 2;
localparam TEST_DATA_COUNT = 20; // Number of data words to send
localparam SLOW_CLK_PERIOD = 20; // 50 MHz
localparam FAST_CLK_PERIOD = 10; // 100 MHz

// Clock and reset signals
reg clk_slow;
reg clk_fast;
reg rst_n;

// Test data generation
reg [DATA_WIDTH-1:0] test_data [0:TEST_DATA_COUNT-1];
integer data_index = 0;
reg test_complete = 0;

// Common input signals
reg valid_slow;
reg [DATA_WIDTH-1:0] data_in;
reg ready_fast;

// FIFO synchronizer signals
wire ready_slow_fifo;
wire valid_fast_fifo;
wire [DATA_WIDTH-1:0] data_out_fifo;

// Request-Acknowledge synchronizer signals
wire ready_slow_req_ack;
wire valid_fast_req_ack;
wire [DATA_WIDTH-1:0] data_out_req_ack;

// Performance metrics
time fifo_start_time[0:TEST_DATA_COUNT-1];
time fifo_end_time[0:TEST_DATA_COUNT-1];
time req_ack_start_time[0:TEST_DATA_COUNT-1];
time req_ack_end_time[0:TEST_DATA_COUNT-1];

real fifo_transfer_times[0:TEST_DATA_COUNT-1];
real req_ack_transfer_times[0:TEST_DATA_COUNT-1];
real avg_fifo_time;
real avg_req_ack_time;

// Instantiate FIFO synchronizer
fifo_synch #(
    .SYNCH_FF_LENGHT(SYNCH_FF_LENGHT),
    .DATA_WIDTH(DATA_WIDTH),
    .PTR_WIDTH(PTR_WIDTH)
) fifo_dut (
    .i_rst(rst_n),
    
    // Slow clock domain (write)
    .i_clk_a(clk_slow),
    .i_valid_clk_a(valid_slow),
    .o_ready_clk_a(ready_slow_fifo),
    .i_data_clk_a(data_in),
    
    // Fast clock domain (read)
    .i_clk_b(clk_fast),
    .o_valid_clk_b(valid_fast_fifo),
    .i_ready_clk_b(ready_fast),
    .o_data_clk_b(data_out_fifo)
);

// Instantiate Request-Acknowledge synchronizer
req_ack_synch #(
    .SYNCH_FF_LENGHT(SYNCH_FF_LENGHT),
    .DATA_WIDTH(DATA_WIDTH)
) req_ack_dut (
    .i_rst(rst_n),
    
    // Slow clock domain (write)
    .i_clk_a(clk_slow),
    .i_valid_clk_a(valid_slow),
    .o_ready_clk_a(ready_slow_req_ack),
    .i_data_clk_a(data_in),
    
    // Fast clock domain (read)
    .i_clk_b(clk_fast),
    .o_valid_clk_b(valid_fast_req_ack),
    .i_ready_clk_b(ready_fast),
    .o_data_clk_b(data_out_req_ack)
);

// Clock generation
initial begin
    clk_slow = 0;
    forever #(SLOW_CLK_PERIOD/2) clk_slow = ~clk_slow;
end

initial begin
    clk_fast = 0;
    forever #(FAST_CLK_PERIOD/2) clk_fast = ~clk_fast;
end

// Reset generation
initial begin
    rst_n = 0;
    #50 rst_n = 1;
end

// Test data generation
initial begin
    for(int i = 0; i < TEST_DATA_COUNT; i++) begin
        test_data[i] = $random; // Generate random test data
    end
end

// Stimulus generation
initial begin
    valid_slow = 0;
    data_in = 0;
    
    // Wait for reset to complete
    @(posedge rst_n);
    repeat(5) @(posedge clk_slow);
    
    // Send data through both synchronizers
    for(data_index = 0; data_index < TEST_DATA_COUNT; data_index++) begin
        // Wait for both synchronizers to be ready
        wait(ready_slow_fifo && ready_slow_req_ack);
        @(posedge clk_slow);
        
        // Apply data and valid signal
        valid_slow = 1;
        data_in = test_data[data_index];
        
        // Record start times
        fifo_start_time[data_index] = $time;
        req_ack_start_time[data_index] = $time;
        
        // Wait for handshake to complete
        @(posedge clk_slow);
        valid_slow = 0;
        
        // Wait before sending next data
        repeat(2) @(posedge clk_slow);
    end
    
    // Wait for all transfers to complete
    wait(data_index == TEST_DATA_COUNT && test_complete);
    
    // Calculate and display results
    calculate_results();
    $display("Test complete!");
    $finish;
end

// Response monitoring for FIFO
always @(posedge clk_fast) begin
    if(valid_fast_fifo && ready_fast) begin
        for(int i = 0; i < TEST_DATA_COUNT; i++) begin
            if(data_out_fifo == test_data[i] && fifo_end_time[i] == 0) begin
                fifo_end_time[i] = $time;
                $display("FIFO: Data %d received at time %t", i, $time);
                break;
            end
        end
    end
end

// Response monitoring for REQ-ACK
always @(posedge clk_fast) begin
    if(valid_fast_req_ack && ready_fast) begin
        for(int i = 0; i < TEST_DATA_COUNT; i++) begin
            if(data_out_req_ack == test_data[i] && req_ack_end_time[i] == 0) begin
                req_ack_end_time[i] = $time;
                $display("REQ-ACK: Data %d received at time %t", i, $time);
                break;
            end
        end
    end
end

// Ready signal generation for fast clock domain
initial begin
    ready_fast = 0;
    
    // Wait for reset to complete
    @(posedge rst_n);
    repeat(10) @(posedge clk_fast);
    
    forever begin
        ready_fast = 1;
        @(posedge clk_fast);
        
        // Randomly deassert ready to introduce backpressure
        if($urandom_range(0, 10) < 3) begin
            ready_fast = 0;
            repeat($urandom_range(1, 3)) @(posedge clk_fast);
        end
    end
end

// Check if all data has been received
always @(posedge clk_fast) begin
    if (!test_complete) begin
        test_complete = 1;
        for(int i = 0; i < TEST_DATA_COUNT; i++) begin
            if(fifo_end_time[i] == 0 || req_ack_end_time[i] == 0) begin
                test_complete = 0;
                break;
            end
        end
    end
end

// Task to calculate and display results
task calculate_results();
    real total_fifo_time = 0;
    real total_req_ack_time = 0;
    
    for(int i = 0; i < TEST_DATA_COUNT; i++) begin
        fifo_transfer_times[i] = fifo_end_time[i] - fifo_start_time[i];
        req_ack_transfer_times[i] = req_ack_end_time[i] - req_ack_start_time[i];
        
        total_fifo_time += fifo_transfer_times[i];
        total_req_ack_time += req_ack_transfer_times[i];
        
        $display("Data %d: FIFO transfer time = %0.2f ns, REQ-ACK transfer time = %0.2f ns", 
                 i, fifo_transfer_times[i], req_ack_transfer_times[i]);
    end
    
    avg_fifo_time = total_fifo_time / TEST_DATA_COUNT;
    avg_req_ack_time = total_req_ack_time / TEST_DATA_COUNT;
    
    $display("\nAverage FIFO transfer time: %0.2f ns", avg_fifo_time);
    $display("Average REQ-ACK transfer time: %0.2f ns", avg_req_ack_time);
    $display("Difference: %0.2f ns (%0.2f%%)", 
             avg_req_ack_time - avg_fifo_time,
             ((avg_req_ack_time - avg_fifo_time) / avg_fifo_time) * 100);
endtask

endmodule