`timescale 1ns/1ps

module control
 (
    output [1:0] o_count    ,
    output       o_count_max,
    
    input        i_reset    , 
    input        clk       
 );
    
    // REGISTROS 
    reg [1:0] counter;
    reg       max    ;    

    // CONTADOR
    always @(posedge clk) begin: control
      if (i_reset==1'b1) begin
          counter <= 2'b10;
          max     <= 1'b0;
      end
      else begin
          if (counter<2'b11) begin
              counter <= counter + 2'b01;
          end
          else begin
              counter <= 2'b00;
          end
         
          if (counter==2'b10) begin
              max     <= 1'b1;
          end
          else begin
              max     <= 1'b0;
          end
         
      end
    end
    
    
    // ASIGNACIÓN DE SALIDAS
    assign o_count_max = max;
    assign o_count     = counter;


 endmodule
