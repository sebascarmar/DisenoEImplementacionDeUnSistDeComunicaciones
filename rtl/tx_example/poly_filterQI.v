//=============================== POLY FILTER Q/I ================================
// AUTOR: Juarez Daniel 
// AÑO:   2025  
// NOMBRE: Modulo Poly filter Q/I  
//================================================================================
module poly_filterQI
  #(
    parameter NB_OUTPUT  = 8 , // Number of output bits
    parameter NBF_OUTPUT = 7 , // Number of fractional bits in the output
    parameter NB_COEFF   = 16, // Number of coefficient bits
    parameter NBF_COEFF  = 15, // Number of fractional bits in the coefficients
    parameter INIT_FILE  = ""    // File with the coefficients
  )
  (
    input                         clock       , // System clock
    input                         i_reset     , // System reset
    input                         i_enable    , // Enable signal
    input                         i_valid     , // Valid signal
    input                         i_dataPrbsI , // Input bit for channel I
    input                         i_dataPrbsQ , // Input bit for channel Q
    input       [2:0]             i_counterMux, // 2 bits used for selection

    output signed [NB_COEFF+2:0]  o_out_fir_full_Q, // Poly out full resolution Q
    output signed [NB_COEFF+2:0]  o_out_fir_full_I, // Poly out full resolution I
    output signed [NB_OUTPUT-1:0] o_out_firI,   // FIR output for channel I
    output signed [NB_OUTPUT-1:0] o_out_firQ    // FIR output for channel Q
  );

  // Local parameters
  localparam N_COEFFS   = 21;                   // Total number of coefficients
  localparam FIR_DEPTH  = (N_COEFFS + 3) >> 2;  // Number of groups (6 in this case)
  localparam RAM_WIDTH  = 8;
  localparam RAM_DEPTH  = N_COEFFS;  

  // Parameters for addition and saturation
  localparam NB_ADD     = NB_COEFF + ($clog2(N_COEFFS) - 1); // ND_ADD  = 19   
  localparam NBF_ADD    = NBF_COEFF;                         // NBF_ADD = 15          
  localparam NBI_ADD    = NB_ADD - NBF_ADD;                  // NBI_ADD = 4    
  localparam NBI_OUTPUT = NB_OUTPUT - NBF_OUTPUT;            // NBI_OUT = 1 
  localparam NB_SAT     = (NB_ADD - NBF_ADD) - (NB_OUTPUT - NBF_OUTPUT); // NB_SATA = 3

  // Coefficient memory: 21 coefficients of 16 bits each
  reg signed [NB_COEFF-1:0] Coeficientes [0:RAM_DEPTH-1];

  // Load coefficients from file (binary format)
  initial begin
    $readmemb(INIT_FILE, Coeficientes, 0, RAM_DEPTH-1);
  end

  // Signals for MUX output and multiplication (channel I)
  wire signed [NB_COEFF-1:0] out_muxI [0:FIR_DEPTH-1];
  wire signed [NB_COEFF-1:0] signedCoefI [0:FIR_DEPTH-1]; // Missing declaration in the original version

  // Signals for MUX output and multiplication (channel Q)
  wire signed [NB_COEFF-1:0] out_muxQ [0:FIR_DEPTH-1];
  wire signed [NB_COEFF-1:0] signedCoefQ [0:FIR_DEPTH-1];

  // Shift registers to store PRBS bits (for each channel)
  reg [FIR_DEPTH-1:0] registerI;
  reg [FIR_DEPTH-1:0] registerQ;

  // Shift register
  always @(posedge clock) begin : shiftRegister
      if (i_reset) begin
          registerI <= 0;
          registerQ <= 0;
      end else if (i_enable && (i_counterMux == 2'b01)) begin
          registerI <= {registerI[FIR_DEPTH-2:0], i_dataPrbsI};
          registerQ <= {registerQ[FIR_DEPTH-2:0], i_dataPrbsQ};
      end        
  end 

  // Coefficient multiplexing for channel I with index protection
  genvar idx;
  generate
    for (idx = 0; idx < FIR_DEPTH; idx = idx + 1) begin : MUX_I
      // For each group of 4 coefficients, check the limit (RAM_DEPTH)
      wire signed [NB_COEFF-1:0] coeff0 = ((idx*4 + 0) < RAM_DEPTH) ? Coeficientes[idx*4 + 0] : 0;
      wire signed [NB_COEFF-1:0] coeff1 = ((idx*4 + 1) < RAM_DEPTH) ? Coeficientes[idx*4 + 1] : 0;
      wire signed [NB_COEFF-1:0] coeff2 = ((idx*4 + 2) < RAM_DEPTH) ? Coeficientes[idx*4 + 2] : 0;
      wire signed [NB_COEFF-1:0] coeff3 = ((idx*4 + 3) < RAM_DEPTH) ? Coeficientes[idx*4 + 3] : 0;
      
      // Selection according to i_counterMux (assumed: 2'b10, 2'b11, 2'b00 and default 2'b01)
      assign out_muxI[idx] = (i_counterMux == 2'b10) ? coeff0  :
                             (i_counterMux == 2'b11) ? coeff1  :
                             (i_counterMux == 2'b00) ? coeff2  : coeff3;
      
      // Sign inversion according to the bit in the shift register
      // Assumed: 0 → positive coefficient, 1 → negative coefficient.
      assign signedCoefI[idx] = (registerI[idx] == 1'b0) ? out_muxI[idx] : -out_muxI[idx];
    end
  endgenerate

  // Coefficient multiplexing for channel Q with index protection
  generate
    for (idx = 0; idx < FIR_DEPTH; idx = idx + 1) begin : MUX_Q
      wire signed [NB_COEFF-1:0] coeff0 = ((idx*4 + 0) < RAM_DEPTH) ? Coeficientes[idx*4 + 0] : 0;
      wire signed [NB_COEFF-1:0] coeff1 = ((idx*4 + 1) < RAM_DEPTH) ? Coeficientes[idx*4 + 1] : 0;
      wire signed [NB_COEFF-1:0] coeff2 = ((idx*4 + 2) < RAM_DEPTH) ? Coeficientes[idx*4 + 2] : 0;
      wire signed [NB_COEFF-1:0] coeff3 = ((idx*4 + 3) < RAM_DEPTH) ? Coeficientes[idx*4 + 3] : 0;
      
      assign out_muxQ[idx] = (i_counterMux == 2'b10) ? coeff0  :
                             (i_counterMux == 2'b11) ? coeff1  :
                             (i_counterMux == 2'b00) ? coeff2  : coeff3;
      assign signedCoefQ[idx] = (registerQ[idx] == 1'b0) ? out_muxQ[idx] : -out_muxQ[idx];
    end
  endgenerate

  // Sum of partial products for each channel (combinational structure)
  reg signed [NB_ADD:0] partial_sumI;
  reg signed [NB_ADD:0] partial_sumQ;
  integer i;
  always @(*) begin
    partial_sumI = 0;
    partial_sumQ = 0;
    for (i = 0; i < FIR_DEPTH; i = i + 1) begin
      partial_sumI = partial_sumI + signedCoefI[i];
      partial_sumQ = partial_sumQ + signedCoefQ[i];
    end
  end

  // Assign sums (truncate or extend according to NB_ADD)
  wire signed [NB_ADD-1:0] sumI = partial_sumI[NB_ADD-1:0];
  wire signed [NB_ADD-1:0] sumQ = partial_sumQ[NB_ADD-1:0];

  // Saturation logic for FIR output (channel I)
  assign o_out_firI = ( ~|sumI[NB_ADD-1 -: NB_SAT+1] || &sumI[NB_ADD-1 -: NB_SAT+1]) ? 
                        sumI[NB_ADD-(NBI_ADD-NBI_OUTPUT) - 1 -: NB_OUTPUT] :
                        (sumI[NB_ADD-1]) ? {1'b1, {NB_OUTPUT-1{1'b0}}} : {1'b0, {NB_OUTPUT-1{1'b1}}};

  // Saturation logic for FIR output (channel Q)
  assign o_out_firQ = ( ~|sumQ[NB_ADD-1 -: NB_SAT+1] || &sumQ[NB_ADD-1 -: NB_SAT+1]) ? 
                        sumQ[NB_ADD-(NBI_ADD-NBI_OUTPUT) - 1 -: NB_OUTPUT] :
                        (sumQ[NB_ADD-1]) ? {1'b1, {NB_OUTPUT-1{1'b0}}} : {1'b0, {NB_OUTPUT-1{1'b1}}};

assign o_out_fir_full_Q = sumQ; // Output full resolution S(19,15)
assign o_out_fir_full_I = sumI; // Output full resolution S(19,15)


endmodule
