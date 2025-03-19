//============================================================
// SNR to Variance table in S(8,7) format
// -----------------------------------------------------------
// SNR (dB)     Variance σ²     σ² (hex)    S(8,7) format
// -----------------------------------------------------------
//       7         0.21875         8'h1c         00011100
//       8       0.1953125         8'h19         00011001
//       9        0.171875         8'h16         00010110
//      10         0.15625         8'h14         00010100
//      11        0.140625         8'h12         00010010
//      12           0.125         8'h10         00010000
// -----------------------------------------------------------
//============================================================
`timescale 1 ns / 1 ps


module gng_top #(
    parameter Z1_I      = 64'd5030521883283424767 , // GNG seed 1 for I
    parameter Z2_I      = 64'd18445829279364155008, // GNG seed 2 for I
    parameter Z3_I      = 64'd18436106298727503359, // GNG seed 3 for I
    parameter Z1_Q      = 64'd14533118196545751551, // GNG seed 1 for Q
    parameter Z2_Q      = 64'd18444914485018758400, // GNG seed 2 for Q
    parameter Z3_Q      = 64'd18425749998705519615, // GNG seed 3 for Q
    
    parameter SIGMA     = 8'sh1c                  ,
    
    parameter NBT_SIGMA =  8, // Total bits for the standard deviation for a desired SNR
    parameter NBF_SIGMA =  7, // Fractional bits for the standard deviation for a desired SNR
    parameter NBT_NOISE =  8, // Total bits for the output noise
    parameter NBF_NOISE =  7  // Fractional bits for the output noise
)
(
    output signed [NBT_NOISE-1 : 0] o_noise_I, // Output noise in S(8,7) format
    output signed [NBT_NOISE-1 : 0] o_noise_Q, // Output noise in S(8,7) format
    
    input                           i_reset  , // Active low reset 
    input                           clk        // System clock                 
);
  
  // Local parameters
  localparam NBT_DATA_GNG   = 16                             ; // Integer bits for GNG data (given by IP core )
  localparam NBF_DATA_GNG   = 11                             ; // Fractional bits for GNG data (given by IP core)
  localparam NBT_NOISE_FRES = NBT_DATA_GNG + NBT_SIGMA       ; // Total bits for full-res noise -> 16 + 8 = 24
  localparam NBF_NOISE_FRES = NBF_DATA_GNG + NBF_SIGMA       ; // Fractional bits for full-res noise -> 11 + 7 = 18  
  localparam NBI_NOISE_FRES = NBT_NOISE_FRES - NBF_NOISE_FRES; // Integer bits for full-res noise -> 24-18 = 6
  localparam NBI_NOISE      = NBT_NOISE - NBF_NOISE          ; // Integer bits for output noise
  localparam NB_SAT         = NBI_NOISE_FRES - NBI_NOISE     ; // Integer bit diff. (full-res vs. output), used for saturation
  
  // Internal wires
  wire                             w_valid_gng_I;
  wire                             w_valid_gng_Q; 
  wire signed [NBT_DATA_GNG-1 : 0] w_gng_Q      ; // S(16,11)
  wire signed [NBT_DATA_GNG-1 : 0] w_gng_I      ; // S(16,11)
  wire signed [NBT_NOISE_FRES-1:0] w_noise_fres_I, w_noise_fres_Q; // Scale the noise: S(16,11)*S(8,6) = S(24,18)
  
  
  // Generation of independent noise for I and Q
  gng#(
    .INIT_Z1(Z1_I), 
    .INIT_Z2(Z2_I), 
    .INIT_Z3(Z3_I)
  ) u_gng_I (
      .i_clock   (clk            ),
      .i_reset   (i_reset        ),
      .ce        (1'b1           ),
      .valid_out (w_valid_gng_I  ),
      .data_out  (w_gng_I        ) // S(16,11)
  );
  
  gng#(
    .INIT_Z1(Z1_Q), 
    .INIT_Z2(Z2_Q), 
    .INIT_Z3(Z3_Q)
  ) u_gng_Q (
      .i_clock   (clk            ),
      .i_reset   (i_reset        ),
      .ce        (1'b1           ),
      .valid_out (w_valid_gng_Q  ),
      .data_out  (w_gng_Q        ) // S(16,11)
  );
  
  // Scale the noise based on the SNR, represented by the std. deviation
  assign w_noise_fres_I = w_gng_I * SIGMA; // S(24,18)
  assign w_noise_fres_Q = w_gng_Q * SIGMA; // S(24,18)
  
  
  // Output assignment with saturation and truncation S(24,18) -> S(8,7)  
  assign o_noise_I = ( w_valid_gng_I==1'b1 )
                       ? ( ~|w_noise_fres_I[NBT_NOISE_FRES-1 -: NBI_NOISE_FRES] || &w_noise_fres_I[NBT_NOISE_FRES-1 -: NBI_NOISE_FRES] ) 
                           ? w_noise_fres_I[(NBT_NOISE_FRES-1)-NB_SAT -: NBT_NOISE] 
                           : ( ( w_noise_fres_I[NBT_NOISE_FRES-1]==1'b1 ) 
                                 ? {1'b1, {NBT_NOISE-1{1'b0}}}   // saturate to max positive
                                 : {1'b0, {NBT_NOISE-1{1'b1}}} ) // saturate to max negative
                       : {NBT_NOISE{1'b0}};
  
  assign o_noise_Q = ( w_valid_gng_Q==1'b1 )
                       ? ( ~|w_noise_fres_Q[NBT_NOISE_FRES-1 -: NBI_NOISE_FRES] || &w_noise_fres_Q[NBT_NOISE_FRES-1 -: NBI_NOISE_FRES] ) 
                           ? w_noise_fres_Q[(NBT_NOISE_FRES-1)-NB_SAT -: NBT_NOISE] 
                           : ( ( w_noise_fres_Q[NBT_NOISE_FRES-1]==1'b1 ) 
                                 ? {1'b1, {NBT_NOISE-1{1'b0}}}   // saturate to max positive
                                 : {1'b0, {NBT_NOISE-1{1'b1}}} ) // saturate to max negative
                       : {NBT_NOISE{1'b0}};
  

endmodule



