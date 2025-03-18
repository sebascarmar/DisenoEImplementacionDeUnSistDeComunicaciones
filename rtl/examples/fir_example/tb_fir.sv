`timescale 1ns/1ps
module tb_top_fir;

    // Parameters for configuration (must match those of the module)
    parameter NB_INPUT   = 8;
    parameter NBF_INPUT  = 7;
    parameter NB_OUTPUT  = 8;
    parameter NBF_OUTPUT = 7;
    parameter NB_COEFF   = 16;
    parameter NBF_COEFF  = 15;
    parameter N_COEFFS   = 17;
    parameter INIT_FILE  = "/home/danielito/Escritorio/run/FilterFIR/Modules/aaf_coeff.dat";

    // Test signals
    reg                                 i_clock         ;  
    reg                                 i_reset         ;
    reg                                 i_valid         ;
    reg  signed [NB_INPUT -1:0]         i_symb_I        ;
    reg  signed [NB_INPUT -1:0]         i_symb_Q        ;
    wire signed [NB_INPUT+NB_COEFF+4:0] o_fir_full_symbI;
    wire signed [NB_INPUT+NB_COEFF+4:0] o_fir_full_symbQ;    
    wire signed [NB_OUTPUT-1:0]         o_fir_symbI     ;
    wire signed [NB_OUTPUT-1:0]         o_fir_symbQ     ;
    
    // variables for loading input data
    reg [NB_INPUT-1:0] symbol_I [0:(1024*10)-1];
    reg [NB_INPUT-1:0] symbol_Q [0:(1024*10)-1];

    // varible for log output data
    integer i             ; 
    // file for the coefficients of the chanel
    integer file_symb_chI     ;
    integer file_symb_chQ     ;
    integer file_symb_full_chI;
    integer file_symb_full_chQ;
    // file for the coefficients of the Anti-aliasing filter
    integer file_symb_afI     ;
    integer file_symb_afQ     ;
    integer file_symb_full_afI;
    integer file_symb_full_afQ;



    // Load data from files
    initial begin
        $readmemb("/home/danielito/Escritorio/run/FilterFIR/Modules/symbI_out_Tx.txt", symbol_I, 0, (1024*10)-1);
        $readmemb("/home/danielito/Escritorio/run/FilterFIR/Modules/symbQ_out_Tx.txt", symbol_Q, 0, (1024*10)-1);
    end        

    // FIR filter instantiation
    top_fir #(
        .NB_INPUT  (NB_INPUT  ),
        .NBF_INPUT (NBF_INPUT ),
        .NB_OUTPUT (NB_OUTPUT ),
        .NBF_OUTPUT(NBF_OUTPUT),
        .NB_COEFF  (NB_COEFF  ),
        .NBF_COEFF (NBF_COEFF ),
        .N_COEFFS  (N_COEFFS  ),
        .INIT_FILE (INIT_FILE )
    ) dut_top_fir (
        .i_clock         (i_clock         ),
        .i_reset         (i_reset         ),
        .i_valid         (i_valid         ),
        .i_symb_I        (i_symb_I        ),
        .i_symb_Q        (i_symb_Q        ),
        .o_fir_full_symbI(o_fir_full_symbI),
        .o_fir_full_symbQ(o_fir_full_symbQ),        
        .o_fir_symbI     (o_fir_symbI     ),
        .o_fir_symbQ     (o_fir_symbQ     )
    );
    
    // 100 MHz clock generation: 10 ns period
    initial begin
        i_clock = 0;
        forever #5 i_clock = ~i_clock;  // clock toggles every 5 ns
    end
    

    initial begin
        // Initialization
        file_symb_chI      = $fopen("/home/danielito/Escritorio/run/FilterFIR/Modules/logs/symb_chI.txt"     , "wb");
        file_symb_chQ      = $fopen("/home/danielito/Escritorio/run/FilterFIR/Modules/logs/symb_chQ.txt"     , "wb");
        file_symb_full_chI = $fopen("/home/danielito/Escritorio/run/FilterFIR/Modules/logs/symb_full_chI.txt", "wb");
        file_symb_full_chQ = $fopen("/home/danielito/Escritorio/run/FilterFIR/Modules/logs/symb_full_chQ.txt", "wb");
        // file_symb_afI      = $fopen("/home/danielito/Escritorio/run/FilterFIR/Modules/logs/symb_afI.txt"     , "wb");
        // file_symb_afQ      = $fopen("/home/danielito/Escritorio/run/FilterFIR/Modules/logs/symb_afQ.txt"     , "wb");
        // file_symb_full_afI = $fopen("/home/danielito/Escritorio/run/FilterFIR/Modules/logs/symb_full_afI.txt", "wb");
        // file_symb_full_afQ = $fopen("/home/danielito/Escritorio/run/FilterFIR/Modules/logs/symb_full_afQ.txt", "wb");

        i_reset   = 1;   
        i_valid   = 0;
        i_symb_I  = 0;  
        i_symb_Q  = 0;  
        #20;
        i_reset = 0;
        // Enable the filter
        i_valid = 1;

        for (i = 0; i < (1024*10); i = i + 1) begin
            i_symb_I = symbol_I[i];
            i_symb_Q = symbol_Q[i];

            if (i_valid) begin
                #10;
                $fwrite(file_symb_chI     , "%b\n", o_fir_symbI   );
                $fwrite(file_symb_chQ     , "%b\n", o_fir_symbQ   );
                $fwrite(file_symb_full_chI, "%b\n", o_fir_full_symbI);
                $fwrite(file_symb_full_chQ, "%b\n", o_fir_full_symbQ);
                // $fwrite(file_symb_afI     , "%b\n", o_symb_afI     );
                // $fwrite(file_symb_afQ     , "%b\n", o_symb_afQ     );
                // $fwrite(file_symb_full_afI, "%b\n", o_symb_full_afI);
                // $fwrite(file_symb_full_afQ, "%b\n", o_symb_full_afQ);
            end
        end

        $fclose(file_symb_chI     );
        $fclose(file_symb_chQ     );
        $fclose(file_symb_full_chI);
        $fclose(file_symb_full_chQ);
        // $fclose(file_symb_afI     );
        // $fclose(file_symb_afQ     );
        // $fclose(file_symb_full_afI);
        // $fclose(file_symb_full_afQ);

        $finish;
    end
    
    // Signal monitoring
    initial begin
        $monitor("Time = %0t ns | i_symb_I = %0d | i_symb_Q = %0d | o_fir_symbI = %0d | o_fir_symbQ = %0d", $time, i_symb_I, i_symb_Q, o_fir_symbI, o_fir_symbQ);
    end

endmodule
