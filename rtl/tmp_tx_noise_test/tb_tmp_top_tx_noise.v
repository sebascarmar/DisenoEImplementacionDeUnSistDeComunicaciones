`timescale 1ns/1ps

module tb_tmp_top_tx_noise;
    // Parámetros
    parameter SEED_I        = 9'h1AA;
    parameter SEED_Q        = 9'h1FE;
    parameter NBT_OUT       = 8;
    parameter NBF_OUT       = 6;
    parameter NBT_COEF_TX   = 8;
    parameter NBF_COEF_TX   = 6;
    parameter NBTOT_DAT     = 8;
    parameter NBAUD         = 6;
    parameter OVERSAMP      = 4;
    parameter NOISE_SEED1_I = 64'd5030521883283424767;
    parameter NOISE_SEED2_I = 64'd18445829279364155008;
    parameter NOISE_SEED3_I = 64'd18436106298727503359;
    parameter NOISE_SEED1_Q = 64'd14533118196545751551;
    parameter NOISE_SEED2_Q = 64'd18444914485018758400;
    parameter NOISE_SEED3_Q = 64'd18425749998705519615;
    parameter SIGMA         = 8'sh1c;
    parameter NBT_SIGMA     = 8;
    parameter NBF_SIGMA     = 7;
    parameter NBT_NOISE     = 8;
    parameter NBF_NOISE     = 7;

    // Señales
    reg clk;
    reg i_reset;
    wire signed [NBT_OUT-1:0] symI_noisy;
    wire signed [NBT_OUT-1:0] symQ_noisy;
    
    // Instancia del módulo DUT
    tmp_top_tx_noise #(
        .SEED_I(SEED_I),
        .SEED_Q(SEED_Q),
        .NBT_OUT(NBT_OUT),
        .NBF_OUT(NBF_OUT),
        .NBT_COEF_TX(NBT_COEF_TX),
        .NBF_COEF_TX(NBF_COEF_TX),
        .NBTOT_DAT(NBTOT_DAT),
        .NBAUD(NBAUD),
        .OVERSAMP(OVERSAMP),
        .NOISE_SEED1_I(NOISE_SEED1_I),
        .NOISE_SEED2_I(NOISE_SEED2_I),
        .NOISE_SEED3_I(NOISE_SEED3_I),
        .NOISE_SEED1_Q(NOISE_SEED1_Q),
        .NOISE_SEED2_Q(NOISE_SEED2_Q),
        .NOISE_SEED3_Q(NOISE_SEED3_Q),
        .SIGMA(SIGMA),
        .NBT_SIGMA(NBT_SIGMA),
        .NBF_SIGMA(NBF_SIGMA),
        .NBT_NOISE(NBT_NOISE),
        .NBF_NOISE(NBF_NOISE)
    ) DUT (
        .symI_noisy(symI_noisy),
        .symQ_noisy(symQ_noisy),
        .i_reset(i_reset),
        .clk(clk)
    );

  integer file_ch_symI_noisy;
  integer file_ch_symQ_noisy;
  integer i                 ;
  integer n_logs = 4*1000000;

    // Generación de reloj
    always #5 clk = ~clk;

    // Estímulos
    initial begin
        file_ch_symI_noisy = $fopen("./../../../../../../tmp_tx_noise_test/scripts_py/file_ch_symI_noisy.txt", "wb");
        file_ch_symQ_noisy = $fopen("./../../../../../../tmp_tx_noise_test/scripts_py/file_ch_symQ_noisy.txt", "wb");
        clk = 0;
        i_reset = 0;
       
        #100;
        i_reset = 1;
        
        for (i = 0; i < n_logs; i = i + 1) begin
          $fwrite(file_ch_symI_noisy , "%d\n", symI_noisy);
          $fwrite(file_ch_symQ_noisy , "%d\n", symQ_noisy);
          #10; 
        end 
        
        $fclose(file_ch_symI_noisy);
        $fclose(file_ch_symQ_noisy);

        $finish;
    end
    
endmodule

