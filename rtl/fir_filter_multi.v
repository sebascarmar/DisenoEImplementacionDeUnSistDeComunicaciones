`timescale 1ns/1ps


module fir_filter_multi
#(
    parameter NUM_COEFF    = 17, 
    parameter FILE_COEFF_0 = "",
    parameter FILE_COEFF_1 = "",
    parameter FILE_COEFF_2 = "",
    parameter FILE_COEFF_3 = "",
    parameter NBT_IN       =  8, 
    parameter NBF_IN       =  7, 
    parameter NBT_COEFF    =  8, 
    parameter NBF_COEFF    =  7, 
    parameter NBT_OUT      =  8, 
    parameter NBF_OUT      =  7 
)
(
    output signed [NBT_OUT-1:0] o_os_data , 
    
    input         [        1:0] i_sel_taps,
    input  signed [ NBT_IN-1:0] i_is_data ,
    input                       i_en      ,
    input                       i_reset   ,
    input                       clk       
);

  // Local parameters for internal operations and output saturation
  localparam NBT_PROD = NBT_IN + NBT_COEFF          ;
  localparam NBF_PROD = NBF_IN + NBF_COEFF          ;

  localparam NBT_ADD  = NBT_PROD + $clog2(NUM_COEFF);
  localparam NBF_ADD  = NBF_PROD                    ;
  localparam NBI_ADD  = NBT_ADD - NBF_PROD          ;
  localparam NBI_OUT  = NBT_OUT - NBF_OUT           ;
  localparam NB_SAT   = NBI_ADD - NBI_OUT           ; 

  // Internal registers and wires
  reg  signed [   NBT_IN-1:0] r_shifter  [NUM_COEFF-1:0]; 
  reg  signed [NBT_COEFF-1:0] r_coeff_0  [NUM_COEFF-1:0];
  reg  signed [NBT_COEFF-1:0] r_coeff_1  [NUM_COEFF-1:0];
  reg  signed [NBT_COEFF-1:0] r_coeff_2  [NUM_COEFF-1:0];
  reg  signed [NBT_COEFF-1:0] r_coeff_3  [NUM_COEFF-1:0];
  reg  signed [NBT_COEFF-1:0] r_coeff    [NUM_COEFF-1:0];
  reg  signed [ NBT_PROD-1:0] r_part_prod[NUM_COEFF-1:0];
  reg  signed [  NBT_ADD-1:0] w_sum1_a                  ;
  reg  signed [  NBT_ADD-1:0] w_sum1_b                  ;
  reg  signed [  NBT_ADD-1:0] w_sum1_c                  ;
  reg  signed [  NBT_ADD-1:0] w_sum1_d                  ;
  reg  signed [  NBT_ADD-1:0] r_sum1_a                  ;
  reg  signed [  NBT_ADD-1:0] r_sum1_b                  ;
  reg  signed [  NBT_ADD-1:0] r_sum1_c                  ;
  reg  signed [  NBT_ADD-1:0] r_sum1_d                  ;
  reg  signed [  NBT_ADD-1:0] r_sum2_a                  ;
  reg  signed [  NBT_ADD-1:0] r_sum2_b                  ;
  reg  signed [  NBT_ADD-1:0] r_sum_final               ;
  
  // Load the filter coefficient values
  initial begin
    $readmemb (FILE_COEFF_0, r_coeff_0);    
    $readmemb (FILE_COEFF_1, r_coeff_1);    
    $readmemb (FILE_COEFF_2, r_coeff_2);    
    $readmemb (FILE_COEFF_3, r_coeff_3);    
  end   

  // Select filter taps
  integer m;
  always @(posedge clk) begin
    if (i_sel_taps == 2'b00) begin
        for (m=0; m<NUM_COEFF ; m=m+1)
          r_coeff[m] <= r_coeff_0[m];
    end
    else if (i_sel_taps == 2'b01) begin
        for (m=0; m<NUM_COEFF ; m=m+1)
          r_coeff[m] <= r_coeff_1[m];
    end
    else if (i_sel_taps == 2'b10) begin
        for (m=0; m<NUM_COEFF ; m=m+1)
          r_coeff[m] <= r_coeff_2[m];
    end
    else begin // i_sel_taps == 2'b11
        for (m=0; m<NUM_COEFF ; m=m+1)
          r_coeff[m] <= r_coeff_3[m];
    end 

  end


  // Shift register: Sequentially updates input samples
  integer i;
  always @(posedge clk) begin
    if (i_reset==1'b1 || i_en==1'b0) begin
        for (i=0 ; i< NUM_COEFF ; i=i+1) begin
            r_shifter[i] <= {NBT_IN{1'b0}};
        end
    end
    else begin
        for (i=0 ; i< NUM_COEFF ; i=i+1) begin:shift
            if (i==0) begin
                r_shifter[i] <= i_is_data;
            end
            else begin
                r_shifter[i] <= r_shifter[i-1];
            end   
        end
    end
  end


  // Compute partial products 
  integer j;
  always @(posedge clk) begin
    if (i_reset==1'b1 || i_en==1'b0) begin
        for (j=0 ; j< NUM_COEFF ; j=j+1) begin
            r_part_prod[j] <= {NBT_PROD{1'b0}};
        end
    end
    else begin
        for (j=0; j<NUM_COEFF ; j=j+1) begin
            r_part_prod[j] <= r_shifter[j] * r_coeff[j];
        end
    end
  end


  // SUM OF PARTIAL PRODUCTOS IN 3 STAGES

  ////Sum all partial products in 4 groups
  integer k;
  always @(*) begin
      w_sum1_a = 0;
      w_sum1_b = 0;
      w_sum1_c = 0;
      w_sum1_d = 0;
      for (k=0 ; k<NUM_COEFF ; k=k+1) begin
          if (k<5) begin
              w_sum1_a = w_sum1_a + r_part_prod[k];
          end
          else if (k<9) begin
              w_sum1_b = w_sum1_b + r_part_prod[k];
          end
          else if (k<13) begin
              w_sum1_c = w_sum1_c + r_part_prod[k];
          end
          else begin
              w_sum1_d = w_sum1_d + r_part_prod[k];
          end
      end
  end
  ////Register the 4 groups
  always @(posedge clk) begin
      if (i_reset==1'b1 || i_en==1'b0) begin
          r_sum1_a <= {NBT_ADD{1'b0}};
          r_sum1_b <= {NBT_ADD{1'b0}};
          r_sum1_c <= {NBT_ADD{1'b0}};
          r_sum1_d <= {NBT_ADD{1'b0}};
      end
      else begin
          r_sum1_a <= w_sum1_a;
          r_sum1_b <= w_sum1_b;
          r_sum1_c <= w_sum1_c;
          r_sum1_d <= w_sum1_d;
      end
  end


  ////Combine the 4 groups into 2 intermediate sums
  always @(posedge clk) begin
      if (i_reset==1'b1 || i_en==1'b0) begin
          r_sum2_a <= {NBT_ADD{1'b0}};
          r_sum2_b <= {NBT_ADD{1'b0}};
      end
      else begin
          r_sum2_a <= r_sum1_a+r_sum1_b;
          r_sum2_b <= r_sum1_c+r_sum1_d;
      end
  end

  
  ////Add the 2 intermediate sums to produce the final result
  always @(posedge clk) begin
      if (i_reset==1'b1 || i_en==1'b0) begin
          r_sum_final <= {NBT_ADD{1'b0}};
      end
      else begin
          r_sum_final <= r_sum2_a+r_sum2_b;
      end
  end



  // Output assignment: Apply saturation and truncation to S(8,7) format
  assign o_os_data  = ( ~|r_sum_final[(NBT_ADD-1) -: NBI_ADD] || &r_sum_final[(NBT_ADD-1) -: NBI_ADD])
                        ? r_sum_final[(NBT_ADD-1)-NB_SAT -: NBT_OUT]
                        :( (r_sum_final[NBT_ADD-1])
                           ? { 1'b1, {(NBT_OUT-1){1'b0}} }
                           : { 1'b0, {(NBT_OUT-1){1'b1}} } );

endmodule


