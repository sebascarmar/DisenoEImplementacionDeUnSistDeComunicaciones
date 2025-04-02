`timescale 1ns/1ps


module control (
    output [1:0] o_counter          ,
    output       o_count_max        ,
    output       o_count_half_or_max,
    output       o_count_max_rate1  ,
    output       o_save_fse_shifters,
    
    input        i_reset            , 
    input        clk       
);
  
  // Internal registers
  reg [1:0] r_counter          ;

  // Counter
  always @(posedge clk) begin: control
    if (i_reset==1'b1) begin
        r_counter <= 2'b10;
    end
    else begin
        // Counter increments until 2'b11, then resets to 2'b00 for polyphase filter control
        if (r_counter<2'b11) begin
            r_counter <= r_counter + 2'b01;
        end
        else begin
            r_counter <= 2'b00;
        end
    end
  end
  

  // Output asignation
  assign o_counter           = r_counter                                           ;
  assign o_count_max         = (r_counter==2'b11) ? 1'b1 : 1'b0                    ;
  assign o_count_half_or_max = (r_counter==2'b00 || r_counter==2'b10) ? 1'b1 : 1'b0;
  assign o_count_max_rate1   = (r_counter==2'b10) ? 1'b1 : 1'b0                    ;
  assign o_save_fse_shifters = (r_counter==2'b11) ? 1'b1 : 1'b0                    ;
  

 endmodule

