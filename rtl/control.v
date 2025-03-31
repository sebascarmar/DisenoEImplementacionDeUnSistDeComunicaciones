//`timescale 1ns/1ps


//module control (
//    output [1:0] o_counter          ,
//    output       o_count_max        ,
//    output       o_count_half_or_max,
    
//    input        i_reset            , 
//    input        clk       
//);
  
//  // Internal registers
//  reg [1:0] r_counter          ;
//  reg       r_count_max        ;    
//  reg       r_count_half_or_max;    

//  // Counter
//  always @(posedge clk) begin: control
//    if (i_reset==1'b1) begin
//        r_counter           <= 2'b10;
//        r_count_max         <= 1'b0;
//        r_count_half_or_max <= 1'b0;
//    end
//    else begin
//        // Counter increments until 2'b11, then resets to 2'b00 for polyphase filter control
//        if (r_counter<2'b11) begin
//            r_counter <= r_counter + 2'b01;
//        end
//        else begin
//            r_counter <= 2'b00;
//        end
       
//        // r_count_max is HIGH when r_counter is 2'b11 due to register delay.
//        r_count_max <= (r_counter==2'b10) ? 1'b1 : 1'b0;
       
//        // count_half_or_max is HIGH when count is 2'b01 or 2'b11
//        r_count_half_or_max <= (r_counter==2'b01 || r_counter==2'b11) ? 1'b1 : 1'b0;
       
//    end
//  end
  
  
//  // Output asignation
//  assign o_counter           = r_counter;
//  assign o_count_max         = r_count_max    ;
//  assign o_count_half_or_max = r_count_half_or_max;

// endmodule




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
  reg       r_count_max        ;    
  reg       r_count_half_or_max;    
  reg       r_count_max_rate1  ;
  //reg       r_save_fse_shifters;

  // Counter
  always @(posedge clk) begin: control
    if (i_reset==1'b1) begin
        r_counter           <= 2'b10;
        r_count_max         <= 1'b0;
        r_count_half_or_max <= 1'b0;
        r_count_max_rate1 <= 1'b0;
        //r_save_fse_shifters <= 1'b0;
    end
    else begin
        // Counter increments until 2'b11, then resets to 2'b00 for polyphase filter control
        if (r_counter<2'b11) begin
            r_counter <= r_counter + 2'b01;
        end
        else begin
            r_counter <= 2'b00;
        end
       
        // r_count_max is HIGH when r_counter is 2'b11 due to register delay.
        r_count_max <= (r_counter==2'b10) ? 1'b1 : 1'b0;
       
        // count_half_or_max is HIGH when count is 2'b01 or 2'b11
        r_count_half_or_max <= (r_counter==2'b01 || r_counter==2'b11) ? 1'b1 : 1'b0;
        //r_count_half_or_max <= (r_counter==2'b00 || r_counter==2'b10) ? 1'b1 : 1'b0;
         
        r_count_max_rate1 <= (r_counter==2'b01) ? 1'b1 : 1'b0;      
        
        
        //r_save_fse_shifters <= (r_counter==2'b11) ? 1'b1 : 1'b0;
    end
  end
  
  
  // Output asignation
  assign o_counter           = r_counter;
  assign o_count_max         = r_count_max    ;
  assign o_count_half_or_max = r_count_half_or_max;
  assign o_count_max_rate1   = r_count_max_rate1;
  //assign o_count_max_rate1   = r_count_max;
  assign o_save_fse_shifters = r_count_max;

 endmodule

