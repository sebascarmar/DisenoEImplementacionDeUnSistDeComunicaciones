`timescale 1ns/1ps


module fse #(
  parameter NUM_TAPS =  9,
  parameter NBT_IN   =  8,
  parameter NBF_IN   =  7,
  parameter NBT_TAPS = 10,
  parameter NBF_TAPS =  7,
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
  input                                  i_ctrl     ,
  input                                  i_en_taps  ,
  input                                  i_en_rx    ,
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
  localparam NBI_TAPS = NBT_TAPS - NBF_TAPS        ;


  // Internal registers and wires
  reg  signed [     NBT_IN-1:0] r_shifter_I       [NUM_TAPS-1:0]; 
  reg  signed [     NBT_IN-1:0] r_shifter_Q       [NUM_TAPS-1:0]; 
  reg  signed [   NBT_TAPS-1:0] r_taps_I          [NUM_TAPS-1:0];
  reg  signed [   NBT_TAPS-1:0] r_taps_Q          [NUM_TAPS-1:0];
  reg  signed [   NBT_PROD-1:0] r_part_prod_sIxtI [NUM_TAPS-1:0];
  reg  signed [   NBT_PROD-1:0] r_part_prod_sQxtI [NUM_TAPS-1:0];
  reg  signed [   NBT_PROD-1:0] r_part_prod_sIxtQ [NUM_TAPS-1:0];
  reg  signed [   NBT_PROD-1:0] r_part_prod_sQxtQ [NUM_TAPS-1:0];
  reg  signed [    NBT_ADD-1:0] w_sum_sIxtI_A                   ;
  reg  signed [    NBT_ADD-1:0] w_sum_sQxtQ_A                   ;
  reg  signed [    NBT_ADD-1:0] w_sum_sIxtQ_A                   ;
  reg  signed [    NBT_ADD-1:0] w_sum_sQxtI_A                   ;
  reg  signed [    NBT_ADD-1:0] w_sum_sIxtI_B                   ;
  reg  signed [    NBT_ADD-1:0] w_sum_sQxtQ_B                   ;
  reg  signed [    NBT_ADD-1:0] w_sum_sIxtQ_B                   ;
  reg  signed [    NBT_ADD-1:0] w_sum_sQxtI_B                   ;
  reg  signed [    NBT_ADD-1:0] r_sum_sIxtI_A                   ;
  reg  signed [    NBT_ADD-1:0] r_sum_sQxtQ_A                   ;
  reg  signed [    NBT_ADD-1:0] r_sum_sIxtQ_A                   ;
  reg  signed [    NBT_ADD-1:0] r_sum_sQxtI_A                   ;
  reg  signed [    NBT_ADD-1:0] r_sum_sIxtI_B                   ;
  reg  signed [    NBT_ADD-1:0] r_sum_sQxtQ_B                   ;
  reg  signed [    NBT_ADD-1:0] r_sum_sIxtQ_B                   ;
  reg  signed [    NBT_ADD-1:0] r_sum_sQxtI_B                   ;
  reg  signed [    NBT_ADD-1:0] r_sum_sIxtI                     ;
  reg  signed [    NBT_ADD-1:0] r_sum_sQxtQ                     ;
  reg  signed [    NBT_ADD-1:0] r_sum_sIxtQ                     ;
  reg  signed [    NBT_ADD-1:0] r_sum_sQxtI                     ;
  reg  signed [(NBT_ADD+1)-1:0] r_sum_final_I                   ;
  reg  signed [(NBT_ADD+1)-1:0] r_sum_final_Q                   ;


  // Shift register: Sequentially updates input samples at rate 2
  integer i;
  always @(posedge clk) begin
    if (i_reset==1'b1 || i_en_rx==1'b0) begin
        for (i=0 ; i<NUM_TAPS ; i=i+1) begin
            r_shifter_I[i] <= {NBT_IN{1'b0}};
            r_shifter_Q[i] <= {NBT_IN{1'b0}};
        end
    end
    else begin
        if (i_ctrl==1'b1) begin // Update shifter at rate 2
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

  // FSE taps registers: converts a packed 1D input into a 2D register array, updating at rate 1 (BR)
  genvar j;
  localparam MID_IDX = NUM_TAPS/2;
  generate
      for (j=0 ; j<NUM_TAPS ; j=j+1) begin
          always @(posedge clk) begin
            if (i_reset==1'b1 || i_en_rx==1'b0) begin
                r_taps_I[j] <= (j==MID_IDX) ? { {(NBI_TAPS-1){1'b0}} , 1'b1 , {NBF_TAPS{1'b0}} } : {NBT_TAPS{1'b0}};
                r_taps_Q[j] <= {NBT_TAPS{1'b0}};
            end
            else begin
                if (i_en_taps) begin
                    r_taps_I[j] <= i_taps_I[(j+1)*NBT_TAPS-1 : j*NBT_TAPS];
                    r_taps_Q[j] <= i_taps_Q[(j+1)*NBT_TAPS-1 : j*NBT_TAPS];
                end
                else begin
                    r_taps_I[j] <= r_taps_I[j];
                    r_taps_Q[j] <= r_taps_Q[j];
                end
            end
          end
      end
  endgenerate

  // Compute partial products between input samples and filter coefficients
  integer k;
  always @(posedge clk) begin
    if (i_reset==1'b1 || i_en_rx==1'b0) begin
        for (k=0 ; k<NUM_TAPS ; k=k+1) begin
            r_part_prod_sIxtI[k] <= {NBT_PROD{1'b0}};
            r_part_prod_sQxtQ[k] <= {NBT_PROD{1'b0}};
            r_part_prod_sIxtQ[k] <= {NBT_PROD{1'b0}};
            r_part_prod_sQxtI[k] <= {NBT_PROD{1'b0}};
        end
    end
    else begin
        for (k=0 ; k<NUM_TAPS ; k=k+1) begin
            r_part_prod_sIxtI[k] <= r_shifter_I[k] * r_taps_I[k];
            r_part_prod_sQxtQ[k] <= r_shifter_Q[k] * r_taps_Q[k];
            r_part_prod_sIxtQ[k] <= r_shifter_I[k] * r_taps_Q[k];
            r_part_prod_sQxtI[k] <= r_shifter_Q[k] * r_taps_I[k];
        end
    end
  end


  // Sum of partial products in 3 stages

  ////1st level: sum all partial products into 2 groups
  integer m;
  always @(*) begin
    w_sum_sIxtI_A = 0;
    w_sum_sQxtQ_A = 0;
    w_sum_sIxtQ_A = 0;
    w_sum_sQxtI_A = 0;
    w_sum_sIxtI_B = 0;
    w_sum_sQxtQ_B = 0;
    w_sum_sIxtQ_B = 0;
    w_sum_sQxtI_B = 0;
    for (m=0 ; m<NUM_TAPS ; m=m+1) begin
        if (m<NUM_TAPS/2) begin
            w_sum_sIxtI_A = w_sum_sIxtI_A + r_part_prod_sIxtI[m];
            w_sum_sQxtQ_A = w_sum_sQxtQ_A + r_part_prod_sQxtQ[m];
            w_sum_sIxtQ_A = w_sum_sIxtQ_A + r_part_prod_sIxtQ[m];
            w_sum_sQxtI_A = w_sum_sQxtI_A + r_part_prod_sQxtI[m];
        end
        else begin
            w_sum_sIxtI_B = w_sum_sIxtI_B + r_part_prod_sIxtI[m];
            w_sum_sQxtQ_B = w_sum_sQxtQ_B + r_part_prod_sQxtQ[m];
            w_sum_sIxtQ_B = w_sum_sIxtQ_B + r_part_prod_sIxtQ[m];
            w_sum_sQxtI_B = w_sum_sQxtI_B + r_part_prod_sQxtI[m];
        end
    end
  end
  ////1st level: register the 2 groups for each partial product type
  always @(posedge clk) begin
      if (i_reset==1'b1 || i_en_rx==1'b0) begin
          r_sum_sIxtI_A <= {(NBT_ADD){1'b0}};
          r_sum_sQxtQ_A <= {(NBT_ADD){1'b0}};
          r_sum_sIxtQ_A <= {(NBT_ADD){1'b0}};
          r_sum_sQxtI_A <= {(NBT_ADD){1'b0}};
          r_sum_sIxtI_B <= {(NBT_ADD){1'b0}};
          r_sum_sQxtQ_B <= {(NBT_ADD){1'b0}};
          r_sum_sIxtQ_B <= {(NBT_ADD){1'b0}};
          r_sum_sQxtI_B <= {(NBT_ADD){1'b0}};
      end
      else begin
          r_sum_sIxtI_A <= w_sum_sIxtI_A;
          r_sum_sQxtQ_A <= w_sum_sQxtQ_A;
          r_sum_sIxtQ_A <= w_sum_sIxtQ_A;
          r_sum_sQxtI_A <= w_sum_sQxtI_A;
          r_sum_sIxtI_B <= w_sum_sIxtI_B;
          r_sum_sQxtQ_B <= w_sum_sQxtQ_B;
          r_sum_sIxtQ_B <= w_sum_sIxtQ_B;
          r_sum_sQxtI_B <= w_sum_sQxtI_B;
      end
  end

  ////2nd level: combine each pair of groups into final convolution sums
  always @(posedge clk) begin
      if (i_reset==1'b1 || i_en_rx==1'b0) begin
          r_sum_sIxtI <= {(NBT_ADD){1'b0}};
          r_sum_sQxtQ <= {(NBT_ADD){1'b0}};
          r_sum_sIxtQ <= {(NBT_ADD){1'b0}};
          r_sum_sQxtI <= {(NBT_ADD){1'b0}};
      end
      else begin
          r_sum_sIxtI <= r_sum_sIxtI_A+r_sum_sIxtI_B;
          r_sum_sQxtQ <= r_sum_sQxtQ_A+r_sum_sQxtQ_B;
          r_sum_sIxtQ <= r_sum_sIxtQ_A+r_sum_sIxtQ_B;
          r_sum_sQxtI <= r_sum_sQxtI_A+r_sum_sQxtI_B;
      end
  end

  ////3rd level: register the final I and Q output values
  always @(posedge clk) begin
      if (i_reset==1'b1 || i_en_rx==1'b0) begin
          r_sum_final_I <= {(NBT_ADD+1){1'b0}};
          r_sum_final_Q <= {(NBT_ADD+1){1'b0}};
      end
      else begin
          r_sum_final_I <= r_sum_sIxtI - r_sum_sQxtQ;
          r_sum_final_Q <= r_sum_sIxtQ + r_sum_sQxtI;
      end
  end



  // Output assignments: Apply saturation and truncation to S(12,9) format
  assign o_os_data_I  = ( ~|r_sum_final_I[(NBT_ADD-1) -: NB_SAT+1] || &r_sum_final_I[(NBT_ADD-1) -: NB_SAT+1])
                        ? r_sum_final_I[(NBT_ADD-1)-NB_SAT -: NBT_OUT]
                        :( (r_sum_final_I[NBT_ADD-1])
                           ? { 1'b1, {(NBT_OUT-1){1'b0}} }
                           : { 1'b0, {(NBT_OUT-1){1'b1}} } );

  assign o_os_data_Q  = ( ~|r_sum_final_Q[(NBT_ADD-1) -: NB_SAT+1] || &r_sum_final_Q[(NBT_ADD-1) -: NB_SAT+1])
                        ? r_sum_final_Q[(NBT_ADD-1)-NB_SAT -: NBT_OUT]
                        :( (r_sum_final_Q[NBT_ADD-1])
                           ? { 1'b1, {(NBT_OUT-1){1'b0}} }
                           : { 1'b0, {(NBT_OUT-1){1'b1}} } );


endmodule

