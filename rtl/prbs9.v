`timescale 1ns/1ps

module prbs9
#(
    parameter SEED   = 9'h1FF 
 )
 (
    output  o_new_bit, 
    
    input   i_ctrl   ,
    input   i_reset  , 
    input   clk       
 );
    
    // REGISTRO DE DESPLAZAMIENTO DE 9 BITS 
    reg [8:0] shiftreg;
    
    
    // DESPLAZAMIENTO DEL REG. Y GENERACIÓN DE NUEVO BIT
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
    
    
    // ASIGNACIÓN DE LA SALIDA
    assign o_new_bit = shiftreg[8];
    
    
  endmodule
