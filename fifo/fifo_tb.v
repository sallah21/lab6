`timescale 1ns / 1ps

module fifo_tb
(
);
 
 //------------ Configurable Parameters --------------------------------
 
 parameter SYMULATION_RES      = 1_000_000_000; //Symultion resolution
 
 parameter CLK_a_F_HZ          = 80_000_000;    //Clock freq in HZ
 parameter CLK_a_T             = SYMULATION_RES / CLK_a_F_HZ; 
 
 parameter CLK_b_F_HZ          = 50_000_000;    //Clock freq in HZ 
 parameter CLK_b_T             = SYMULATION_RES / CLK_b_F_HZ; 
 
 parameter DATA_WIDTH          = 8;             //Data width of valid ready interface
 
 //simulation length in number of received data packets on virtual valid/ready receiver
 parameter SYM_LENGHT          = 100;
 
 //With these parameters you can set the rate of sending and receiving data 
 //on virtual interfaces valid ready
 
 //------------------------Virtual Sender--------------------------------------
 //Minimum delay in setting the “valid” signal after transmitting data in 
 //the virtual valid/ready transmitter in clock cycles A
 parameter MIN_DELAY_VALID_A   = 0;    
 //Maksimum delay in setting the “valid” signal after transmitting data in 
 //the virtual valid/ready transmitter in clock cycles A
 //If max equals min, the data will be sent at fixed non-random delays equal to “max”
 parameter MAX_DELAY_VALID_A   = 20;
 
 //------------------------Virtual Receiver------------------------------------
 //Minimum delay in setting the “ready” signal after receiving data in 
 //the virtual valid/ready receiver in clock cycles B
 parameter MIN_DELAY_READY_B   = 0;
 //Maksimum delay in setting the “ready” signal after receivimg data in 
 //the virtual valid/ready receiver in clock cycles B
 //If max equals min, the data will be received at fixed non-random delays equal to “max”
 parameter MAX_DELAY_READY_B   = 20;
 
 //---------------------------------------------------------------------------
 integer delay_a;
 integer delay_b;
 integer packages_sent;
 integer packages_recived;
 integer packages_sent_tab[SYM_LENGHT:0];
 integer date_sent;
 integer date_received;
 integer errors;
 
 //--------------------------- Usable signals -------------------------------
 //Global reset
 reg  rst;                           //global reset
 
 //Source clock:
 reg  clk_a;                         //source clock
                                     
 reg  valid_a;                       //virtual valid/ready sender signal "valid"
 wire ready_clk_a;                   //"ready" signal from our device
 reg [(DATA_WIDTH-1):0] data_a;      //virtual valid/ready sender signal "data"
                                     
 //Destiantion clock:                
 reg clk_b;                          //destination clock
                                     
 wire valid_clk_b;                   //"valid" signal from our device     
 reg  ready_clk_b;                   //virtual valid/ready reciver signal "ready"
 wire [(DATA_WIDTH-1):0] data_clk_b; //"data" from our device (valid/ready interface)
 
 //----------------------- SANDBOX Start -------------------------------------

fifo_synch #
(
    .DATA_WIDTH       (DATA_WIDTH),
    .SYNCH_FF_LENGTH  (2),
    .PTR_WIDTH        (3)
)
fifo_synch_i
(
  .i_rst           (rst),
  
  .i_clk_a         (clk_a),

  .i_valid_clk_a   (valid_a),
  .o_ready_clk_a   (ready_clk_a),
  .i_data_clk_a    (data_a),

  .i_clk_b         (clk_b),

  .o_valid_clk_b   (valid_clk_b),
  .i_ready_clk_b   (ready_clk_b),
  .o_data_clk_b    (data_clk_b)

);

 //----------------------- SANDBOX Stop -------------------------------------   
   
   initial //Main Inital
       begin
           clk_a = 1'b1;
           rst   = 1'b0;
           data_a  = {DATA_WIDTH{1'b0}};
           valid_a = 1;
           delay_a = 0;
           packages_sent = 0;
           packages_recived = 0;
           date_sent = 0;
           date_received = 0;
           errors = 0;
           
           #(CLK_a_T * 3);
           rst    = 1'b1;
       end  
   
   always #(CLK_a_T/2) clk_a = ~clk_a;
   
   
   
   always @(posedge clk_a)
    if (ready_clk_a & valid_a)
    begin
         valid_a <= 1'b0;
         
         date_sent = data_a;
         packages_sent = packages_sent + 1;
         packages_sent_tab[packages_sent] = date_sent;
         
         $display("--------------------------SENDER---------------------------------");
         $display("Data pkg: %d send in domain A (Val in hex):    %h, at Time: %t", packages_sent, date_sent ,$time);

         
         delay_a = my_rnd(MIN_DELAY_VALID_A,MAX_DELAY_VALID_A);
         $display("Delay in setting up signal valid (Testbench sender):  %d clock A cycles",delay_a);
         repeat (delay_a) @(posedge clk_a);
   
         valid_a <= 1'b1;
         data_a  <= my_rnd(0,2 **DATA_WIDTH);       
    end           
           
   initial //Main Inital
       begin
           clk_b = 1'b1;
           ready_clk_b = 1'b1;
           delay_b = 0;
       end       
   
   always #(CLK_b_T/2) clk_b = ~clk_b; //clock 
         
   always @(posedge clk_b)
    if (valid_clk_b & ready_clk_b)
     begin       
      ready_clk_b <= 1'b0;
      date_received = data_clk_b;
      packages_recived = packages_recived + 1;
      $display("--------------------------RECIVER---------------------------------");
      $display("Data pkg: %d recived in domain B (Val in hex): %h, at Time: %t", packages_recived, date_received ,$time);
      
      if (packages_sent_tab[packages_recived] == date_received)
        $display("Send: %h , Recived: %h ================================================================> OK", packages_sent_tab[packages_recived], date_received);
      else
        begin
            $display("Send: %h , Recived: %h ================================================================> ERROR!!!", packages_sent_tab[packages_recived], date_received);
            errors = errors + 1;
        end
      delay_b = my_rnd(MIN_DELAY_READY_B,MAX_DELAY_READY_B);
      $display("Delay in setting up signal ready (Testbench reciver): %d clock B cycles",delay_b);
      repeat (delay_b) @(posedge clk_b);
      ready_clk_b <= 1'b1;
      
      if (packages_recived == SYM_LENGHT) 
        begin
            $display("");
            $display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
            if (errors == 0)
                $display("++++++++++++++++++ The simulation was completed successfully +++++++++++++++++++");
            else
                $display("+++++++++++++++++ The simulation was completed with %d ERRORS",errors);
            $display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
            $finish;
        end    
     end    
   
function integer my_rnd;
input integer min,max;
    begin
        if (min == max ) my_rnd = min;
        else my_rnd = ($unsigned($random) % (max-min)) + min;
    end
endfunction    
 
endmodule
