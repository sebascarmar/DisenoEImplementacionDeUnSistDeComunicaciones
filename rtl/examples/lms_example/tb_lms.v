`timescale 1ns/1ps

module tb_lms;

  // Parámetros del DUT
  parameter STEP     = 12'sh001;
  parameter LEAK     = 11'sh001;
  parameter NBT_STEP = 12;
  parameter NBF_STEP = 11;
  parameter NBT_LEAK = 11;
  parameter NBF_LEAK = 10;
  parameter NUM_TAPS = 11;
  parameter NBT_IN   = 8;
  parameter NBF_IN   = 7;
  parameter NBT_TAPS = 28;
  parameter NBF_TAPS = 25;
  parameter NBT_ERR  = 12;
  parameter NBF_ERR  = 9;

  // Señales de prueba
  reg signed [NBT_IN-1:0] i_is_data_I;
  reg signed [NBT_IN-1:0] i_is_data_Q;
  reg signed [NBT_ERR-1:0] i_err_I;
  reg signed [NBT_ERR-1:0] i_err_Q;
  reg i_en_shtr;
  reg i_en_taps;
  reg i_reset;
  reg clk;

  wire [(NUM_TAPS*NBT_TAPS)-1:0] o_taps_I;
  wire [(NUM_TAPS*NBT_TAPS)-1:0] o_taps_Q;

  // Instancia del DUT
  lms #(
    .STEP(STEP),
    .LEAK(LEAK),
    .NBT_STEP(NBT_STEP),
    .NBF_STEP(NBF_STEP),
    .NBT_LEAK(NBT_LEAK),
    .NBF_LEAK(NBF_LEAK),
    .NUM_TAPS(NUM_TAPS),
    .NBT_IN(NBT_IN),
    .NBF_IN(NBF_IN),
    .NBT_TAPS(NBT_TAPS),
    .NBF_TAPS(NBF_TAPS),
    .NBT_ERR(NBT_ERR),
    .NBF_ERR(NBF_ERR)
  ) dut (
    .o_taps_I(o_taps_I),
    .o_taps_Q(o_taps_Q),
    .i_is_data_I(i_is_data_I),
    .i_is_data_Q(i_is_data_Q),
    .i_err_I(i_err_I),
    .i_err_Q(i_err_Q),
    .i_en_shtr(i_en_shtr),
    .i_en_taps(i_en_taps),
    .i_reset(i_reset),
    .clk(clk)
  );

  // Generador de reloj
  always #5 clk = ~clk; // Periodo de 10 ns

  initial begin
    // Inicialización de señales
    clk = 0;
    i_reset = 1;
    i_en_shtr = 0;
    i_en_taps = 0;
    i_is_data_I = 0;
    i_is_data_Q = 0;
    i_err_I = 0;
    i_err_Q = 0;


    // Reset inicial
    #100;
    i_reset = 0;
    
    // Ciclo 0
    #15; i_en_shtr = 1;
         i_en_taps = 0;
         i_is_data_I = 8'sd0;
         i_is_data_Q = 8'sd0;
         i_err_I     = 12'sd1;
         i_err_Q     = 12'sd1;
    // Ciclo 1
    #10; i_en_shtr = 0;
         i_en_taps = 0;
         i_is_data_I = 8'sd0;
         i_is_data_Q = 8'sd0;
         i_err_I     = 12'sd1;
         i_err_Q     = 12'sd1;

    // Ciclo 2
    #10; i_en_shtr = 1;
         i_en_taps = 1;
         i_is_data_I = 8'sd0;
         i_is_data_Q = 8'sd0;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1
    // Ciclo 3
    #10; i_en_shtr = 0;
         i_en_taps = 0;
         i_is_data_I = 8'sd0;
         i_is_data_Q = 8'sd0;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1


    // Ciclo 4
    #10; i_en_shtr = 1;
         i_en_taps = 0;
         i_is_data_I = 8'sd0;
         i_is_data_Q = 8'sd0;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1
    // Ciclo 5
    #10; i_en_shtr = 0;
         i_en_taps = 0;
         i_is_data_I = 8'sd0;
         i_is_data_Q = 8'sd0;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1


    // Ciclo 6
    #10; i_en_shtr = 1;
         i_en_taps = 1;
         i_is_data_I = 8'sd255; //-0.0078125
         i_is_data_Q = 8'sd255;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1
    // Ciclo 7
    #10; i_en_shtr = 0;
         i_en_taps = 0;
         i_is_data_I = 8'sd255; //-0.0078125
         i_is_data_Q = 8'sd255;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1


    // Ciclo 8
    #10; i_en_shtr = 1;
         i_en_taps = 0;
         i_is_data_I = 8'sd0; //0
         i_is_data_Q = 8'sd0;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1
    // Ciclo 9
    #10; i_en_shtr = 0;
         i_en_taps = 0;
         i_is_data_I = 8'sd0; //0
         i_is_data_Q = 8'sd0;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1


    // Ciclo 10
    #10; i_en_shtr = 1;
         i_en_taps = 1;
         i_is_data_I = 8'sd0; //0
         i_is_data_Q = 8'sd0;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1
    // Ciclo 11
    #10; i_en_shtr = 0;
         i_en_taps = 0;
         i_is_data_I = 8'sd0; //0
         i_is_data_Q = 8'sd0;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1


    // Ciclo 12
    #10; i_en_shtr = 1;
         i_en_taps = 0;
         i_is_data_I = 8'sd0;
         i_is_data_Q = 8'sd0;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1
    // Ciclo 13
    #10; i_en_shtr = 0;
         i_en_taps = 0;
         i_is_data_I = 8'sd0;
         i_is_data_Q = 8'sd0;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1


    // Ciclo 14
    #10; i_en_shtr = 1;
         i_en_taps = 1;
         i_is_data_I = 8'sd254;// -0.015625
         i_is_data_Q = 8'sd254;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1
    // Ciclo 15
    #10; i_en_shtr = 0;
         i_en_taps = 0;
         i_is_data_I = 8'sd254;// -0.015625
         i_is_data_Q = 8'sd254;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1


    // Ciclo 16
    #10; i_en_shtr = 1;
         i_en_taps = 0;
         i_is_data_I = 8'sd252;// -0.03125
         i_is_data_Q = 8'sd252;
         i_err_I     = 12'sd508; // 0.9921875
         i_err_Q     = 12'sd508; 
    // Ciclo 17
    #10; i_en_shtr = 0;
         i_en_taps = 0;
         i_is_data_I = 8'sd252;// -0.03125
         i_is_data_Q = 8'sd252;
         i_err_I     = 12'sd508; // 0.9921875
         i_err_Q     = 12'sd508; 


    // Ciclo 18
    #10; i_en_shtr = 1;
         i_en_taps = 1;
         i_is_data_I = 8'sd1;// 0.0078125
         i_is_data_Q = 8'sd1;
         i_err_I     = 12'sd508; // 0.9921875
         i_err_Q     = 12'sd508; 
    // Ciclo 19
    #10; i_en_shtr = 0;
         i_en_taps = 0;
         i_is_data_I = 8'sd1;// 0.0078125
         i_is_data_Q = 8'sd1;
         i_err_I     = 12'sd508; // 0.9921875
         i_err_Q     = 12'sd508; 


    // Ciclo 20
    #10; i_en_shtr = 1;
         i_en_taps = 0;
         i_is_data_I = 8'sd13;// 0.1015625
         i_is_data_Q = 8'sd13;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1
    // Ciclo 21
    #10; i_en_shtr = 0;
         i_en_taps = 0;
         i_is_data_I = 8'sd13;// 0.1015625
         i_is_data_Q = 8'sd13;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1


    // Ciclo 22
    #10; i_en_shtr = 1;
         i_en_taps = 1;
         i_is_data_I = 8'sd24;// 0.1875
         i_is_data_Q = 8'sd24;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1
    // Ciclo 23
    #10; i_en_shtr = 0;
         i_en_taps = 0;
         i_is_data_I = 8'sd24;// 0.1875
         i_is_data_Q = 8'sd24;
         i_err_I     = 12'sd3584; // -1
         i_err_Q     = 12'sd3584; // -1


    // Ciclo 24
    #10; i_en_shtr = 1;
         i_en_taps = 0;
         i_is_data_I = 8'sd32;// 0.25
         i_is_data_Q = 8'sd31;// 0.2421875
         i_err_I     = 12'sd504; // 0.984375
         i_err_Q     = 12'sd504; // 0.984375
    // Ciclo 25
    #10; i_en_shtr = 0;
         i_en_taps = 0;
         i_is_data_I = 8'sd32;// 0.25
         i_is_data_Q = 8'sd31;// 0.2421875
         i_err_I     = 12'sd504; // 0.984375
         i_err_Q     = 12'sd504; // 0.984375


    // Ciclo 26
    #10; i_en_shtr = 1;
         i_en_taps = 1;
         i_is_data_I = 8'sd35;// 0.2734375
         i_is_data_Q = 8'sd34;// 0.265625
         i_err_I     = 12'sd504; // 0.984375
         i_err_Q     = 12'sd504; // 0.984375
    // Ciclo 27
    #10; i_en_shtr = 0;
         i_en_taps = 0;
         i_is_data_I = 8'sd35;// 0.2734375
         i_is_data_Q = 8'sd34;// 0.265625
         i_err_I     = 12'sd504; // 0.984375
         i_err_Q     = 12'sd504; // 0.984375


    // Ciclo 28
    #10; i_en_shtr = 1;
         i_en_taps = 0;
         i_is_data_I = 8'sd28;// 0.21875
         i_is_data_Q = 8'sd30;// 0.234375
         i_err_I     = 12'sd3587; // 0.-0.994140625
         i_err_Q     = 12'sd3587; // 0.-0.994140625
    // Ciclo 29
    #10; i_en_shtr = 0;
         i_en_taps = 0;
         i_is_data_I = 8'sd28;// 0.21875
         i_is_data_Q = 8'sd30;// 0.234375
         i_err_I     = 12'sd3587; // 0.-0.994140625
         i_err_Q     = 12'sd3587; // 0.-0.994140625


    // Ciclo 29
    #10; i_en_shtr = 1;
         i_en_taps = 1;
         i_is_data_I = 8'sd8; // 0.0625
         i_is_data_Q = 8'sd13;// 0.1015625
         i_err_I     = 12'sd3587; // 0.-0.994140625
         i_err_Q     = 12'sd3587; // 0.-0.994140625
    // Ciclo 30
    #10; i_en_shtr = 0;
         i_en_taps = 0;
         i_is_data_I = 8'sd8; // 0.0625
         i_is_data_Q = 8'sd13;// 0.1015625
         i_err_I     = 12'sd3587; // 0.-0.994140625
         i_err_Q     = 12'sd3587; // 0.-0.994140625




    
    #100;
    
    // Finalizar simulación
    $stop;
  end

endmodule



