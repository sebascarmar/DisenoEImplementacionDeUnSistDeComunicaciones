//==============================================================================
// Author: Juarez Daniel 
// Date: 03/2025
// Description: This module generates a complete sine and cosine wave starting 
//				from 1/4 wave of each.Then, the generated waves are applied to 
//				the input data I and Q to generate a rotated output at a 
//				frequency set based on the i_step input.
// Instanciation: 
// 
//    top_phase_gen
//    #(
//        .READ_DEPTH   ( ),            
//        .READ_WIDTH   ( ),      
//        .NB_OUTPUT    ( ), 
//        .NBF_OUTPUT   ( ), 
//        .NB_COEFF     ( ), 
//        .NBF_COEFF    ( ), 
//        .INIT_FILE_SIN( ),      
//        .INIT_FILE_COS( )  		
//    )
//    u_top_phase_gen
//    (
//        .i_clock        ( ), 
//        .i_reset        ( ), 
//        .i_enable       ( ), 
//        .i_step         ( ), 
//        .i_dataI        ( ), 
//        .i_dataQ        ( ),          	
// 		  .o_ph_full_symbI( ),
// 		  .o_ph_full_symbQ( ),
//        .o_ph_symbI     ( ), 
//        .o_ph_symbQ     ( )  
//    );
//==============================================================================

module top_phase_gen
#(
    parameter READ_DEPTH = 2500, // Depth of the data            
    parameter READ_WIDTH = 8   , // Width of the data  
	parameter NB_INPUT   = 8   , // Bits coef
	parameter NBF_INPUT  = 6   , // Fractional bits coef	    
	parameter NB_OUTPUT  = 8   , // Bits output
	parameter NBF_OUTPUT = 6   , // Fractional bits output
	parameter INIT_FILE_SIN = "/home/danielito/Escritorio/run/FaceGenerator/Modules/CuartoSin.dat", // path to the file with the data     
	parameter INIT_FILE_COS = "/home/danielito/Escritorio/run/FaceGenerator/Modules/CuartoCos.dat"  // 		
)
(
    input 					      i_clock   , // system clock 
    input 					      i_reset   , // system reset 
	input					      i_enable  , // enbable module 
	input 		  [7:0] 	      i_step    , // input step for the wave 
    input  signed [NB_OUTPUT-1:0] i_dataI   , // input data I 
    input  signed [NB_OUTPUT-1:0] i_dataQ   , // input data Q     
	output signed [NB_INPUT+NB_OUTPUT:0] o_ph_full_symbI , // output full    
	output signed [NB_INPUT+NB_OUTPUT:0] o_ph_full_symbQ , // output full 	
	output signed [NB_OUTPUT-1:0] 		 o_ph_symbI	     , // output rotated I 
	output signed [NB_OUTPUT-1:0] 		 o_ph_symbQ	        // output rotated Q 
);

//___connections___//	
wire signed [READ_WIDTH-1:0] data_out_sin;
wire signed [READ_WIDTH-1:0] data_out_cos;

wire signed [NB_OUTPUT-1:0] data_out_rot_I;
wire signed [NB_OUTPUT-1:0] data_out_rot_Q;

wire signed [(NB_INPUT+NB_OUTPUT):0] data_full_out_rot_I;
wire signed [(NB_INPUT+NB_OUTPUT):0] data_full_out_rot_Q;

localparam [7:0] paso_wave = 0; // VALUE THAT SHOULD COME FROM RF

//========================================
//  Modulo WaveSinAndCos
//========================================
wave_sin_and_cos
	#(
        .READ_WIDTH	  (READ_WIDTH   ),     
        .READ_DEPTH	  (READ_DEPTH   ),
		.INIT_FILE_SIN(INIT_FILE_SIN),
		.INIT_FILE_COS(INIT_FILE_COS)			
	)
	u_wave_sin_and_cos
		(
		.i_clock   (i_clock      ),
		.i_reset   (i_reset      ),
		.i_enable  (i_enable     ),
		.i_step    (paso_wave    ),
		.o_dataSin (data_out_sin),   
		.o_dataCos (data_out_cos)         		
	);

//=========================================
//  Modulo Datafilter
//=========================================
add_rotation
	#(
 		.NB_OUTPUT 	 (NB_OUTPUT	), 
 		.NBF_OUTPUT	 (NBF_OUTPUT), 
 		.NB_COEFF  	 (NB_INPUT	), 
 		.NBF_COEFF   (NBF_INPUT	) 
	)
	u_add_rotation
	( 
		.i_clock    	(i_clock			),
		.i_reset    	(i_reset			),
		.i_dataI		(i_dataI			),
		.i_dataQ		(i_dataQ			),
		.i_dataSin   	(data_out_sin	    ),
		.i_dataCos   	(data_out_cos	    ),
		.o_data_rotated_full_I(data_full_out_rot_I),
		.o_data_rotated_full_Q(data_full_out_rot_Q),		
		.o_dataRotatedI (data_out_rot_I),
		.o_dataRotatedQ (data_out_rot_Q)
	);

assign o_ph_full_symbI = data_full_out_rot_I;
assign o_ph_full_symbQ = data_full_out_rot_Q;

assign o_ph_symbI = data_out_rot_I;
assign o_ph_symbQ = data_out_rot_Q;

endmodule
