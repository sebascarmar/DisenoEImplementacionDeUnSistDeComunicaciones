`timescale 1ns/1ps

module tb_ber;

  // Parámetros
  parameter PRBS_SEED_I     = 9'h1AA;
  parameter PRBS_SEED_Q     = 9'h1FE;
  parameter PRBS_MAX_CYCLES = 511;
  parameter START_SYN       = PRBS_MAX_CYCLES*690;
  parameter START_CNT       = START_SYN + 511*511;

  // Entradas
  reg i_rx_bit_I;
  reg i_rx_bit_Q;
  reg i_en_rate1;
  reg i_reset;
  reg clk;

  // Salidas
  wire o_ber_ok_led_I;
  wire o_ber_ok_led_Q;

  // Instanciación del módulo 'ber'
  ber #(
    .PRBS_SEED_I(PRBS_SEED_I),
    .PRBS_SEED_Q(PRBS_SEED_Q),
    .PRBS_MAX_CYCLES(PRBS_MAX_CYCLES),
    .START_SYN(START_SYN),
    .START_CNT(START_CNT)
  ) uut (
    .o_ber_ok_led_I(o_ber_ok_led_I),
    .o_ber_ok_led_Q(o_ber_ok_led_Q),
    .i_rx_bit_I(i_rx_bit_I),
    .i_rx_bit_Q(i_rx_bit_Q),
    .i_en_rate1(i_en_rate1),
    .i_reset(i_reset),
    .clk(clk)
  );

  // Generador de reloj
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // Genera reloj con periodo de 10ns
  end

   integer i                 ;
  // Inicialización y estímulos
  initial begin
    // Inicialización de señales
    i_rx_bit_I = 0;
    i_rx_bit_Q = 0;
    i_en_rate1 = 0;
    i_reset = 1;

    #15 i_reset = 0;  // Desactivar el reset

    for (i = 0; i < 650000; i = i + 1) begin
          i_en_rate1 = 1;
          #10; 
          i_en_rate1 = 0;
          #30;
        end 
    #14103600
    // Simulación de bits recibidos (esto es un ejemplo)
    #20 i_rx_bit_I = 1;
    #20 i_rx_bit_Q = 1;

    // Habilitar tasa 1
    #20 i_en_rate1 = 1;

    // Cambiar los bits recibidos
    #50 i_rx_bit_I = 0;
    #50 i_rx_bit_Q = 0;

    // Habilitar tasa 1 nuevamente
    #50 i_en_rate1 = 1;

    // Probar reset nuevamente
    #100 i_reset = 1;
    #10 i_reset = 0;

    // Finalizar la simulación después de un tiempo
    #200 $finish;
  end

  // Monitor de salida para verificar el comportamiento
  initial begin
    $monitor("Time = %0t, i_rx_bit_I = %b, i_rx_bit_Q = %b, i_en_rate1 = %b, o_ber_ok_led_I = %b, o_ber_ok_led_Q = %b", 
             $time, i_rx_bit_I, i_rx_bit_Q, i_en_rate1, o_ber_ok_led_I, o_ber_ok_led_Q);
  end

endmodule

