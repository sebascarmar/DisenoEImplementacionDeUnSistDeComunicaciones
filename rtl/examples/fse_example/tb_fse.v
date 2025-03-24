`timescale 1ns/1ps

module tb_fse;

  // Parameters
  parameter NUM_TAPS = 11;
  parameter NBT_IN   =  8;
  parameter NBF_IN   =  7;
  parameter NBT_TAPS = 28;
  parameter NBF_TAPS = 25;
  parameter NBT_OUT  = 12;
  parameter NBF_OUT  =  9;

  // Signals
  reg clk;
  reg i_reset;
  reg i_en;
  reg signed [NBT_IN-1:0] i_is_data_I;
  reg signed [NBT_IN-1:0] i_is_data_Q;
  reg signed [(NUM_TAPS*NBT_TAPS)-1:0] i_taps_I;
  reg signed [(NUM_TAPS*NBT_TAPS)-1:0] i_taps_Q;
  
  wire signed [NBT_OUT-1:0] o_os_data_I;
  wire signed [NBT_OUT-1:0] o_os_data_Q;




  // Instantiate DUT
  fse #(
    .NUM_TAPS(NUM_TAPS),
    .NBT_IN(NBT_IN),
    .NBF_IN(NBF_IN),
    .NBT_TAPS(NBT_TAPS),
    .NBF_TAPS(NBF_TAPS),
    .NBT_OUT(NBT_OUT),
    .NBF_OUT(NBF_OUT)
  ) dut (
    .clk(clk),
    .i_reset(i_reset),
    .i_en(i_en),
    .i_is_data_I(i_is_data_I),
    .i_is_data_Q(i_is_data_Q),
    .i_taps_I(i_taps_I),
    .i_taps_Q(i_taps_Q),
    .o_os_data_I(o_os_data_I),
    .o_os_data_Q(o_os_data_Q)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Test sequence
  initial begin
    clk = 0;
    i_reset = 1;
    i_en = 0;
    i_is_data_I = 0;
    i_is_data_Q = 0;
    i_taps_I = 308'h00000000000000000000000000000000000200000000000000000000000000000000000000000;
    i_taps_Q = 308'h0;


    // Reset pulse
    #100;
    i_reset = 0;
    
    // Ciclo 0
    #15; i_en = 1;
         i_is_data_I = 8'sd0;
         i_is_data_Q = 8'sd0;
         i_taps_I = 308'h00000000000000000000000000000000000200000000000000000000000000000000000000000;
         i_taps_Q = 308'h0;
    // Ciclo 1
    #10; i_en = 0;
         i_is_data_I = 8'sd0;
         i_is_data_Q = 8'sd0;
         i_taps_I = 308'h00000000000000000000000000000000000200000000000000000000000000000000000000000;
         i_taps_Q = 308'h0;

    // Ciclo 2
    #10; i_en = 1;
         i_is_data_I = 8'sd0;
         i_is_data_Q = 8'sd0;
         i_taps_I = 308'h000000000000000000000000000000000001fffff000000000000000000000000000000000000;
         i_taps_Q = 308'h0;
    // Ciclo 3
    #10; i_en = 0;
         i_is_data_I = 8'sd0;
         i_is_data_Q = 8'sd0;
         i_taps_I = 308'h000000000000000000000000000000000001fffff000000000000000000000000000000000000;
         i_taps_Q = 308'h0;


    // Ciclo 4
    #10; i_en = 1;
         i_is_data_I = 8'sd0;
         i_is_data_Q = 8'sd0;
         i_taps_I = 308'h000000000000000000000000000000000001fffff000000000000000000000000000000000000;
         i_taps_Q = 308'h0;
    // Ciclo 5
    #10; i_en = 0;
         i_is_data_I = 8'sd0;
         i_is_data_Q = 8'sd0;
         i_taps_I = 308'h000000000000000000000000000000000001fffff000000000000000000000000000000000000;
         i_taps_Q = 308'h0;


    // Ciclo 6
    #10; i_en = 1;
         i_is_data_I = 8'sd255; //-0.0078125
         i_is_data_Q = 8'sd255;
         i_taps_I = 308'h000000000000000000000000000000000001ffffe000000000000000000000000000000000000;
         i_taps_Q = 308'h0;
    // Ciclo 7
    #10; i_en = 0;
         i_is_data_I = 8'sd255; //-0.0078125
         i_is_data_Q = 8'sd255;
         i_taps_I = 308'h000000000000000000000000000000000001ffffe000000000000000000000000000000000000;
         i_taps_Q = 308'h0;


    // Ciclo 8
    #10; i_en = 1;
         i_is_data_I = 8'sd0; //0
         i_is_data_Q = 8'sd0;
         i_taps_I = 308'h000000000000000000000000000000000001ffffe000000000000000000000000000000000000;
         i_taps_Q = 308'h0;
    // Ciclo 9
    #10; i_en = 0;
         i_is_data_I = 8'sd0; //0
         i_is_data_Q = 8'sd0;
         i_taps_I = 308'h000000000000000000000000000000000001ffffe000000000000000000000000000000000000;
         i_taps_Q = 308'h0;


    // Ciclo 10
    #10; i_en = 1;
         i_is_data_I = 8'sd0; //0
         i_is_data_Q = 8'sd0;
         i_taps_I = 308'h000000000000000000000000000000000001ffffd0000000000000000000000fffff000000000;
         i_taps_Q = 308'h0;
    // Ciclo 11
    #10; i_en = 0;
         i_is_data_I = 8'sd0; //0
         i_is_data_Q = 8'sd0;
         i_taps_I = 308'h000000000000000000000000000000000001ffffd0000000000000000000000fffff000000000;
         i_taps_Q = 308'h0;


    // Ciclo 12
    #10; i_en = 1;
         i_is_data_I = 8'sd0;
         i_is_data_Q = 8'sd0;
         i_taps_I = 308'h000000000000000000000000000000000001ffffd0000000000000000000000fffff000000000;
         i_taps_Q = 308'h0;
    // Ciclo 13
    #10; i_en = 0;
         i_is_data_I = 8'sd0;
         i_is_data_Q = 8'sd0;
         i_taps_I = 308'h000000000000000000000000000000000001ffffd0000000000000000000000fffff000000000;
         i_taps_Q = 308'h0;


    // Ciclo 14
    #10; i_en = 1;
         i_is_data_I = 8'sd254;// -0.015625
         i_is_data_Q = 8'sd254;
         i_taps_I = 308'h000000000000000000000000000000000001ffffc00000000fffff000000000fffff000000000;
         i_taps_Q = 308'h0;
    // Ciclo 15
    #10; i_en = 0;
         i_is_data_I = 8'sd254;// -0.015625
         i_is_data_Q = 8'sd254;
         i_taps_I = 308'h000000000000000000000000000000000001ffffc00000000fffff000000000fffff000000000;
         i_taps_Q = 308'h0;


    // Ciclo 16
    #10; i_en = 1;
         i_is_data_I = 8'sd252;// -0.03125
         i_is_data_Q = 8'sd252;
         i_taps_I = 308'h000000000000000000000000000000000001ffffc00000000fffff000000000fffff000000000;
         i_taps_Q = 308'h0;
    // Ciclo 17
    #10; i_en = 0;
         i_is_data_I = 8'sd252;// -0.03125
         i_is_data_Q = 8'sd252;
         i_taps_I = 308'h000000000000000000000000000000000001ffffc00000000fffff000000000fffff000000000;
         i_taps_Q = 308'h0;


    // Ciclo 18
    #10; i_en = 1;
         i_is_data_I = 8'sd1;
         i_is_data_Q = 8'sd1;
         i_taps_I = 308'h0000000000000000000000000000000000020000ae0000000fffff00000000000000fc00003f8;
         i_taps_Q = 308'h0;
    // Ciclo 19
    #10; i_en = 0;
         i_is_data_I = 8'sd1;
         i_is_data_Q = 8'sd1;
         i_taps_I = 308'h0000000000000000000000000000000000020000ae0000000fffff00000000000000fc00003f8;
         i_taps_Q = 308'h0;


    // Ciclo 20
    #10; i_en = 1;
         i_is_data_I = 8'sd13;// 0.1015625
         i_is_data_Q = 8'sd13;
         i_taps_I = 308'h0000000000000000000000000000000000020000ae0000000fffff00000000000000fc00003f8;
         i_taps_Q = 308'h0;
    // Ciclo 21
    #10; i_en = 0;
         i_is_data_I = 8'sd13;// 0.1015625
         i_is_data_Q = 8'sd13;
         i_taps_I = 308'h0000000000000000000000000000000000020000ae0000000fffff00000000000000fc00003f8;
         i_taps_Q = 308'h0;


    // Ciclo 22
    #10; i_en = 1;
         i_is_data_I = 8'sd24;// 0.1875
         i_is_data_Q = 8'sd24;
         i_taps_I = 308'h000000000000000000000fffff000000000200009d0000000ffffd00ffffc0000001fb00010f7;
         i_taps_Q = 308'h0;
    // Ciclo 23
    #10; i_en = 0;
         i_is_data_I = 8'sd24;// 0.1875
         i_is_data_Q = 8'sd24;
         i_taps_I = 308'h000000000000000000000fffff000000000200009d0000000ffffd00ffffc0000001fb00010f7;
         i_taps_Q = 308'h0;


    // Ciclo 24
    #10; i_en = 1;
         i_is_data_I = 8'sd32;// 0.25
         i_is_data_Q = 8'sd31;// 0.2421875
         i_taps_I = 308'h000000000000000000000fffff000000000200009d0000000ffffd00ffffc0000001fb00010f7;
         i_taps_Q = 308'h0;
    // Ciclo 25
    #10; i_en = 0;
         i_is_data_I = 8'sd32;// 0.25
         i_is_data_Q = 8'sd31;// 0.2421875
         i_taps_I = 308'h000000000000000000000fffff000000000200009d0000000ffffd00ffffc0000001fb00010f7;
         i_taps_Q = 308'h0;


    // Ciclo 26
    #10; i_en = 1;
         i_is_data_I = 8'sd35;// 0.2734375
         i_is_data_Q = 8'sd34;// 0.265625
         i_taps_I = 308'h000000000000fc0000000fffff000000000200028400003f0ffffc04fffef34fffea5affff1f4;
         i_taps_Q = 308'h0000000000000000000000000000000000000000000000000000000000000000000000fffff82;
    // Ciclo 27
    #10; i_en = 0;
         i_is_data_I = 8'sd35;// 0.2734375
         i_is_data_Q = 8'sd34;// 0.265625
         i_taps_I = 308'h000000000000fc0000000fffff000000000200028400003f0ffffc04fffef34fffea5affff1f4;
         i_taps_Q = 308'h0000000000000000000000000000000000000000000000000000000000000000000000fffff82;


    // Ciclo 28
    #10; i_en = 1;
         i_is_data_I = 8'sd28;// 0.21875
         i_is_data_Q = 8'sd30;// 0.234375
         i_taps_I = 308'h000000000000fc0000000fffff000000000200028400003f0ffffc04fffef34fffea5affff1f4;
         i_taps_Q = 308'h0000000000000000000000000000000000000000000000000000000000000000000000fffff82;
    // Ciclo 29
    #10; i_en = 0;
         i_is_data_I = 8'sd28;// 0.21875
         i_is_data_Q = 8'sd30;// 0.234375
         i_taps_I = 308'h000000000000fc0000000fffff000000000200028400003f0ffffc04fffef34fffea5affff1f4;
         i_taps_Q = 308'h0000000000000000000000000000000000000000000000000000000000000000000000fffff82;


    // Ciclo 29
    #10; i_en = 1;
         i_is_data_I = 8'sd8; // 0.0625
         i_is_data_Q = 8'sd13;// 0.1015625
         i_taps_I = 308'h000000000000fb0000000ffffd03ffffc06200037200010dc00013e00000e840000ca60000ec8;
         i_taps_Q = 308'h00000000000000000000000000000000000000000000000000000000000007f000007fffffe83;
    // Ciclo 30
    #10; i_en = 0;
         i_is_data_I = 8'sd8; // 0.0625
         i_is_data_Q = 8'sd13;// 0.1015625
         i_taps_I = 308'h000000000000fb0000000ffffd03ffffc06200037200010dc00013e00000e840000ca60000ec8;
         i_taps_Q = 308'h00000000000000000000000000000000000000000000000000000000000007f000007fffffe83;




    
    #100;
    
    // Finalizar simulación
    $stop;
  end

endmodule

