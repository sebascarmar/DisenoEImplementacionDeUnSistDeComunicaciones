`timescale 1ns/1ps


module fse #(
  parameter NUM_TAPS = 11,
  parameter NBT_IN   =  8,
  parameter NBF_IN   =  7,
  parameter NBT_TAPS = 28,
  parameter NBF_TAPS = 25,
  parameter NBT_OUT  = 12,
  parameter NBF_OUT  =  9
)
(
  output signed [           NBT_OUT-1:0] o_os_data_I,
  output signed [           NBT_OUT-1:0] o_os_data_Q,

  input signed [             NBT_IN-1:0] i_is_data_I, 
  input signed [             NBT_IN-1:0] i_is_data_Q, 
  input signed [(NUM_TAPS*NBT_TAPS)-1:0] i_taps_I   , // [NBT_TAPS-1:0] data_array [NUM_TAPS-1:0]
  input signed [(NUM_TAPS*NBT_TAPS)-1:0] i_taps_Q   , // [NBT_TAPS-1:0] data_array [NUM_TAPS-1:0]
  input                                  i_en       ,
  input                                  i_reset    ,
  input                                  clk       
);

  // Local parameters for internal operations and output saturation
  localparam NBT_PROD = NBT_IN + NBT_TAPS          ;
  localparam NBF_PROD = NBF_IN + NBF_TAPS          ;

  localparam NBT_ADD  = NBT_PROD + $clog2(NUM_TAPS);
  localparam NBF_ADD  = NBF_PROD                   ;
  localparam NBI_ADD  = NBT_ADD - NBF_ADD          ;
  localparam NBI_OUT  = NBT_OUT - NBF_OUT          ;
  localparam NB_SAT   = NBI_ADD - NBI_OUT          ; 

  // Internal registers and wires
  reg  signed [     NBT_IN-1:0] r_shifter_I      [NUM_TAPS-1:0]; 
  reg  signed [     NBT_IN-1:0] r_shifter_Q      [NUM_TAPS-1:0]; 
  wire signed [   NBT_TAPS-1:0] w_taps_I         [NUM_TAPS-1:0];
  wire signed [   NBT_TAPS-1:0] w_taps_Q         [NUM_TAPS-1:0];
  wire signed [   NBT_PROD-1:0] w_part_prod_sIxtI[NUM_TAPS-1:0];
  wire signed [   NBT_PROD-1:0] w_part_prod_sQxtI[NUM_TAPS-1:0];
  wire signed [   NBT_PROD-1:0] w_part_prod_sIxtQ[NUM_TAPS-1:0];
  wire signed [   NBT_PROD-1:0] w_part_prod_sQxtQ[NUM_TAPS-1:0];
  wire signed [    NBT_ADD-1:0] w_add_sIxtI                    ;
  wire signed [    NBT_ADD-1:0] w_add_sQxtQ                    ;
  wire signed [    NBT_ADD-1:0] w_add_sIxtQ                    ;
  wire signed [    NBT_ADD-1:0] w_add_sQxtI                    ;
  wire signed [(NBT_ADD+1)-1:0] w_add_I                        ;
  wire signed [(NBT_ADD+1)-1:0] w_add_Q                        ;


  // Shift register: Sequentially updates input samples at rate 2
  integer i;
  always @(posedge clk) begin
    if (i_reset==1'b1) begin
        for (i=0 ; i<NUM_TAPS ; i=i+1) begin
            r_shifter_I[i] <= {NBT_IN{1'b0}};
            r_shifter_Q[i] <= {NBT_IN{1'b0}};
        end
    end
    else begin
        if (i_en==1'b1) begin // Update shifter at rate 2
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

  // Converting a packed 1D input into a 2D-indexed array for easier access
  genvar j;
  generate
      for (j=0; j<NUM_TAPS ; j=j+1) begin
          assign w_taps_I[j] = i_taps_I[(j+1)*NBT_TAPS-1 : j*NBT_TAPS];
          assign w_taps_Q[j] = i_taps_Q[(j+1)*NBT_TAPS-1 : j*NBT_TAPS];
      end
  endgenerate

  // Compute partial products between input samples and filter coefficients
  genvar k;
  generate
      for (k=0; k<NUM_TAPS ; k=k+1) begin : multiply
          assign w_part_prod_sIxtI[k] = r_shifter_I[k] * w_taps_I[k];
          assign w_part_prod_sQxtQ[k] = r_shifter_Q[k] * w_taps_Q[k];
          
          assign w_part_prod_sIxtQ[k] = r_shifter_I[k] * w_taps_Q[k];
          assign w_part_prod_sQxtI[k] = r_shifter_Q[k] * w_taps_I[k];
      end
  endgenerate

  // Sum all partial products for each component
  assign w_add_sIxtI = w_part_prod_sIxtI[ 0] + w_part_prod_sIxtI[ 1] + w_part_prod_sIxtI[ 2] + w_part_prod_sIxtI[ 3] +
                       w_part_prod_sIxtI[ 4] + w_part_prod_sIxtI[ 5] + w_part_prod_sIxtI[ 6] + w_part_prod_sIxtI[ 7] +
                       w_part_prod_sIxtI[ 8] + w_part_prod_sIxtI[ 9] + w_part_prod_sIxtI[10] ;
  assign w_add_sQxtQ = w_part_prod_sQxtQ[ 0] + w_part_prod_sQxtQ[ 1] + w_part_prod_sQxtQ[ 2] + w_part_prod_sQxtQ[ 3] +
                       w_part_prod_sQxtQ[ 4] + w_part_prod_sQxtQ[ 5] + w_part_prod_sQxtQ[ 6] + w_part_prod_sQxtQ[ 7] +
                       w_part_prod_sQxtQ[ 8] + w_part_prod_sQxtQ[ 9] + w_part_prod_sQxtQ[10] ;

  assign w_add_sIxtQ = w_part_prod_sIxtQ[ 0] + w_part_prod_sIxtQ[ 1] + w_part_prod_sIxtQ[ 2] + w_part_prod_sIxtQ[ 3] +
                       w_part_prod_sIxtQ[ 4] + w_part_prod_sIxtQ[ 5] + w_part_prod_sIxtQ[ 6] + w_part_prod_sIxtQ[ 7] +
                       w_part_prod_sIxtQ[ 8] + w_part_prod_sIxtQ[ 9] + w_part_prod_sIxtQ[10] ;
  assign w_add_sQxtI = w_part_prod_sQxtI[ 0] + w_part_prod_sQxtI[ 1] + w_part_prod_sQxtI[ 2] + w_part_prod_sQxtI[ 3] +
                       w_part_prod_sQxtI[ 4] + w_part_prod_sQxtI[ 5] + w_part_prod_sQxtI[ 6] + w_part_prod_sQxtI[ 7] +
                       w_part_prod_sQxtI[ 8] + w_part_prod_sQxtI[ 9] + w_part_prod_sQxtI[10] ;


  // Compute final summed values for I and Q outputs
  assign  w_add_I    = w_add_sIxtI - w_add_sQxtQ;
  assign  w_add_Q    = w_add_sIxtQ + w_add_sQxtI;

  // Output assignment: Apply saturation and truncation to S(12,9) format
  assign o_os_data_I  = ( ~|w_add_I[(NBT_ADD-1) -: NB_SAT+1] || &w_add_I[(NBT_ADD-1) -: NB_SAT+1])
                        ? w_add_I[(NBT_ADD-1)-NB_SAT -: NBT_OUT]
                        :( (w_add_I[NBT_ADD-1])
                           ? { 1'b1, {(NBT_OUT-1){1'b0}} }
                           : { 1'b0, {(NBT_OUT-1){1'b1}} } );

  assign o_os_data_Q  = ( ~|w_add_Q[(NBT_ADD-1) -: NB_SAT+1] || &w_add_Q[(NBT_ADD-1) -: NB_SAT+1])
                        ? w_add_Q[(NBT_ADD-1)-NB_SAT -: NBT_OUT]
                        :( (w_add_Q[NBT_ADD-1])
                           ? { 1'b1, {(NBT_OUT-1){1'b0}} }
                           : { 1'b0, {(NBT_OUT-1){1'b1}} } );


endmodule

