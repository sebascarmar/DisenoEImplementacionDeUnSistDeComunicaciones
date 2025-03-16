//==============================================================================
// Author: Juarez Daniel 
// Date: 03/2025
// Description: This module adds the rotation of the data to the output of the 
//              filter.
//       (I+jQ)*(cos() + jsin()) I*cos + I jsin() + jQcos() - Qsin()  --- 
// --- I*cos() - Qsin() + j I.sin() + Qcos()
//==============================================================================

module add_rotation
#
(
	parameter  NB_OUTPUT   = 8 ,    // Integer part of output
	parameter  NBF_OUTPUT  = 7 ,    // Fractional part of output
	parameter  NB_COEFF    = 8 ,    // Integer part of coefficients
	parameter  NBF_COEFF   = 7      // Fractional part of coefficients
)
(
	input                              i_clock,       // clock
	input                              i_reset,       // reset 
	input  signed  [NB_OUTPUT-1:0]     i_dataI,       // input data I
	input  signed  [NB_OUTPUT-1:0]     i_dataQ,       // input data Q
	input  signed  [NB_OUTPUT-1:0]     i_dataSin,     // input data Sin
	input  signed  [NB_OUTPUT-1:0]     i_dataCos,     // input data Cos
	output signed [(NB_COEFF+NB_OUTPUT):0] o_data_rotated_full_Q,
	output signed [(NB_COEFF+NB_OUTPUT):0] o_data_rotated_full_I,	
	output signed [NB_OUTPUT-1:0]      o_dataRotatedI,// output data rotated I
	output signed [NB_OUTPUT-1:0]      o_dataRotatedQ // output data rotated Q    
);


//___Local parameters___//
localparam NB_ADD     = (NB_OUTPUT + NB_COEFF)+1;            // Total sum bits: 17 bits
localparam NBF_ADD    = (NBF_COEFF + NBF_OUTPUT)-2;          // Fractional part of sum: 12 bits                                                                                                    
localparam NBI_ADD    = NB_ADD    - NBF_ADD;                 // Difference between 17 and 12 = 5 bits
localparam NBI_OUTPUT = NB_OUTPUT - NBF_OUTPUT;              // Difference between 8 and 7 = 1 bit
localparam NB_SAT     = (NB_ADD-NBF_ADD)-(NB_OUTPUT-NBF_OUTPUT); // Saturation = 4 bits

//___Internal connections___//
wire signed [NB_OUTPUT+NB_COEFF-1:0] productoria  [3:0]; // Max resolution 
wire signed [NB_OUTPUT+NB_COEFF:0] sumatoria      [1:0]; // Max resolution



//___Partial products___//
assign productoria[0] = i_dataI * i_dataCos; // Partial product for output I 
assign productoria[1] = i_dataQ * i_dataSin;
assign productoria[2] = i_dataI * i_dataSin; // Partial product for output Q
assign productoria[3] = i_dataQ * i_dataCos; 

//___Sum of the partial products___//
assign sumatoria [0] = productoria[0] - productoria[1];    // Outputs to S(17,12), full resolution
assign sumatoria [1] = productoria[2] + productoria[3];

//___Saturation and truncation correction, from S(17,12) to S(8,7)___//

assign o_dataRotatedI = (~|sumatoria[0] [NB_ADD-1 -: NB_SAT+1] || &sumatoria[0] [NB_ADD-1 -: NB_SAT+1]) ? sumatoria[0] [NB_ADD-(NBI_ADD-NBI_OUTPUT) - 1 -: NB_OUTPUT] :
				 (sumatoria[0] [NB_ADD-1]) ? {{1'b1},{NB_OUTPUT-1{1'b0}}} : {{1'b0},{NB_OUTPUT-1{1'b1}}};

assign o_dataRotatedQ = (~|sumatoria[1] [NB_ADD-1 -: NB_SAT+1] || &sumatoria[1] [NB_ADD-1 -: NB_SAT+1]) ? sumatoria[1] [NB_ADD-(NBI_ADD-NBI_OUTPUT) - 1 -: NB_OUTPUT] :
				 (sumatoria[1] [NB_ADD-1]) ? {{1'b1},{NB_OUTPUT-1{1'b0}}} : {{1'b0},{NB_OUTPUT-1{1'b1}}};

assign o_data_rotated_full_I = sumatoria[0];
assign o_data_rotated_full_Q = sumatoria[1];

endmodule
