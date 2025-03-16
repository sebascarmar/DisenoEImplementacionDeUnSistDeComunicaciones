//============================================================================================
//  GNG Top Module: This module takes the top of the IP-Core (gng) and multiplies its output
//                  by a variance equivalent to a certain SNR to obtain a scaled noise output.
//  Author: Daniel A. Juarez 
//  Date: 01/2025
// Instaciation:
// 
// top_gng
// #(
//     .Z1_I        ( ),
//     .Z2_I        ( ),
//     .Z3_I        ( ),
//     .Z1_Q        ( ),
//     .Z2_Q        ( ),
//     .Z3_Q        ( ),
//     .NBT_IN       ( ),
//     .NBF_IN      ( ),
//     .NBT_NOISE      ( ),   
//     .NBF_NOISE     ( ) 
//     .NBT_NOISE_FRES ( ),    
//     .NBF_NOISE_FRES( ),
// )
// u_top_gng
// (
//     .i_clock_enable ( ),
//     .i_sigma_mul    ( ),
//     .i_clock        ( ),
//     .i_reset        ( ),
//     .i_symbI        ( ),
//     .i_symbQ        ( ),   
//     .o_noise_fres_Q( ),
//     .o_noise_fres_I( ),       
//     .o_noise_I     ( ),
//     .o_noise_Q     ( )
// );
//============================================================================================

`timescale 1 ns / 1 ps

module top_gng #(

    parameter Z1_I         = 64'd5030521883283424767 , // GNG seed I
    parameter Z2_I         = 64'd18445829279364155008, // GNG seed I
    parameter Z3_I         = 64'd18436106298727503359, // GNG seed I

    parameter Z1_Q         = 64'd14533118196545751551, // GNG seed Q
    parameter Z2_Q         = 64'd18444914485018758400, // GNG seed Q
    parameter Z3_Q         = 64'd18425749998705519615, // GNG seed Q

    parameter NBT_IN         = 8 , // NB of output 
    parameter NBF_IN         = 7 , // NBF of output
    parameter NBT_SIGMA      = 8 , // NB of output 
    parameter NBF_SIGMA      = 7 , // NBF of output   
    parameter NBT_NOISE      = 8 , // NB of output
    parameter NBF_NOISE      = 7 , // NBF of output     
    parameter NBT_NOISE_FRES = 24, // NB of output
    parameter NBF_NOISE_FRES = 18  // NBF of output 
)
(
    // Inputs                                      
    input                                 i_clock       , // System clock                 
    input                                 i_reset       , // Active low reset 
    input   signed [     NBT_SIGMA-1 : 0] i_sigma       ,                         
    // Outputs    
    output  signed [NBT_NOISE_FRES-1 : 0] o_noise_fres_Q, // Output noise full resolution, S(24,18)        
    output  signed [NBT_NOISE_FRES-1 : 0] o_noise_fres_I, // Output noise full resolution, S(24,18)                                                                           
    output  signed [NBT_NOISE-1 : 0]      o_noise_I     , // Output noise, S(8,7)        
    output  signed [NBT_NOISE-1 : 0]      o_noise_Q     , // Output noise, S(8,7)    
    output                                o_valid_I     ,
    output                                o_valid_Q         
                              
);

    //======================================================================
    // local parameters
    //======================================================================
    localparam NBT_DATA_GNG   = 16                             ;  // NBT of data gng given by the IP-CORE 
    localparam NBI_NOISE_FRES = NBT_NOISE_FRES - NBF_NOISE_FRES;  // NBI noise fres -> 24-18 = 6
    localparam NBI_NOISE      = NBT_NOISE - NBF_NOISE          ;  // NBI noise -> 8-7 = 1
    localparam NB_SAT         = NBI_NOISE_FRES - NBI_NOISE     ;  // (24-18) - (8-7) = 5 


    //======================================================================
    // Generation of independent noise for I and Q
    //======================================================================
    // Instantiate two noise modules (gng)

    wire                             w_valid_gng_I;
    wire                             w_valid_gng_Q; 
    wire signed [NBT_DATA_GNG-1 : 0] w_gng_Q      ; // S(16,11)
    wire signed [NBT_DATA_GNG-1 : 0] w_gng_I      ; // S(16,11)

    // Scale the noise: S(16,11)*S(8,6) = S(24,18)
    wire signed [NBT_NOISE_FRES-1:0] w_noise_fres_I, w_noise_fres_Q;
    wire signed [     NBT_NOISE-1:0] noise_I, noise_Q              ;

    // Generate with Seed = 1
    gng#(
      .INIT_Z1(Z1_I), 
      .INIT_Z2(Z2_I), 
      .INIT_Z3(Z3_I)
    ) u_gng_I (
        .i_clock   (i_clock        ),
        .i_reset   (i_reset        ),
        .ce        (1'b1           ),
        .valid_out (w_valid_gng_I  ),
        .data_out  (w_gng_I        ) // S(16,11)
    );
    // Generate with Seed = 2    
    gng#(
      .INIT_Z1(Z1_Q), 
      .INIT_Z2(Z2_Q), 
      .INIT_Z3(Z3_Q)
    ) u_gng_Q (
        .i_clock   (i_clock        ),
        .i_reset   (i_reset        ),
        .ce        (1'b1           ),
        .valid_out (w_valid_gng_Q  ),
        .data_out  (w_gng_Q        )
    );

    assign w_noise_fres_I = w_gng_I * i_sigma; // S(24,18)
    assign w_noise_fres_Q = w_gng_Q * i_sigma; // S(24,18)

    // Asignacion de salidas full resolution 
    assign o_noise_fres_I = w_noise_fres_I;
    assign o_noise_fres_Q = w_noise_fres_Q;

    // Asignacion de salidas con saturacion y truncado S(24,18) -> S(8,7)  
    assign o_noise_I = ( ~|w_noise_fres_I[NBT_NOISE_FRES-1 -: NBI_NOISE_FRES] || &w_noise_fres_I[NBT_NOISE_FRES-1 -: NBI_NOISE_FRES] ) 
                         ? w_noise_fres_I[(NBT_NOISE_FRES-1)-NB_SAT -: NBT_NOISE] 
                         : ( (w_noise_fres_I[NBT_NOISE_FRES-1]) 
                              ? {1'b1, {NBT_NOISE-1{1'b0}}} 
                              : {1'b0, {NBT_NOISE-1{1'b1}}} );

    assign o_noise_Q = ( ~|w_noise_fres_Q[NBT_NOISE_FRES-1 -: NBI_NOISE_FRES] || &w_noise_fres_Q[NBT_NOISE_FRES-1 -: NBI_NOISE_FRES] ) 
                         ? w_noise_fres_Q[(NBT_NOISE_FRES-1)-NB_SAT -: NBT_NOISE] 
                         : ( (w_noise_fres_Q[NBT_NOISE_FRES-1]) 
                              ? {1'b1, {NBT_NOISE-1{1'b0}}} 
                              : {1'b0, {NBT_NOISE-1{1'b1}}} );

    assign o_valid_Q = w_valid_gng_Q; 
    assign o_valid_I = w_valid_gng_I;  

endmodule



    // noisy_sum#(
    //     .NBT_IN        (NBT_IN        ),  // NBT input symbol
    //     .NBF_IN        (NBF_IN        ),  // NBF input symbol
    //     .NBT_NOISE_FRES(NBT_NOISE_FRES),  // NB of output
    //     .NBF_NOISE_FRES(NBF_NOISE_FRES),  // NBF of output
    //     .NBT_NOISE     (NBT_NOISE     ),  // NBT of output
    //     .NBF_NOISE     (NBF_NOISE     ),  // NBF of output     
    //     .NBT_NOISE   (NBT_NOISE   ),  // NBT of output
    //     .NBF_NOISE   (NBF_NOISE   )   // NBF of output     
    // )
    // u_noisy_sum
    // (
    //     .i_tx_symI_txf       (i_symbI           ), // Input symb  S(8,7) 
    //     .i_tx_symQ_txf       (i_symbQ           ), // Input symb  S(8,7)   
    //     .i_noise_I           (noise_I           ), // Input noisy S(8,7) 
    //     .i_noise_Q           (noise_Q           ), // Input noisy S(8,7)
    //     .o_ch_symI_noisy_FRES(ch_symI_noisy_FRES), // output full resolution S(9,7)
    //     .o_ch_symQ_noisy_FRES(ch_symQ_noisy_FRES) // output full resolution S(9,7)
    //     // .o_ch_symI_noisy     (ch_symI_noisy     ), // output trunc and sat S(8,7)
    //     // .o_ch_symQ_noisy     (ch_symQ_noisy     )  // output trunc and sat S(8,7)
    // );





///////////////////////////////////////////////////////////////////////////////////////////////
// module top_gng #(
//     parameter Z1_I         = 64'd5030521883283424767 , // GNG seed I
//     parameter Z2_I         = 64'd18445829279364155008, // GNG seed I
//     parameter Z3_I         = 64'd18436106298727503359, // GNG seed I

//     parameter Z1_Q         = 64'd14533118196545751551, // GNG seed Q
//     parameter Z2_Q         = 64'd18444914485018758400, // GNG seed Q
//     parameter Z3_Q         = 64'd18425749998705519615, // GNG seed Q

//     parameter NBT_IN        = 8 ,   // NB of output
//     parameter NBF_IN        = 7 ,   // NBF of output
//     parameter NBT_NOISE       = 8 ,   // NB of output
//     parameter NBF_NOISE       = 7 ,   // NBF of output     
//     parameter NBT_NOISE_FRES   = 25,   // NB of output
//     parameter NBF_NOISE_FRES  = 17    // NBF of output

// )
// (
//     // Inputs       
//     input                               i_clock_enable, // Clock enable                 
//     input   signed [NBT_IN-1:0]         i_sigma_mul   , // Input sigma S(8,6)               
//     input                               i_clock       , // System clock                 
//     input                               i_reset       , // Active low reset             
//     input   signed [NBT_IN-1:0]         i_symbI       , // Symbol I S(8,6)              
//     input   signed [NBT_IN-1:0]         i_symbQ       , // Symbol Q S(8,6)              
//     // Outputs    
//     output  signed [NBT_NOISE_FRES-1 : 0]  o_noise_fres_Q, // Output data, S(26,17)        
//     output  signed [NBT_NOISE_FRES-1 : 0]  o_noise_fres_I, // Output data, S(26,17)                                                                           
//     output  signed [NBT_NOISE-1 : 0]      o_noise_I     , // Symbol I with noise, S(8,7)        
//     output  signed [NBT_NOISE-1 : 0]      o_noise_Q     , // Symbol Q with noise, S(8,7)    
//     output  signed                      o_valid    
                              
// );

//     //======================================================================
//     // local parameters
//     //======================================================================
//     localparam NBT_DATA_GNG  = 16          ;  // NB of data gng 
//     localparam NBF_DATA_GNG = 11          ;  // NBF of data gng    
//     localparam NBT_NOISE_FRES  = 24               ;  // NB of extended data
//     localparam NBF_NOISE_FRES = 17               ;  // NBF of extended data
//     localparam NBI_NOISE_FRES = NBT_NOISE_FRES - NBF_NOISE_FRES ;  // NBI of extended data -> 24-17 = 7  
//     localparam NBI_IN  = NBT_IN - NBF_IN  ;  // NBI of input data    -> 8-6 = 2
//     localparam NBI_SYM = NBT_NOISE - NBF_NOISE;  // NBI of output data   -> 8-6 = 2

//     // Parámetros para la suma y saturación S(8,6)
//     localparam NB_ADD     = NBT_NOISE_FRES + 1;             // 25 
//     localparam NBF_ADD    = NBF_NOISE_FRES;                // 17
//     localparam NBI_ADD    = NB_ADD - NBF_ADD;       // 27-17 = 10
//     localparam NBI = NBT_NOISE - NBF_NOISE;       // 8-7 = 1
//     localparam NB_SAT_NOISE     = (NB_ADD - NBF_ADD) - (NBT_NOISE - NBF_NOISE); // (27-17)-(8-7) = 9


//     //======================================================================
//     // Conversion of input symbols to S(24,17)
//     //======================================================================)
//     // Extend S(8,6) to S(24,17): add 5 sign bits and shift 11 bits.
//     wire signed [NBT_NOISE_FRES-1:0] i_symbI_correct, i_symbQ_correct;
//     assign i_symbI_correct = $signed({{(NBI_NOISE_FRES-NBI_IN){i_symbI[NBT_IN-1]}}, i_symbI, {(NBF_NOISE_FRES-NBF_IN){1'b0}}});
//     assign i_symbQ_correct = $signed({{(NBI_NOISE_FRES-NBI_IN){i_symbQ[NBT_IN-1]}}, i_symbQ, {(NBF_NOISE_FRES-NBF_IN){1'b0}}});
//                                         //(5+2)+(6+11) = 24 

//     //======================================================================
//     // Generation of independent noise for I and Q
//     //======================================================================
//     // Instantiate two noise modules (gng)
//     wire signed [NBT_DATA_GNG-1:0]   w_noisy_for_I;
//     wire signed [NBT_DATA_GNG-1:0]   w_noisy_for_Q;
//     wire                            w_valid_gng_I;
//     wire                            w_valid_gng_Q;

//     // Generate with Seed = 1
//     gng#(
//       .INIT_Z1(Z1_I), 
//       .INIT_Z2(Z2_I), 
//       .INIT_Z3(Z3_I)
//     ) u_gng_I (
//         .i_clock   (i_clock),
//         .i_reset   (i_reset),
//         .ce        (i_clock_enable),
//         .valid (w_valid_gng_I),
//         .data  (w_noisy_for_I)
//     );
//     // Generate with Seed = 2    
//     gng#(
//       .INIT_Z1(Z1_Q), 
//       .INIT_Z2(Z2_Q), 
//       .INIT_Z3(Z3_Q)
//     ) u_gng_Q (
//         .i_clock   (i_clock),
//         .i_reset   (i_reset),
//         .ce        (i_clock_enable),
//         .valid (w_valid_gng_Q),
//         .data  (w_noisy_for_Q)
//     );

//     // Scale the noise: S(16,11)*S(8,6) = S(24,17)
//     wire signed [NBT_NOISE_FRES-1:0] w_noise_fres_I, w_noise_fres_Q;
//     assign w_noise_fres_I = w_noisy_for_I * i_sigma_mul;
//     assign w_noise_fres_Q = w_gng_Q* i_sigma_mul;

//     //======================================================================
//     // Add the independent noise to each symbol S(26,17)
//     //======================================================================
//     wire signed [NB_ADD-1:0] symbI_with_noise, symbQ_with_noise;
//     assign symbI_with_noise = i_symbI_correct + w_noise_fres_I;
//     assign symbQ_with_noise = i_symbQ_correct + w_noise_fres_Q;

//     //======================================================================
//     // Output assignments
//     //======================================================================
//     // assign o_noise_I = symbI_with_noise;
//     // assign o_noise_Q = symbQ_with_noise;

//     assign o_noise_I = ( ~|symbI_with_noise[NB_ADD-1 -: NBI_NOISE_FRES] || &symbI_with_noise[NB_ADD-1 -: NBI_NOISE_FRES]) ? 
//                             symbI_with_noise[NB_ADD-(NBI_ADD-NBI) - 1 -: NBT_NOISE] :
//                             (symbI_with_noise[NB_ADD-1]) ? {1'b1, {NBT_NOISE-1{1'b0}}} : {1'b0, {NBT_NOISE-1{1'b1}}};

//     assign o_noise_Q = ( ~|symbQ_with_noise[NB_ADD-1 -: NBI_NOISE_FRES] || &symbQ_with_noise[NB_ADD-1 -: NBI_NOISE_FRES]) ? 
//                             symbQ_with_noise[NB_ADD-(NBI_ADD-NBI) - 1 -: NBT_NOISE] :
//                             (symbQ_with_noise[NB_ADD-1]) ? {1'b1, {NBT_NOISE-1{1'b0}}} : {1'b0, {NBT_NOISE-1{1'b1}}};

//     // Assign o_noise_fres_I with one of the scaled noises
//     assign o_noise_fres_I = symbI_with_noise;
//     // o_noise_fres_Q is assigned to the original output of the gng module, as needed
//     assign o_noise_fres_Q = symbQ_with_noise; 
//     // The output is considered valid if both generators indicate validity
//    assign o_valid = w_valid_gng_I & w_valid_gng_Q;

// endmodule
