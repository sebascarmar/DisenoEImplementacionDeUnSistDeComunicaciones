`timescale 1ns/1ps

module tb_fir_test2;

    // Parámetros para igualar con el módulo
    parameter NUM_COEFF = 17;
    parameter FILE_COEFF = "/home/sebastian/Repositorios/CorreccionDeEfectosDeCanal/fixed_point/logs/coeffs_aafilt.dat";
    parameter NBT_IN    = 8;
    parameter NBF_IN    = 7;
    parameter NBT_COEFF = 8;
    parameter NBF_COEFF = 7;
    parameter NBT_OUT   = 8;
    parameter NBF_OUT   = 7;

    // Señales de entrada
    reg signed [NBT_IN-1:0] i_is_data;
    reg i_en;
    reg i_reset;
    reg clk;

    // Señales de salida
    wire signed [NBT_OUT-1:0] o_os_data;

    // Instanciación del módulo fir
    fir_filter #(
        .NUM_COEFF(NUM_COEFF),
        .FILE_COEFF(FILE_COEFF),
        .NBT_IN(NBT_IN),
        .NBF_IN(NBF_IN),
        .NBT_COEFF(NBT_COEFF),
        .NBF_COEFF(NBF_COEFF),
        .NBT_OUT(NBT_OUT),
        .NBF_OUT(NBF_OUT)
    ) dut (
        .o_os_data(o_os_data),
        .i_is_data(i_is_data),
        .i_en(i_en),
        .i_reset(i_reset),
        .clk(clk)
    );

    // Generación del reloj
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // Periodo de 10ns para el reloj
    end

    // Estímulos de entrada
    initial begin
        // Inicialización de señales
        i_is_data = 0;
        i_en = 1; // Comienza con reset activado
        i_reset = 1; // Comienza con reset activado

        #100; // Espera un poco
        // Desactiva el reset
        i_reset = 0;

        // Enviar datos de prueba
        i_is_data = 8'sh01; // Primer dato de entrada
        #10; // Espera para el siguiente ciclo

        i_is_data = 8'sh00; // Primer dato de entrada
        #10; // Espera para el siguiente ciclo

        i_is_data = -8'sh01; // Primer dato de entrada
        #10; // Espera para el siguiente ciclo

        i_is_data = -8'sh01; // Segundo dato de entrada
        #10; // Espera para el siguiente ciclo

        i_is_data = 8'sh04; // Tercer dato de entrada
        #10; // Espera para el siguiente ciclo

        i_is_data = 8'sh05; // Cuarto dato de entrada
        #10;

        i_is_data = 8'sh02; // Quinto dato de entrada
        #10;

        i_is_data = -8'sh06; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh10; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh1b; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh21; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh26; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh25; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh2a; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh25; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh12; // Sexto dato de entrada
        #10;

        i_is_data = 8'sh04; // Sexto dato de entrada
        #10;

        i_is_data = 8'sh1f; // Sexto dato de entrada
        #10;

        i_is_data = 8'sh2c; // Sexto dato de entrada
        #10;

        i_is_data = 8'sh1f; // Sexto dato de entrada
        #10;

        i_is_data = 8'sh01; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh20; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh2e; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh1c; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh02; // Sexto dato de entrada
        #10;

        i_is_data = 8'sh25; // Sexto dato de entrada
        #10;

        i_is_data = 8'sh28; // Sexto dato de entrada
        #10;

        i_is_data = 8'sh1d; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh01; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh1e; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh30; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh22; // Sexto dato de entrada
        #10;

        i_is_data = 8'sh02; // Sexto dato de entrada
        #10;

        i_is_data = 8'sh25; // Sexto dato de entrada
        #10;

        i_is_data = 8'sh20; // Sexto dato de entrada
        #10;

        i_is_data = 8'sh16; // Sexto dato de entrada
        #10;

        i_is_data = 8'sh08; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh26; // Sexto dato de entrada
        #10;

        i_is_data = -8'sh2a; // Sexto dato de entrada
        #10;
        
        i_is_data = -8'sh24; // Sexto dato de entrada
        #10;
        
        i_is_data = 8'sh0a; // Sexto dato de entrada
        #10;

        // Finalizar la simulación después de un tiempo
        #100;
        $finish;
    end


endmodule
