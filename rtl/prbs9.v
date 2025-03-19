`timescale 1ns/1ps


module prbs9 #(
    parameter SEED = 9'h1FF 
)
(
    output  o_new_bit, 
    
    input   i_ctrl   ,
    input   i_reset  , 
    input   clk       
);
  
  // 9-bit shift register for PRBS generation
  reg [8:0] shiftreg;
  
  
  // PRBS bit generation using XOR feedback
  always @(posedge clk) begin
    if (i_reset==1'b1) begin
        shiftreg <= SEED;
    end
    else begin
        if (i_ctrl==1'b1) begin
            shiftreg <= {shiftreg[7:0], shiftreg[8]^shiftreg[4]};
        end
        else begin
            shiftreg <= shiftreg;
        end
    end
  end
  
  
  // Output assignment: PRBS9 sequence bit
  assign o_new_bit = shiftreg[8];
  
  
endmodule

