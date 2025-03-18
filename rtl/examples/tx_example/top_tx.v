//================================== Modulo TX ===================================
// AUTOR: Juarez Daniel 
// AÑO:   2025  
// NOMBRE: Módulo TOP TX 
// INSTANCE: 
// top_tx
// #(    
//     .NB_OUTPUT ( ), 
//     .NBF_OUTPUT( ), 
//     .NB_COEFF  ( ),
//     .NBF_COEFF ( ),
//     .INIT_FILE ( )
// )
// u_top_tx
// (
//     .i_clock        ( ),
//     .i_reset        ( ),
//     .i_sw           ( ),
//     .o_tx_full_symbI( ),
//     .o_tx_full_symbQ( ),
//     .o_tx_symbI     ( ),
//     .o_tx_symbQ     ( ) 
// );
//================================================================================
module top_tx
#(

  parameter NB_OUTPUT  = 8 , // NB of output
  parameter NBF_OUTPUT = 7 , // NBF of output
  parameter NB_COEFF   = 16, // NB of Coefficients
  parameter NBF_COEFF  = 15, // NBF of Coefficients
  parameter INIT_FILE  = ""  // File with the coefficients
)
(
    input                         i_clock  , // clock system
    input                         i_reset  , // reset system
    input         [3:0]           i_sw     , // i_sw[0] para PRBS y FIR, i_sw[1] para BER, i_sw[3:2] selec de fase
    output signed [NB_COEFF+2:0]  o_tx_full_symbI,
    output signed [NB_COEFF+2:0]  o_tx_full_symbQ,
    output signed [NB_OUTPUT-1:0] o_tx_symbI     , // output signal TX for I 
    output signed [NB_OUTPUT-1:0] o_tx_symbQ      // output signal TX for Q 
);
  
  //Salidas del contador 
  wire [2:0] counter_to_mux;
  wire valid_to_Prbs       ;

  //Salidas de PRBS
  wire out_prbsI_to_fir;  
  wire out_prbsQ_to_fir;

  //Salida de los Filtros Q e I
  wire signed [NB_OUTPUT-1:0] out_data_firI;
  wire signed [NB_OUTPUT-1:0] out_data_firQ; 

  wire signed [NB_COEFF+2:0] out_data_fir_full_Q;
  wire signed [NB_COEFF+2:0] out_data_fir_full_I;


  //==============================================================
  //                  Instantiation of the modules
  //==============================================================

  //==============================================
  //                 Counter                    
  //==============================================
  counter
    u_counter
      (
        .clock    (i_clock ), // clock system         
        .i_reset  (i_reset ), // reset system         
        .i_enable (i_sw[0] ), // signal enable system 

        .o_counter_mux (counter_to_mux),  // counter to Mux 
        .o_validPrbs   (valid_to_Prbs)    // valid for PRBS and FIR
      );

  //==============================================
  //                 PRBS                     
  //==============================================
  prbsQI
  u_prbsQI
    (
      .clock    (i_clock         ), // clock system         
      .i_reset  (i_reset         ), // reset system         
      .i_enable (i_sw[0]         ), // signal enable system 
      .i_valid  (valid_to_Prbs   ), // valid for PRBS and FIR
      .o_PrbsI  (out_prbsI_to_fir), // output PRBS I 
      .o_PrbsQ  (out_prbsQ_to_fir)  // output PRBS Q
    );

  //==============================================
  //                 Filter FIR Q/I                     
  //==============================================
   poly_filterQI
     #(
       .NB_OUTPUT  (NB_OUTPUT ), // NB of output
       .NBF_OUTPUT (NBF_OUTPUT), // NBF of output
       .NB_COEFF   (NB_COEFF  ), // NB of Coefficients
       .NBF_COEFF  (NBF_COEFF ), // NBF of Coefficients
       .INIT_FILE  (INIT_FILE )  // File with the coefficients
     )
     u_poly_filterQI 
       (
         .clock        (i_clock         ), // Clock 
         .i_reset      (i_reset         ), // Reset 
         .i_enable     (i_sw[0]         ), // Enable
         .i_valid      (valid_to_Prbs   ), // Valid enable        
         .i_dataPrbsI  (out_prbsI_to_fir), // Input PRBS I
         .i_dataPrbsQ  (out_prbsQ_to_fir), // Input PRBS Q 
         .i_counterMux (counter_to_mux  ), // counter to Mux
         .o_out_fir_full_Q (out_data_fir_full_Q), // Out data full resolution Q
         .o_out_fir_full_I (out_data_fir_full_I), // Out data full resolution I         
         .o_out_firI   (out_data_firI   ), // output FIR I 
         .o_out_firQ   (out_data_firQ   )  // output FIR Q
       );

  assign o_tx_symbI  = out_data_firI;
  assign o_tx_symbQ  = out_data_firQ;

  assign o_tx_full_symbI  = out_data_fir_full_I;
  assign o_tx_full_symbQ  = out_data_fir_full_Q;



endmodule

