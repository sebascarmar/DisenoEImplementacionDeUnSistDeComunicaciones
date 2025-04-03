`timescale 1ns/1ps


module fir_filter
#(
    parameter NUM_COEFF  = 17, 
    parameter FILE_COEFF = "",
    parameter NBT_IN     =  8, 
    parameter NBF_IN     =  7, 
    parameter NBT_COEFF  =  8, 
    parameter NBF_COEFF  =  7, 
    parameter NBT_OUT    =  8, 
    parameter NBF_OUT    =  7 
)
(
    output signed [NBT_OUT-1:0] o_os_data, 
    
    input  signed [ NBT_IN-1:0] i_is_data,
    input                       i_en     ,
    input                       i_reset  ,
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
  reg  signed [NBT_COEFF-1:0] r_coeff    [NUM_COEFF-1:0];
  wire signed [ NBT_PROD-1:0] w_part_prod[NUM_COEFF-1:0];
  reg  signed [  NBT_ADD-1:0] w_add                     ;
  
  // Load the filter coefficient values
  initial begin
    $readmemb (FILE_COEFF, r_coeff);    
  end   


  // Shift register: Sequentially updates input bits (representing QPSK symbols)
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


  // Compute partial products based on filter phase and stored symbols (1 or -1)
  genvar j;
  generate
      for (j=0; j<NUM_COEFF ; j=j+1) begin : multiply
          assign w_part_prod[j] = r_shifter[j] * r_coeff[j];
      end
  endgenerate

  // Add all the partial products
  integer k;
  always @(*) begin
    w_add = 0;
    for (k=0 ; k<NUM_COEFF ; k=k+1) begin
        w_add = w_add + w_part_prod[k];
    end
  end

  // Output assignment: Apply saturation and truncation to S(8,7) format
  assign o_os_data  = ( ~|w_add[(NBT_ADD-1) -: NBI_ADD] || &w_add[(NBT_ADD-1) -: NBI_ADD])
                        ? w_add[(NBT_ADD-1)-NB_SAT -: NBT_OUT]
                        :( (w_add[NBT_ADD-1])
                           ? { 1'b1, {(NBT_OUT-1){1'b0}} }
                           : { 1'b0, {(NBT_OUT-1){1'b1}} } );

endmodule

