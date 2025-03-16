//==================================================================================
// Table of SNR to Variance values in S(8,7)
// --------------------------------------------------------------------------------
// SNR (dB)   Real Variance σ²   σ²×64 (hex value)   Representation S(8,7) (8 bits)
// --------------------------------------------------------------------------------
// 7         0.21875                 8'h1c            00011100
// 8         0.1953125               8'h19            00011001
// 9         0.171875                8'h16            00010110
// 10        0.15625                 8'h14            00010100
// 11        0.140625                8'h12            00010010
// 12        0.125                   8'h10            00010000
// --------------------------------------------------------------------------------
// Author: Daniel A. Juarez 
// Date: 10/01/2025
//==================================================================================


`timescale 1ns / 1ps

module tb_top_gng;
        
    parameter Z1_I         = 64'd5030521883283424767 ; // GNG seed I
    parameter Z2_I         = 64'd18445829279364155008; // GNG seed I
    parameter Z3_I         = 64'd18436106298727503359; // GNG seed I

    parameter Z1_Q         = 64'd14533118196545751551; // GNG seed Q
    parameter Z2_Q         = 64'd18444914485018758400; // GNG seed Q
    parameter Z3_Q         = 64'd18425749998705519615; // GNG seed Q

    parameter NBT_IN         = 8 ; // NB of output 
    parameter NBF_IN         = 7 ; // NBF of output
    parameter NBT_SIGMA      = 8 ; // NB of output 
    parameter NBF_SIGMA      = 7 ; // NBF of output   
    parameter NBT_NOISE      = 8 ; // NB of output
    parameter NBF_NOISE      = 7 ; // NBF of output     
    parameter NBT_NOISE_FRES = 24; // NB of output
    parameter NBF_NOISE_FRES = 18; // NBF of output 

    // Inputs                                      
    reg                                 i_clock       ; // System clock                 
    reg                                 i_reset       ; // Active low reset 
    reg   signed [     NBT_SIGMA-1 : 0] i_sigma       ;                         
    // Outputs    
    wire  signed [NBT_NOISE_FRES-1 : 0] o_noise_fres_Q; // Output noise full resolution, S(24,18)        
    wire  signed [NBT_NOISE_FRES-1 : 0] o_noise_fres_I; // Output noise full resolution, S(24,18)                                                                           
    wire  signed [NBT_NOISE-1 : 0]      o_noise_I     ; // Output noise, S(8,7)        
    wire  signed [NBT_NOISE-1 : 0]      o_noise_Q     ; // Output noise, S(8,7)    
    wire                                o_valid_I     ;
    wire                                o_valid_Q     ; 

    // Instanciación del módulo bajo prueba (UUT)
    top_gng #(

        .Z1_I          (Z1_I          ), // GNG seed I
        .Z2_I          (Z2_I          ), // GNG seed I
        .Z3_I          (Z3_I          ), // GNG seed I
        .Z1_Q          (Z1_Q          ), // GNG seed Q
        .Z2_Q          (Z2_Q          ), // GNG seed Q
        .Z3_Q          (Z3_Q          ), // GNG seed Q
        .NBT_IN        (NBT_IN        ), // NB of output 
        .NBF_IN        (NBF_IN        ), // NBF of output
        .NBT_SIGMA     (NBT_SIGMA     ), // NB of output 
        .NBF_SIGMA     (NBF_SIGMA     ), // NBF of output   
        .NBT_NOISE     (NBT_NOISE     ), // NB of output
        .NBF_NOISE     (NBF_NOISE     ), // NBF of output     
        .NBT_NOISE_FRES(NBT_NOISE_FRES), // NB of output
        .NBF_NOISE_FRES(NBF_NOISE_FRES) // NBF of output 
    )
    u_top_gng
    (                                      
        .i_clock       (i_clock       ), // System clock                 
        .i_reset       (i_reset       ), // Active low reset 
        .i_sigma       (i_sigma       ), // Input sigma                         
        .o_noise_fres_Q(o_noise_fres_Q), // Output noise full resolution, S(24,18)        
        .o_noise_fres_I(o_noise_fres_I), // Output noise full resolution, S(24,18)                                                                           
        .o_noise_I     (o_noise_I     ), // Output noise, S(8,7)        
        .o_noise_Q     (o_noise_Q     ), // Output noise, S(8,7)    
        .o_valid_I     (o_valid_I     ),
        .o_valid_Q     (o_valid_Q     )                               
    );


    //=================================================================
    //                      LOCAL PARAMETERS 
    //=================================================================

    // Stimulus generation
    integer i, j;
    // File handle
    integer file_noise_I;
    integer file_noise_Q;
    integer file_noise_fres_I;
    integer file_noise_fres_Q;

    parameter N_SIMU = (1000000*4); // Largo de simulación 
    reg signed [NBT_SIGMA-1:0] sigma_values [0:5];


    // Clock generation
    initial i_clock = 1'b0;
    always #5 i_clock = ~i_clock; // 100 MHz clock (10 ns period)

    initial begin
        // Initialization
        i_reset = 0;
        i_sigma = 0;
        // Reset the DUT
        #10;
        i_reset = 1'b0;
        #20;
        i_reset = 1'b1;

        // Initialize sigma values
        sigma_values[0]  = 8'sh1c; // SNR = 7
        sigma_values[1]  = 8'sh19; // SNR = 8
        sigma_values[2]  = 8'sh16; // SNR = 9
        sigma_values[3]  = 8'sh14; // SNR = 10
        sigma_values[4]  = 8'sh12; // SNR = 11
        sigma_values[5]  = 8'sh10; // SNR = 12


        // Sweep through sigma values
        for (j = 0; j < 6; j = j + 1) begin
            i_sigma = sigma_values[j];

            // Open files
            file_noise_I      = $fopen($sformatf("/home/danielito/Escritorio/run/GNG_Prototype/Modules/logs/noise_I_SNR_%0d.txt", j+7), "wb");
            file_noise_Q      = $fopen($sformatf("/home/danielito/Escritorio/run/GNG_Prototype/Modules/logs/noise_Q_SNR_%0d.txt", j+7), "wb");
            file_noise_fres_Q = $fopen($sformatf("/home/danielito/Escritorio/run/GNG_Prototype/Modules/logs/noise_fres_I_SNR_%0d.txt", j+7), "wb");
            file_noise_fres_I = $fopen($sformatf("/home/danielito/Escritorio/run/GNG_Prototype/Modules/logs/noise_fres_Q_SNR_%0d.txt", j+7), "wb");

                for (i = 0; i < N_SIMU; i = i + 1) begin

                    if(o_valid_Q & o_valid_I) begin 
                        $fwrite(file_noise_Q, "%d\n",      o_noise_Q     ); // Write to symbI
                        $fwrite(file_noise_I, "%d\n",      o_noise_I     ); // Write to symbQ
                        $fwrite(file_noise_fres_Q, "%d\n", o_noise_fres_Q); // Write noise Q
                        $fwrite(file_noise_fres_I, "%d\n", o_noise_fres_I); // Write noise I
                    end 
                    else begin 
                        $fwrite(file_noise_Q,      "%d\n", 8'd0  ); // Write to symbI
                        $fwrite(file_noise_I,      "%d\n", 8'd0  ); // Write to symbQ
                        $fwrite(file_noise_fres_Q, "%d\n", 24'd0 ); // Write noise Q
                        $fwrite(file_noise_fres_I, "%d\n", 24'd0 ); // Write noise I
                    end 
                     #10; // Wait one cycle
                end // fin for()


            $fclose(file_noise_Q); // Close symbI file
            $fclose(file_noise_I); // Close symbQ file
            $fclose(file_noise_fres_Q); // Close symbQ file
            $fclose(file_noise_fres_I); // Close symbQ file
        end // End of for(j)
        $finish;
    end 

endmodule




// `timescale 1 ns / 1 ps

// module tb_gng_top;

//     // Parameters
//     parameter Z1_I         = 64'd5030521883283424767 ; // GNG seed I
//     parameter Z2_I         = 64'd18445829279364155008; // GNG seed I
//     parameter Z3_I         = 64'd18436106298727503359; // GNG seed I

//     parameter Z1_Q         = 64'd14533118196545751551; // GNG seed Q
//     parameter Z2_Q         = 64'd18444914485018758400; // GNG seed Q
//     parameter Z3_Q         = 64'd18425749998705519615; // GNG seed Q

//     parameter NBT_IN         = 8 ;   // NB of output
//     parameter NBF_IN         = 7 ;   // NBF of output
//     parameter NBT_SYM_OUT    = 8 ;   // NB of output
//     parameter NBF_SYM_OUT    = 7 ;   // NBF of output     
//     parameter NBT_OUT_FULL   = 9 ;   // NB of output
//     parameter NBF_OUT_FULL   = 7 ;    // NBF of output

//     // Inputs       
//     reg                            i_clock_enable; // Clock enable     
//     reg       signed [NBT_IN-1:0]  i_sigma   ; // S(8,7)           
//     reg                            i_clock       ; // System clock     
//     reg                            i_reset       ; // Active low reset 
//     reg       signed [NBT_IN-1:0]  i_symbI       ; // Symbol I S(8,7)
//     reg       signed [NBT_IN-1:0]  i_symbQ       ; // Symbol Q S(8,7)
//    // Outputs    
//     wire signed [NBT_OUT_FULL-1:0] o_gn_full_symbQ; // Output data, S(26,17)        
//     wire signed [NBT_OUT_FULL-1:0] o_gn_full_symbI; // Output data, S(26,17)                                                                           
//     wire signed [NBT_SYM_OUT-1:0]  o_gn_symbI     ; // Symbol I with noise, S(8,7)        
//     wire signed [NBT_SYM_OUT-1:0]  o_gn_symbQ     ; // Symbol Q with noise, S(8,7)      
//     wire                           o_valid        ;   
                        
//     //=================================================================
//     //                      LOCAL PARAMETERS 
//     //=================================================================
//     // // Array declaration
//     // reg [NBT_IN-1:0] symbol_I [0:(1024*10)-1];
//     // reg [NBT_IN-1:0] symbol_Q [0:(1024*10)-1];
//     // reg signed [NB_DATA_GNG-1:0] sigma_multiplier;
// //    // Load data from files
// //    initial begin
// //        $readmemb("/home/danielito/Escritorio/run/GNG_Prototype/Modules/rtl/symbol_I.dat", symbol_I, 0, (1024*10)-1);
// //        $readmemb("/home/danielito/Escritorio/run/GNG_Prototype/Modules/rtl/symbol_Q.dat", symbol_Q, 0, (1024*10)-1);
// //    end

//     parameter N_LENGTH = (1957.0*511);
//     parameter N_SIMU = 1;

//     // Array declaration
//     reg [NBT_IN-1:0] symbol_I [0:(N_LENGTH)-1];
//     reg [NBT_IN-1:0] symbol_Q [0:(N_LENGTH)-1];

//     // Load data from files
//     initial begin
//         $readmemb("/home/danielito/Escritorio/Logueos/file_symbTxI.dat", symbol_I, 0, (N_LENGTH)-1);
//         $readmemb("/home/danielito/Escritorio/Logueos/file_symbTxQ.dat", symbol_Q, 0, (N_LENGTH)-1);
//     end


//     // DUT instantiation
//     top_gng
//     #(
//         .Z1_I        (Z1_I        ),
//         .Z2_I        (Z2_I        ),
//         .Z3_I        (Z3_I        ),
//         .Z1_Q        (Z1_Q        ),
//         .Z2_Q        (Z2_Q        ),
//         .Z3_Q        (Z3_Q        ),
//         .NBT_IN      (NBT_IN      ),
//         .NBF_IN      (NBF_IN      ),
//         .NBT_SYM_OUT (NBT_SYM_OUT ),   
//         .NBF_SYM_OUT (NBF_SYM_OUT ), 
//         .NBT_OUT_FULL(NBT_OUT_FULL),    
//         .NBF_OUT_FULL(NBF_OUT_FULL)
//     )
//     u_top_gng
//     (
//         .i_clock_enable (i_clock_enable ),
//         .i_sigma    (i_sigma    ),
//         .i_clock        (i_clock        ),
//         .i_reset        (i_reset        ),
//         .i_symbI        (i_symbI        ),
//         .i_symbQ        (i_symbQ        ),  
//         .o_gn_full_symbQ(o_gn_full_symbQ),
//         .o_gn_full_symbI(o_gn_full_symbI),                
//         .o_gn_symbI     (o_gn_symbI     ),
//         .o_gn_symbQ     (o_gn_symbQ     ),
//         .o_valid        (o_valid        )
//     );

//     // Clock generation
//     initial i_clock = 1'b0;
//     always #5 i_clock = ~i_clock; // 100 MHz clock (10 ns period)

//     // Stimulus generation
//     integer i, j, k;
//     reg [NBT_IN-1:0] sigma_values [0:12];

//     // File handle
//     integer file_noise_I;
//     integer file_noise_Q;
//     integer file_noise_fres_I;
//     integer file_noise_fres_Q;

//     initial begin
//         // Initialization
//         i_reset            = 0;
//         i_clock_enable     = 0;
//         i_sigma = 0;
//         i_symbI            = 0;
//         i_symbQ            = 0;

//         // Reset the DUT
//         #10;
//         i_reset = 1'b0;
//         #20;
//         i_reset = 1'b1;
//         #100;
//         i_clock_enable = 0;
//         #50
//         i_clock_enable = 1;

//         // Initialize sigma values
//         sigma_values[0]  = 8'h40;
//         sigma_values[1]  = 8'h33;
//         sigma_values[2]  = 8'h28;
//         sigma_values[3]  = 8'h20;
//         sigma_values[4]  = 8'h19;
//         sigma_values[5]  = 8'h14;
//         sigma_values[6]  = 8'h10;
//         sigma_values[7]  = 8'h0D;
//         sigma_values[8]  = 8'h0A;
//         sigma_values[9]  = 8'h08;
//         sigma_values[10] = 8'h06;
//         sigma_values[11] = 8'h05;
//         sigma_values[12] = 8'h04;

        

//         // Sweep through sigma values
//         for (j = 7; j <= 7; j = j + 1) begin
//             i_sigma = sigma_values[j];

//             // Open files
//             file_noise_I = $fopen($sformatf("/home/danielito/Escritorio/run/GNG_Prototype/Modules/logs/noise_I_SNR%0d.txt", j), "wb");
//             file_noise_Q = $fopen($sformatf("/home/danielito/Escritorio/run/GNG_Prototype/Modules/logs/noise_Q_SNR_%0d.txt", j), "wb");
//             file_noise_fres_Q = $fopen($sformatf("/home/danielito/Escritorio/run/GNG_Prototype/Modules/logs/noise_fres_I_SNR_%0d.txt", j), "wb");
//             file_noise_fres_I = $fopen($sformatf("/home/danielito/Escritorio/run/GNG_Prototype/Modules/logs/noise_fres_Q_SNR_%0d.txt", j), "wb");

//             // Verify file descriptors
//             if (file_symb_gnI == 0) begin
//                 $display("Error: Cannot open o_data_symb_I_SNR_%0d.txt", j);
//                 $finish; // End simulation if file cannot be opened
//             end     
//             if (file_symb_gnQ == 0) begin
//                 $display("Error: Cannot open o_data_symb_Q_SNR_%0d.txt", j);
//                 $finish; // End simulation if file cannot be opened
//             end
//             if (file_noise_fres_Q == 0) begin
//                 $display("Error: Cannot open o_gng_I_SNR_%0d.txt", j);
//                 $finish; // End simulation if file cannot be opened
//             end
//             if (file_noise_fres_I == 0) begin
//                 $display("Error: Cannot open o_gng_Q_SNR_%0d.txt", j);
//                 $finish; // End simulation if file cannot be opened
//             end

//             for (i = 0; i < N_SIMU; i = i + 1) begin
//                 for (k = 0; k < (N_LENGTH); k = k + 1) begin
//                     i_symbI = symbol_I[k];
//                     i_symbQ = symbol_Q[k];

//                     if (o_valid) begin
//                         $fwrite(file_symb_gnI  ,    "%d\n", o_gn_symbI); // Write to symbI
//                         $fwrite(file_symb_gnQ  ,    "%d\n", o_gn_symbQ); // Write to symbQ
//                         $fwrite(file_noise_fres_Q, "%d\n", o_gn_full_symbQ); // Write noise Q
//                         $fwrite(file_noise_fres_I, "%d\n", o_gn_full_symbI); // Write noise I
//                     end
//                     #10; // Wait one cycle
//                 end // End of for(i)
//             end 

//             $fclose(file_symb_gnI); // Close symbI file
//             $fclose(file_symb_gnQ); // Close symbQ file
//             $fclose(file_noise_fres_Q); // Close symbQ file
//             $fclose(file_noise_fres_I); // Close symbQ file
//         end // End of for(j)
//         $finish;
//     end 

// endmodule
