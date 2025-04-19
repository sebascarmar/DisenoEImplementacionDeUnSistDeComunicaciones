`timescale 1ns/1ps


module lms #(
  parameter STEP     = 12'sh001,
  parameter LEAK     = 11'sh001,
  parameter NBT_STEP = 12      ,
  parameter NBF_STEP = 11      ,
  parameter NBT_LEAK = 11      ,
  parameter NBF_LEAK = 10      ,
  
  parameter NUM_TAPS     =  9,
  parameter NBT_IN       =  8,
  parameter NBF_IN       =  7,
  parameter NBT_LMS_TAPS = 20,
  parameter NBF_LMS_TAPS = 17,
  parameter NBT_FSE_TAPS = 10,
  parameter NBF_FSE_TAPS =  7,
  parameter NBT_ERR      =  9,
  parameter NBF_ERR      =  7
)
(
  output signed [(NUM_TAPS*NBT_FSE_TAPS)-1:0] o_taps_I     , // [NBT_LMS_TAPS-1:0] data_array [NUM_TAPS-1:0]
  output signed [(NUM_TAPS*NBT_FSE_TAPS)-1:0] o_taps_Q     , // [NBT_LMS_TAPS-1:0] data_array [NUM_TAPS-1:0]

  input signed  [                 NBT_IN-1:0] i_is_data_I  , // S(8,7)
  input signed  [                 NBT_IN-1:0] i_is_data_Q  , // S(8,7)
  input signed  [                NBT_ERR-1:0] i_err_I      , // S(27,24)
  input signed  [                NBT_ERR-1:0] i_err_Q      , // S(27,24)
  input                                       i_en_shtr    ,
  input                                       i_en_taps    ,
  input                                       i_save_shftrs,
  input                                       i_en_rx      ,
  input                                       i_reset      ,
  input                                       clk       
);

  // Local parameters for internal operations and output saturation
  localparam NBT_TERM1    = NBT_LMS_TAPS + (NBT_STEP+NBT_LEAK)           ;
  localparam NBF_TERM1    = NBF_LMS_TAPS + (NBF_STEP+NBF_LEAK)           ;
  localparam NBI_TERM1    = NBT_TERM1 - NBF_TERM1                        ;
  localparam NBT_TERM2    = NBT_STEP + (NBT_ERR+NBT_IN + 1)              ;
  localparam NBF_TERM2    = NBF_STEP + (NBF_ERR+NBF_IN    )              ;
  localparam NBI_TERM2    = NBT_TERM2 - NBF_TERM2                        ;

  localparam NBT_ADD      = max(NBT_TERM1, NBT_TERM2) + 1                ;
  localparam NBF_ADD      = max(NBF_TERM1, NBF_TERM2)                    ;
  localparam ALIGN_SIG    = max(NBI_TERM1-NBI_TERM2, NBI_TERM2-NBI_TERM1);
  localparam ALIGN_LSB    = max(NBF_TERM1-NBF_TERM2, NBF_TERM2-NBF_TERM1);

  localparam NBI_ADD      = NBT_ADD - NBF_ADD                            ;
  localparam NBI_LMS_TAPS = NBT_LMS_TAPS - NBF_LMS_TAPS                  ;
  localparam NB_SAT       = NBI_ADD - NBI_LMS_TAPS                       ; 

  localparam NBI_FSE_TAPS = NBT_FSE_TAPS - NBF_FSE_TAPS                  ;
  localparam NB_FSE_SAT   = NBI_LMS_TAPS - NBI_FSE_TAPS                  ; 


  // Internal registers and wires
  reg  signed [      NBT_IN-1:0] r_shifter_I      [3+NUM_TAPS-1:0]; 
  reg  signed [      NBT_IN-1:0] r_shifter_Q      [3+NUM_TAPS-1:0]; 
  reg  signed [      NBT_IN-1:0] r_shftr_buf_r1_I [  NUM_TAPS-1:0]; 
  reg  signed [      NBT_IN-1:0] r_shftr_buf_r1_Q [  NUM_TAPS-1:0]; 
  reg  signed [NBT_LMS_TAPS-1:0] r_taps_I         [  NUM_TAPS-1:0];
  reg  signed [NBT_LMS_TAPS-1:0] r_taps_Q         [  NUM_TAPS-1:0];

  wire signed [NBT_STEP+NBT_LEAK-1:0] one                   ;
  assign one = (1'b1 << (NBF_STEP+NBF_LEAK))                ;
  reg signed [    NBT_TERM1-1:0] r_term1_I    [NUM_TAPS-1:0];//S(51,46)
  reg signed [    NBT_TERM2-1:0] r_term2_I    [NUM_TAPS-1:0];//S(33,27)
  reg signed [      NBT_ADD-1:0] w_add_I      [NUM_TAPS-1:0];//S(52,46)
  reg signed [ NBT_LMS_TAPS-1:0] w_new_taps_I [NUM_TAPS-1:0];//S(28,25)
  reg signed [    NBT_TERM1-1:0] r_term1_Q    [NUM_TAPS-1:0];
  reg signed [    NBT_TERM2-1:0] r_term2_Q    [NUM_TAPS-1:0];
  reg signed [      NBT_ADD-1:0] w_add_Q      [NUM_TAPS-1:0];
  reg signed [ NBT_LMS_TAPS-1:0] w_new_taps_Q [NUM_TAPS-1:0];



  // Shift register: Sequentially updates input samples at rate 2
  integer i;
  always @(posedge clk) begin
    if (i_reset==1'b1 || i_en_rx==1'b0) begin
        for (i=0 ; i<3+NUM_TAPS ; i=i+1) begin
            r_shifter_I[i] <= {NBT_IN{1'b0}};
            r_shifter_Q[i] <= {NBT_IN{1'b0}};
        end
    end
    else begin
        if (i_en_shtr==1'b1) begin // Update shifter at rate 2
            for (i=0 ; i<3+NUM_TAPS ; i=i+1) begin
                if (i==0) begin
                    r_shifter_I[i] <= i_is_data_I;
                    r_shifter_Q[i] <= i_is_data_Q;
                end
                else begin
                    r_shifter_I[i] <= r_shifter_I[i-1];
                    r_shifter_Q[i] <= r_shifter_Q[i-1];
                end   
            end
        end
        else begin
            for (i=0 ; i<3+NUM_TAPS ; i=i+1) begin
                r_shifter_I[i] <= r_shifter_I[i];
                r_shifter_Q[i] <= r_shifter_Q[i];
            end
        end
    end
  end
  
  // Shifter buffers: updated at rate 1, after taps update 
  integer j  ;
  always @(posedge clk) begin
    if (i_reset==1'b1 || i_en_rx==1'b0) begin
        for (j=0 ; j<NUM_TAPS ; j=j+1) begin
            r_shftr_buf_r1_I[j] <= {NBT_IN{1'b0}};
            r_shftr_buf_r1_Q[j] <= {NBT_IN{1'b0}};
        end
    end
    else begin
        if (i_save_shftrs==1'b1) begin
            for (j=0 ; j<NUM_TAPS ; j=j+1) begin
                r_shftr_buf_r1_I[j] <= r_shifter_I[3+j];
                r_shftr_buf_r1_Q[j] <= r_shifter_Q[3+j];
            end
        end
        else begin
            for (j=0 ; j<NUM_TAPS ; j=j+1) begin
                r_shftr_buf_r1_I[j] <= r_shftr_buf_r1_I[j];
                r_shftr_buf_r1_Q[j] <= r_shftr_buf_r1_Q[j];
            end
        end
    end
  end


  // FSE coefficient registers: initialized to 1+j0 and updated at rate 1 (BR)
  integer k  ;
  localparam MID_IDX = NUM_TAPS/2;
  always @(posedge clk) begin
    if (i_reset==1'b1 || i_en_rx==1'b0) begin // Initialize taps with 1+j0 at the center position 
        for (k=0 ; k<NUM_TAPS ; k=k+1) begin
            r_taps_I[k] <= (k==MID_IDX) ? { {(NBI_LMS_TAPS-1){1'b0}} , 1'b1 , {NBF_LMS_TAPS{1'b0}} } : {NBT_LMS_TAPS{1'b0}};
            r_taps_Q[k] <= {NBT_LMS_TAPS{1'b0}};
        end
    end
    else begin
        if (i_en_taps==1'b1) begin // Update taps at rate 1 (BR)
            for (k=0 ; k<NUM_TAPS ; k=k+1) begin
                r_taps_I[k] <= w_new_taps_I[k];
                r_taps_Q[k] <= w_new_taps_Q[k];
            end
        end
        else begin
            for (k=0 ; k<NUM_TAPS ; k=k+1) begin
                r_taps_I[k] <= r_taps_I[k];
                r_taps_Q[k] <= r_taps_Q[k];
            end
        end
    end
  end


  // Update tap values in 2 stages

  ////1st stage: compute and register both terms for tap update
  integer m;
  always @(posedge clk) begin
    if (i_reset==1'b1 || i_en_rx==1'b0) begin
        for (m=0 ; m<NUM_TAPS ; m=m+1) begin
          r_term1_I[m] <= r_taps_I[m]*(one-STEP*LEAK);
          r_term2_I[m] <= STEP*(i_err_I*r_shftr_buf_r1_I[m] + i_err_Q*r_shftr_buf_r1_Q[m]);
          r_term1_Q[m] <= r_taps_Q[m]*(one-STEP*LEAK);
          r_term2_Q[m] <= STEP*(i_err_I*r_shftr_buf_r1_Q[m] - i_err_Q*r_shftr_buf_r1_I[m]);
        end
    end
    else begin
        if (i_save_shftrs==1'b1) begin // Update terms at rate 1 (BR)
            for (m=0 ; m<NUM_TAPS ; m=m+1) begin
              r_term1_I[m] <= r_taps_I[m]*(one-STEP*LEAK);
              r_term2_I[m] <= STEP*(i_err_I*r_shftr_buf_r1_I[m] + i_err_Q*r_shftr_buf_r1_Q[m]);
              r_term1_Q[m] <= r_taps_Q[m]*(one-STEP*LEAK);
              r_term2_Q[m] <= STEP*(i_err_I*r_shftr_buf_r1_Q[m] - i_err_Q*r_shftr_buf_r1_I[m]);
            end
        end
        else begin
            for (m=0 ; m<NUM_TAPS ; m=m+1) begin
              r_term1_I[m] <= r_term1_I[m];
              r_term2_I[m] <= r_term2_I[m];
              r_term1_Q[m] <= r_term1_Q[m];
              r_term2_Q[m] <= r_term2_Q[m];
            end
        end
    end
  end

  //// 2nd stage: combine both terms to compute the updated tap values
  integer n;
  always @(*) begin
    for (n=0 ; n<NUM_TAPS ; n=n+1) begin
        w_add_I[n] =  r_term1_I[n] - (r_term2_I[n]<<ALIGN_LSB);
        w_add_Q[n] =  r_term1_Q[n] + (r_term2_Q[n]<<ALIGN_LSB);
    end
  end


  // Saturate and truncate updated taps to LSM format (wider than FSE format)
  integer p;
  always @(*) begin
    for (p=0 ; p<NUM_TAPS ; p=p+1) begin
          w_new_taps_I[p] = ( ~|w_add_I[p][(NBT_ADD-1) -: NB_SAT+1] || &w_add_I[p][(NBT_ADD-1) -: NB_SAT+1])
                              ? w_add_I[p][(NBT_ADD-1)-NB_SAT -: NBT_LMS_TAPS]
                              :( (w_add_I[p][NBT_ADD-1])
                                 ? { 1'b1, {(NBT_LMS_TAPS-1){1'b0}} }
                                 : { 1'b0, {(NBT_LMS_TAPS-1){1'b1}} } );
          w_new_taps_Q[p] = ( ~|w_add_Q[p][(NBT_ADD-1) -: NB_SAT+1] || &w_add_Q[p][(NBT_ADD-1) -: NB_SAT+1])
                              ? w_add_Q[p][(NBT_ADD-1)-NB_SAT -: NBT_LMS_TAPS]
                              :( (w_add_Q[p][NBT_ADD-1])
                                 ? { 1'b1, {(NBT_LMS_TAPS-1){1'b0}} }
                                 : { 1'b0, {(NBT_LMS_TAPS-1){1'b1}} } );
    end
  end


  // Assign computed tap values to output bus while applying truncation to FSE format
  genvar q;
  generate
      for (q=0; q<NUM_TAPS ; q=q+1) begin
          assign o_taps_I[(q+1)*NBT_FSE_TAPS-1 : q*NBT_FSE_TAPS] = r_taps_I[q][(NBT_LMS_TAPS-1) -: NBT_FSE_TAPS];
          assign o_taps_Q[(q+1)*NBT_FSE_TAPS-1 : q*NBT_FSE_TAPS] = r_taps_Q[q][(NBT_LMS_TAPS-1) -: NBT_FSE_TAPS];
      end
  endgenerate






// Returns the maximum value between two integers
function integer max;
    input integer a, b;
    begin
        max = (a > b) ? a : b;
    end
endfunction


endmodule

