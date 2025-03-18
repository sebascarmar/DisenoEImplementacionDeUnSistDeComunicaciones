`timescale 1ns/1ps

module tb_tmp_top_tx;

  // Parámetros del módulo
  parameter SEED_I      = 9'h1AA;
  parameter SEED_Q      = 9'h1FE;
  parameter NBT_OUT     = 8;
  parameter NBF_OUT     = 6;
  parameter NBT_COEF_TX = 8;
  parameter NBF_COEF_TX = 6;
  parameter NBTOT_DAT   = 8;
  parameter NBAUD       = 5+1;
  parameter OVERSAMP    = 4;

  // Señales
  reg clk;
  reg i_reset;
  wire signed [NBT_OUT-1:0] out_from_tx_filtI_to_noiseI;
  wire signed [NBT_OUT-1:0] out_from_tx_filtQ_to_noiseQ;

  // Instanciación del DUT (Device Under Test)
  tmp_top_tx #(
    .SEED_I      (SEED_I),
    .SEED_Q      (SEED_Q),
    .NBT_OUT     (NBT_OUT),
    .NBF_OUT     (NBF_OUT),
    .NBT_COEF_TX (NBT_COEF_TX),
    .NBF_COEF_TX (NBF_COEF_TX),
    .NBTOT_DAT   (NBTOT_DAT),
    .NBAUD       (NBAUD),
    .OVERSAMP    (OVERSAMP)
  ) dut (
    .out_from_tx_filtI_to_noiseI(out_from_tx_filtI_to_noiseI),
    .out_from_tx_filtQ_to_noiseQ(out_from_tx_filtQ_to_noiseQ),
    .i_reset(i_reset),
    .clk(clk)
  );

  integer file_tx_symI_txf   ;
  integer file_tx_symQ_txf   ;
  integer i               ;
  integer n_logs = 4*1000000;

  // Generación del clock
  always #5 clk = ~clk;

  // Proceso de test
  initial begin
    // Inicialización
    file_tx_symI_txf = $fopen("./../../../../../../tmp_tx_test/scripts_py/file_tx_symI_txf.txt", "wb");
    file_tx_symQ_txf = $fopen("./../../../../../../tmp_tx_test/scripts_py/file_tx_symQ_txf.txt", "wb");
    clk     = 0;
    i_reset = 0;
    
    
    #100;
    i_reset = 1;
    
    
    for (i = 0; i < n_logs; i = i + 1) begin
      $fwrite(file_tx_symI_txf , "%d\n", out_from_tx_filtI_to_noiseI);
      $fwrite(file_tx_symQ_txf , "%d\n", out_from_tx_filtQ_to_noiseQ);
      #10; 
    end 
    
    $fclose(file_tx_symI_txf     );
    $fclose(file_tx_symQ_txf     );
    // Simulación durante 1000 ns
    
    $finish;
  end


endmodule

