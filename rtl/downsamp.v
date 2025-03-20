`timescale 1ns/1ps


module downsamp
#(
    parameter NBT_IN_OUT =  8, 
    parameter NBF_IN_OUT =  7
)
(
    output signed [NBT_IN_OUT-1:0] o_os_data,  // Output sample
    
    input  signed [NBT_IN_OUT-1:0] i_is_data , // Input sample
    input                          i_en      ,
    input                          i_reset   ,
    input                          clk       
);

  // Internal register
  reg  signed [NBT_IN_OUT-1:0] r_dwsamp;


  // Reset or update r_dwsamp based on i_reset and i_en signals
  always @(posedge clk) begin
    if (i_reset==1'b1) begin
        r_dwsamp <= {NBT_IN_OUT{1'b0}};
    end
    else begin
        r_dwsamp <= (i_en==1'b1) ? i_is_data : r_dwsamp;
    end
  end


  // Output asignation
  assign o_os_data = r_dwsamp;

endmodule

