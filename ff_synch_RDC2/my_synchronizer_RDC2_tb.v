`timescale 1ns / 1ps

module my_synchronizer_RDC2_tb
(
);
 
 parameter DATA_WIDTH          = 1;       
 
 //------------ Configurable Parameters --------------------------------
 
 parameter SYMULATION_RES      = 1_000_000_000; //Symultion resolution
 
 parameter CLK_a_F_HZ          = 50_000_000;    //Clock freq in HZ
 parameter CLK_a_T             = SYMULATION_RES / CLK_a_F_HZ; 
 
 parameter CLK_b_F_HZ          = 80_000_000;    //Clock freq in HZ 
 parameter CLK_b_T             = SYMULATION_RES / CLK_b_F_HZ; 
 
      
 //simulation length in number of received data packets on virtual valid/ready receiver
 parameter SYM_LENGHT          = 100;
 
 //---------------------------------------------------------------------------
 integer packages_sent;
 integer date_sent;

 
 //--------------------------- Usable signals -------------------------------
 reg  rst;                           //global reset
 
 //Source clock:
 reg  clk_a;                         //source clock
                                     
 reg  data_a;                        //data to send
 wire next_data_clk_a;
                                     
 //Destiantion clock:                
 reg  clk_b;                         //destination clock
                                     
 wire data_clk_b;                    //recived data
 
 //----------------------- SANDBOX Start -------------------------------------
 
my_synchronizer_RDC2 my_synchronizer_RDC2_i
(
  .i_rst        (rst),
  
  .i_clk_a      (clk_a),

  .i_clk_b      (clk_b),

  .i_data_clk_a (data_a), 

  .o_data_clk_b (data_clk_b)

);
 
 assign next_data_clk_a = 1'b1;
 
 //----------------------- SANDBOX Stop -------------------------------------   
   
   initial //Main Inital
       begin
           clk_a = 1'b1;
           rst = 1'b0;
           data_a  = {DATA_WIDTH{1'b0}};
           packages_sent = 0;
           date_sent = 0;
           
           #(CLK_a_T * 3);
           rst = 1'b1;
       end  
   
   always #(CLK_a_T/2) clk_a = ~clk_a;
   
   
   
   always @(posedge clk_a)
    if (next_data_clk_a)
    begin
         
         date_sent = data_a;
         packages_sent = packages_sent + 1;
         
         $display("--------------------------SENDER---------------------------------");
         $display("Data pkg: %d send in domain A (Val in hex):    %h, at Time: %t", packages_sent, date_sent ,$time);
   
         data_a  <= my_rnd(0,2 **DATA_WIDTH);

         if (packages_sent == (SYM_LENGHT + 1)) 
           begin
               $display("");
               $display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
               $display("++++++++++++++++++ The simulation was completed successfully +++++++++++++++++++");
               $display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
               $finish;
           end           
    end           
           
   initial //Main Inital
       begin
           clk_b = 1'b1; 
       end       
   
   always #(CLK_b_T/2) clk_b = ~clk_b; //clock 
         
  
   
function integer my_rnd;
input integer min,max;
    begin
        if (min == max ) my_rnd = min;
        else my_rnd = ($unsigned($random) % (max-min)) + min;
    end
endfunction    
 
endmodule
