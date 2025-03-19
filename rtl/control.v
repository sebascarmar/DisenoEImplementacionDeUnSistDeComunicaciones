`timescale 1ns/1ps


module control (
    output [1:0] o_count    ,
    output       o_count_max,
    
    input        i_reset    , 
    input        clk       
);
  
  // Internal registers
  reg [1:0] counter;
  reg       max    ;    

  // Counter
  always @(posedge clk) begin: control
    if (i_reset==1'b1) begin
        counter <= 2'b10;
        max     <= 1'b0;
    end
    else begin
        // Counter increments until 2'b11, then resets to 2'b00 for polyphase filter control
        if (counter<2'b11) begin
            counter <= counter + 2'b01;
        end
        else begin
            counter <= 2'b00;
        end
       
        // max is HIGH when counter is 2'b11 due to register delay.
        if (counter==2'b10) begin
            max     <= 1'b1;
        end
        else begin
            max     <= 1'b0;
        end
       
    end
  end
  
  
  // Output asignation
  assign o_count_max = max    ;
  assign o_count     = counter;


 endmodule

