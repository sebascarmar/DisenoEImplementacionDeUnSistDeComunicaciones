`timescale 1ns/1ps


module lms #(
  parameter STEP     = 12'sh001,
  parameter LEAK     = 11'sh001,
  parameter NBT_STEP = 12      ,
  parameter NBF_STEP = 11      ,
  parameter NBT_LEAK = 11      ,
  parameter NBF_LEAK = 10      ,
  
  parameter NUM_TAPS = 11      ,
  parameter NBT_IN   =  8      ,
  parameter NBF_IN   =  7      ,
  parameter NBT_TAPS = 28      ,
  parameter NBF_TAPS = 25      ,
  parameter NBT_ERR  = 12      ,
  parameter NBF_ERR  =  9
)
(
  output wire  [(NUM_TAPS*NBT_TAPS)-1:0] o_taps_I   , // [NBT_TAPS-1:0] data_array [NUM_TAPS-1:0]
  output wire  [(NUM_TAPS*NBT_TAPS)-1:0] o_taps_Q   , // [NBT_TAPS-1:0] data_array [NUM_TAPS-1:0]

  input signed [             NBT_IN-1:0] i_is_data_I, // S(8,7)
  input signed [             NBT_IN-1:0] i_is_data_Q, // S(8,7)
  input signed [            NBT_ERR-1:0] i_err_I    , // S(27,24)
  input signed [            NBT_ERR-1:0] i_err_Q    , // S(27,24)
  input                                  i_en_shtr  ,
  input                                  i_en_taps  ,
  input                                  i_reset    ,
  input                                  clk       
);

  // Local parameters for internal operations and output saturation
  localparam NBT_TERM1 = NBT_TAPS + (NBT_STEP+NBT_LEAK)               ;
  localparam NBF_TERM1 = NBF_TAPS + (NBF_STEP+NBF_LEAK)               ;
  localparam NBI_TERM1 = NBT_TERM1 - NBF_TERM1                        ;
  localparam NBT_TERM2 = NBT_STEP + (NBT_ERR+NBT_IN + 1)              ;
  localparam NBF_TERM2 = NBF_STEP + (NBF_ERR+NBF_IN    )              ;
  localparam NBI_TERM2 = NBT_TERM2 - NBF_TERM2                        ;

  localparam NBT_ADD   = max(NBT_TERM1, NBT_TERM2) + 1                ;
  localparam NBF_ADD   = max(NBF_TERM1, NBF_TERM2)                    ;
  localparam ALIGN_SIG = max(NBI_TERM1-NBI_TERM2, NBI_TERM2-NBI_TERM1);
  localparam ALIGN_LSB = max(NBF_TERM1-NBF_TERM2, NBF_TERM2-NBF_TERM1);

  localparam NBI_ADD   = NBT_ADD - NBF_ADD                            ;
  localparam NBI_TAPS  = NBT_TAPS - NBF_TAPS                          ;
  localparam NB_SAT    = NBI_ADD - NBI_TAPS                           ; 



  // Internal registers and wires
  reg  signed [  NBT_IN-1:0] r_shifter_I   [NUM_TAPS-1:0]; 
  reg  signed [  NBT_IN-1:0] r_shifter_Q   [NUM_TAPS-1:0]; 
  reg  signed [NBT_TAPS-1:0] r_taps_I      [NUM_TAPS-1:0];
  reg  signed [NBT_TAPS-1:0] r_taps_Q      [NUM_TAPS-1:0];

  wire signed [NBT_STEP+NBT_LEAK-1:0] one                ;
  assign one = (1'b1 << (NBF_STEP+NBF_LEAK))             ;
  wire signed [NBT_TERM1-1:0] w_term1_I    [NUM_TAPS-1:0];//S(51,46)
  wire signed [NBT_TERM2-1:0] w_term2_I    [NUM_TAPS-1:0];//S(33,27)
  wire signed [  NBT_ADD-1:0] w_add_I      [NUM_TAPS-1:0];//S(52,46)
  wire signed [ NBT_TAPS-1:0] w_new_taps_I [NUM_TAPS-1:0];//S(28,25)
  wire signed [NBT_TERM1-1:0] w_term1_Q    [NUM_TAPS-1:0];
  wire signed [NBT_TERM2-1:0] w_term2_Q    [NUM_TAPS-1:0];
  wire signed [  NBT_ADD-1:0] w_add_Q      [NUM_TAPS-1:0];
  wire signed [ NBT_TAPS-1:0] w_new_taps_Q [NUM_TAPS-1:0];



  // Shift register: Sequentially updates input samples at rate 2
  integer i;
  always @(posedge clk) begin
    if (i_reset == 1'b1) begin
        for (i=0 ; i<NUM_TAPS ; i=i+1) begin
            r_shifter_I[i] <= {NBT_IN{1'b0}};
            r_shifter_Q[i] <= {NBT_IN{1'b0}};
        end
    end
    else begin
        if (i_en_shtr==1'b1) begin // Update shifter at rate 2
            for (i=0 ; i<NUM_TAPS ; i=i+1) begin
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
            for (i=0 ; i<NUM_TAPS ; i=i+1) begin
                r_shifter_I[i] <= r_shifter_I[i];
                r_shifter_Q[i] <= r_shifter_Q[i];
            end
        end
    end
  end

  // FSE coefficient registers: initialized to 1+j0 and updated at rate 4  
  integer j  ;
  localparam MID_IDX = NUM_TAPS/2;
  always @(posedge clk) begin
    if (i_reset == 1'b1) begin // Initialize taps with 1+j0 at the center position  
        for (j=0 ; j<NUM_TAPS ; j=j+1) begin
            r_taps_I[j] <= (j==MID_IDX) ? { {(NBI_TAPS-1){1'b0}} , 1'b1 , {NBF_TAPS{1'b0}} } : {NBT_TAPS{1'b0}};
            r_taps_Q[j] <= {NBT_TAPS{1'b0}};
        end
    end
    else begin
        if (i_en_taps==1'b1) begin // Update taps at rate 4
            for (j=0 ; j<NUM_TAPS ; j=j+1) begin
                r_taps_I[j] <= w_new_taps_I[j];
                r_taps_Q[j] <= w_new_taps_Q[j];
            end
        end
        else begin
            for (j=0 ; j<NUM_TAPS ; j=j+1) begin
                r_taps_I[j] <= r_taps_I[j];
                r_taps_Q[j] <= r_taps_Q[j];
            end
        end
    end
  end



  // LMS-based coefficient computation for the FSE  
  genvar k;
  generate
      for (k=0; k<NUM_TAPS ; k=k+1) begin
          // NEW I TAPS CALCULATION:
          //  new_tap_I = tap_I*(1-step*leak) - step*(err_I*shi_I + err_Q*shi_Q)
          //  new_tap_I = term1_I - term2_I
          assign w_term1_I[k] = r_taps_I[k]*(one-STEP*LEAK);
          assign w_term2_I[k] = STEP*(i_err_I*r_shifter_I[k] + i_err_Q*r_shifter_Q[k]);
          assign w_add_I[k] = (NBI_TERM1>NBI_TERM2 && NBF_TERM1>NBF_TERM2)
                             ?   w_term1_I[k] - { {ALIGN_SIG{w_term2_I[k][NBT_TERM2-1]}} , (w_term2_I[k]<<ALIGN_LSB ) } 
                             :(NBI_TERM1>NBI_TERM2 && NBF_TERM1<NBF_TERM2)
                             ?   (w_term1_I[k]<<ALIGN_LSB ) - { {ALIGN_SIG{w_term2_I[k][NBT_TERM2-1]}} , w_term2_I[k] }
                             :(NBI_TERM1<NBI_TERM2 && NBF_TERM1>NBF_TERM2)
                             ?   { {ALIGN_SIG{w_term1_I[k][NBT_TERM1-1]}} ,w_term1_I[k] } - (w_term2_I[k]<<ALIGN_LSB)
                             :(NBI_TERM1<NBI_TERM2 && NBF_TERM1<NBF_TERM2)
                             ?   { {ALIGN_SIG{w_term1_I[k][NBT_TERM1-1]}} , (w_term1_I[k]<<ALIGN_LSB )} - w_term2_I[k]
                             :   w_term1_I[k] - w_term2_I[k] ;
          // Saturation and truncation of the final computed tap value  
          assign w_new_taps_I[k] = ( ~|w_add_I[k][(NBT_ADD-1) -: NB_SAT+1] || &w_add_I[k][(NBT_ADD-1) -: NB_SAT+1])
                                     ? w_add_I[k][(NBT_ADD-1)-NB_SAT -: NBT_TAPS]
                                     :( (w_add_I[k][NBT_ADD-1])
                                        ? { 1'b1, {(NBT_TAPS-1){1'b0}} }
                                        : { 1'b0, {(NBT_TAPS-1){1'b1}} } );
          
          
          // NEW Q TAPS CALCULATION:
          //  new_tap_Q = tap_Q*(1-step*leak) + step*(err_I*shi_Q - err_Q*shi_I)
          //  new_tap_Q = term1_Q - term2_Q
          assign w_term1_Q[k] = r_taps_Q[k]*(one-STEP*LEAK);
          assign w_term2_Q[k] = STEP*(i_err_I*r_shifter_Q[k] - i_err_Q*r_shifter_I[k]);
          assign w_add_Q[k] = (NBI_TERM1>NBI_TERM2 && NBF_TERM1>NBF_TERM2)
                             ?    w_term1_Q[k] + { {ALIGN_SIG{w_term2_Q[k][NBT_TERM2-1]}} , (w_term2_Q[k]<<ALIGN_LSB ) } 
                             :(NBI_TERM1>NBI_TERM2 && NBF_TERM1<NBF_TERM2)
                             ?    (w_term1_Q[k]<<ALIGN_LSB ) + { {ALIGN_SIG{w_term2_Q[k][NBT_TERM2-1]}} , w_term2_Q[k] }
                             :(NBI_TERM1<NBI_TERM2 && NBF_TERM1>NBF_TERM2)
                             ?    { {ALIGN_SIG{w_term1_Q[k][NBT_TERM1-1]}} ,w_term1_Q[k] } + (w_term2_Q[k]<<ALIGN_LSB)
                             :(NBI_TERM1<NBI_TERM2 && NBF_TERM1<NBF_TERM2)
                             ?    { {ALIGN_SIG{w_term1_Q[k][NBT_TERM1-1]}} , (w_term1_Q[k]<<ALIGN_LSB )} + w_term2_Q[k]
                             :    w_term1_Q[k] + w_term2_Q[k] ;
          // Saturation and truncation of the final computed tap value  
          assign w_new_taps_Q[k] = ( ~|w_add_Q[k][(NBT_ADD-1) -: NB_SAT+1] || &w_add_Q[k][(NBT_ADD-1) -: NB_SAT+1])
                                     ? w_add_Q[k][(NBT_ADD-1)-NB_SAT -: NBT_TAPS]
                                     :( (w_add_Q[k][NBT_ADD-1])
                                        ? { 1'b1, {(NBT_TAPS-1){1'b0}} }
                                        : { 1'b0, {(NBT_TAPS-1){1'b1}} } );
      end
      
  endgenerate


  // Assign computed tap values to output bus  
  genvar m;
  generate
      for (m=0; m<NUM_TAPS ; m=m+1) begin : assign_taps
          assign o_taps_I[(m+1)*NBT_TAPS-1 : m*NBT_TAPS] = r_taps_I[m];
          assign o_taps_Q[(m+1)*NBT_TAPS-1 : m*NBT_TAPS] = r_taps_Q[m];
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
