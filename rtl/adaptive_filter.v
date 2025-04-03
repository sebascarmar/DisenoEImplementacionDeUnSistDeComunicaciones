`timescale 1ns/1ps


module adaptive_filter #(
  parameter STEP     = 12'sh001,
  parameter LEAK     = 11'sh001,
  parameter NBT_STEP = 12      ,
  parameter NBF_STEP = 11      ,
  parameter NBT_LEAK = 11      ,
  parameter NBF_LEAK = 10      ,
  
  parameter NUM_TAPS =  9      ,
  parameter NBT_IN   =  8      ,
  parameter NBF_IN   =  7      ,
  parameter NBT_TAPS = 28      ,
  parameter NBF_TAPS = 25      ,
  parameter NBT_OUT  = 12      ,
  parameter NBF_OUT  =  9      ,
  parameter NBT_ERR  = 12      ,
  parameter NBF_ERR  =  9      
)
(
  output signed [NBT_OUT-1:0] o_os_data_I ,
  output signed [NBT_OUT-1:0] o_os_data_Q ,

  input signed  [ NBT_IN-1:0] i_is_data_I , 
  input signed  [ NBT_IN-1:0] i_is_data_Q , 
  input                       i_en_rate2  ,
  input                       i_en_rate1  ,
  input                       i_save_shtrs,
  input                       i_en_rx     ,
  input                       i_reset     ,
  input                       clk       
);


  localparam NBI_OUT  = NBT_OUT - NBF_OUT;


  wire signed [(NUM_TAPS*NBT_TAPS)-1:0] w_taps_I         ;
  wire signed [(NUM_TAPS*NBT_TAPS)-1:0] w_taps_Q         ;
  wire signed [            NBT_OUT-1:0] w_fseI_to_dw_r1I ;
  wire signed [            NBT_OUT-1:0] w_fseQ_to_dw_r1Q ;
  wire signed [            NBT_OUT-1:0] w_dw_r1I_to_slcrI;
  wire signed [            NBT_OUT-1:0] w_dw_r1Q_to_slcrQ;
  wire signed [            NBT_ERR-1:0] w_err_I          ;
  wire signed [            NBT_ERR-1:0] w_err_Q          ;
  (* keep *) wire signed [ NBT_OUT-1:0] w_sym_slcr_I     ;
  (* keep *) wire signed [ NBT_OUT-1:0] w_sym_slcr_Q     ;
  


  lms #(
    .STEP    (STEP    ),
    .LEAK    (LEAK    ),
    .NBT_STEP(NBT_STEP),
    .NBF_STEP(NBF_STEP),
    .NBT_LEAK(NBT_LEAK),
    .NBF_LEAK(NBF_LEAK),
    .NUM_TAPS(NUM_TAPS),
    .NBT_IN  (NBT_IN  ),
    .NBF_IN  (NBF_IN  ),
    .NBT_TAPS(NBT_TAPS),
    .NBF_TAPS(NBF_TAPS),
    .NBT_ERR (NBT_ERR ),
    .NBF_ERR (NBF_ERR )
  ) u_lms (
    .o_taps_I     (w_taps_I    ), // [NBT_TAPS-1:0] data_array [NUM_TAPS-1:0]
    .o_taps_Q     (w_taps_Q    ), // [NBT_TAPS-1:0] data_array [NUM_TAPS-1:0]
    .i_is_data_I  (i_is_data_I ),
    .i_is_data_Q  (i_is_data_Q ),
    .i_err_I      (w_err_I     ),
    .i_err_Q      (w_err_Q     ),
    .i_en_shtr    (i_en_rate2  ),
    .i_en_taps    (i_en_rate1  ),
    .i_save_shftrs(i_save_shtrs),
    .i_en_rx      (i_en_rx     ),
    .i_reset      (i_reset     ),
    .clk          (clk         )
  );


  fse #(
    .NUM_TAPS(NUM_TAPS),
    .NBT_IN  (NBT_IN  ),
    .NBF_IN  (NBF_IN  ),
    .NBT_TAPS(NBT_TAPS),
    .NBF_TAPS(NBF_TAPS),
    .NBT_OUT (NBT_OUT ),
    .NBF_OUT (NBF_OUT )
  ) u_fse (
    .o_os_data_I(w_fseI_to_dw_r1I),
    .o_os_data_Q(w_fseQ_to_dw_r1Q),
    .i_is_data_I(i_is_data_I     ),
    .i_is_data_Q(i_is_data_Q     ),            
    .i_taps_I   (w_taps_I        ),
    .i_taps_Q   (w_taps_Q        ),
    .i_ctrl     (i_en_rate2      ),
    .i_en_taps  (i_en_rate1      ),
    .i_en_rx    (i_en_rx         ),
    .i_reset    (i_reset         ),
    .clk        (clk             )
  );


  downsamp #(
    .NBT_IN_OUT(NBT_OUT), 
    .NBF_IN_OUT(NBT_OUT)
  ) u_dwsamp_r1_I (
    .o_os_data(w_dw_r1I_to_slcrI),
    .i_is_data(w_fseI_to_dw_r1I ),
    .i_ctrl   (i_en_rate1       ),
    .i_en     (i_en_rx          ),
    .i_reset  (i_reset          ),
    .clk      (clk              ) 
  );

  downsamp #(
    .NBT_IN_OUT (NBT_OUT), 
    .NBF_IN_OUT (NBT_OUT)
  ) u_dwsamp_r1_Q (
    .o_os_data(w_dw_r1Q_to_slcrQ),
    .i_is_data(w_fseQ_to_dw_r1Q ),
    .i_ctrl   (i_en_rate1       ),
    .i_en     (i_en_rx          ),
    .i_reset  (i_reset          ),
    .clk      (clk              ) 
  );


  // Slicer
  assign w_sym_slcr_I = (w_dw_r1I_to_slcrI[NBT_OUT-1] == 1'b0)
                        ? { {(NBI_OUT-1){1'b0}} , 1'b1 , {NBF_OUT{1'b0}} }
                        : { {(NBI_OUT-1){1'b1}} , 1'b1 , {NBF_OUT{1'b0}} };
  assign w_sym_slcr_Q = (w_dw_r1Q_to_slcrQ[NBT_OUT-1] == 1'b0)
                        ? { {(NBI_OUT-1){1'b0}} , 1'b1 , {NBF_OUT{1'b0}} }
                        : { {(NBI_OUT-1){1'b1}} , 1'b1 , {NBF_OUT{1'b0}} };


  // Error for LMS
  assign w_err_I = w_dw_r1I_to_slcrI - w_sym_slcr_I;
  assign w_err_Q = w_dw_r1Q_to_slcrQ - w_sym_slcr_Q;


  // Output assignments
  assign o_os_data_I = w_sym_slcr_I;
  assign o_os_data_Q = w_sym_slcr_Q;


endmodule

