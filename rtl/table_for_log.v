//===================================================//
//	Modulo de prueba con tablas para logueo de datos //
//	y manejo de Tasas 															 //
//===================================================//

/////////////////////////////////////////////////////////////////////////////
// Cosas a loguear: 	
// 1 - Entrada del FSE S(8,7) 							Tasa 2 BR*2 = 50 MHz
// 2 - Entrada del Slicer S(12,9)       	  Tasa 1 BR   = 25 MHz
// 3 - Coeficientes de I e Q S(28,25) 			Tasa 1 BR   = 25 MHz CON RETARDO 
// 4 - Entrada del error S(12,9) 						Tasa 1 BR		= 25 MHz 
///////////////////////////////////////////////////////////////////////////// 

/*
  =========== Instance ============= 
  table_for_log	
		u_table_for_log
	(	
		.i_clock						(	), 
		.i_reset						(	), 
		.o_data_fse_I				( ),
		.o_data_fse_Q				( ),
		.o_data_input_slcr_I( ),	 
		.o_data_input_slcr_Q( ),
		.o_data_coeff_I			( ),
		.o_data_coeff_Q			( ),
		.o_data_err_I				( ),
		.o_data_err_Q				( ),
		.o_count_bit_I			( ), 
		.o_count_bit_Q			( ), 
		.o_count_err_I			( ), 
		.o_count_err_Q			( ) 
	);

	*/

`define NBT_FSE			 8	
`define NBT_SCLR		 12 
`define NBT_COEFF		 8 
`define NBT_ERRS 		 12
`define N_DEPTH_DATA 33	
`define N_COEFF 		 11 
`define FILE_FSE_I		"/home/danielito/Escritorio/CorreccionDeEfectosDeCanal/rtl/build/Ram_and_GPIO/Modulos/Data_for_Test/data_fse_I.dat" 
`define FILE_SLCR_I   "/home/danielito/Escritorio/CorreccionDeEfectosDeCanal/rtl/build/Ram_and_GPIO/Modulos/Data_for_Test/data_slcr_I.dat"
`define FILE_COEFF_I  "/home/danielito/Escritorio/CorreccionDeEfectosDeCanal/rtl/build/Ram_and_GPIO/Modulos/Data_for_Test/data_coeffs_I.dat"
`define FILE_ERR_I   	"/home/danielito/Escritorio/CorreccionDeEfectosDeCanal/rtl/build/Ram_and_GPIO/Modulos/Data_for_Test/data_err_I.dat"

module table_for_log
#(
	parameter NBT_FSE			 =	`NBT_FSE		 , 
	parameter NBT_SCLR		 =	`NBT_SCLR		 , 
	parameter NBT_COEFF		 =	`NBT_COEFF	 , 
	parameter NBT_ERRS 		 =	`NBT_ERRS 	 , 
	parameter N_DEPTH_DATA = 	`N_DEPTH_DATA, 
	parameter N_COEFF 		 =	`N_COEFF 	   , 
	parameter FILE_FSE_I 	 =	`FILE_FSE_I  , 
	parameter FILE_SLCR_I  =	`FILE_SLCR_I , 
	parameter FILE_COEFF_I =	`FILE_COEFF_I, 
	parameter FILE_ERR_I   =	`FILE_ERR_I    
)
(
	// Entradas
	input           i_clock, 
	input           i_reset, 
	// Salidas de datos
	output reg signed [						  NBT_FSE-1:0] o_data_fse_I       ,
	output reg signed [						  NBT_FSE-1:0] o_data_fse_Q       ,
	output reg signed [					  NBT_SCLR-1 :0] o_data_input_slcr_I,	 
	output reg signed [					  NBT_SCLR-1 :0] o_data_input_slcr_Q,
	output reg signed [(NBT_COEFF*N_COEFF)-1 :0] o_data_coeff_I		  ,
	output reg signed [(NBT_COEFF*N_COEFF)-1 :0] o_data_coeff_Q		  ,
	output reg signed [						NBT_ERRS-1 :0] o_data_err_I			  ,
	output reg signed [						NBT_ERRS-1 :0] o_data_err_Q	      ,
	// Salidas de contadores
	output reg        [63:0] o_count_bit_I, 
	output reg        [63:0] o_count_bit_Q, 
	output reg        [63:0] o_count_err_I,
	output reg        [63:0] o_count_err_Q,
	// Salidas de habilitación de tasa
	output                  o_enbl_rate_two, 
	output                  o_enbl_rate_one
);

	//========= Registros para contadores ===========
	reg [$clog2(N_DEPTH_DATA)-1:0] r_count_slcr_bits_errs; // Para SLCR, bits y errores
	reg [$clog2(N_DEPTH_DATA)-1:0] r_count_fse;            // Para FSE
	reg [$clog2(N_DEPTH_DATA)-1:0] r_count_coeffs;         // Para coeficientes (lectura en bloques de 11)
	reg [											1:0] r_count_max;            // Contador para las tasas
	reg                          	 r_enbl_rate_two;        // para 50MHz
	reg                          	 r_enbl_rate_one;        // para 25MHz
	reg [(NBT_COEFF*N_COEFF)-1:0]  temp_data_coeff;

	// integers
	integer i;



	//========= Registros para datos ===========
	reg signed [  (NBT_FSE-1):0]  r_data_fse_I       [0:N_DEPTH_DATA-1];
	reg signed [ (NBT_SCLR-1):0]  r_data_input_slcr_I[0:N_DEPTH_DATA-1];
	reg signed [ (NBT_SCLR-1):0]  r_data_err_I       [0:N_DEPTH_DATA-1];
	reg signed [(NBT_COEFF-1):0]  r_data_coeff_I     [0:N_DEPTH_DATA-1];

	//======= Registro para contador de bits y errores ========
	reg [63:0] r_count_bits_and_errs;

	//========= Bloque de inicialización ===========
	initial begin
		$readmemb(FILE_FSE_I	, r_data_fse_I			 , 0, N_DEPTH_DATA-1);
		$readmemb(FILE_SLCR_I	, r_data_input_slcr_I, 0, N_DEPTH_DATA-1);
		$readmemb(FILE_ERR_I	, r_data_err_I			 , 0, N_DEPTH_DATA-1);
		$readmemb(FILE_COEFF_I, r_data_coeff_I		 , 0, N_DEPTH_DATA-1);
	end 

	//========= Lógica de generación de tasas ===========
	always @(posedge i_clock) begin 
		if(i_reset) begin 
			r_count_max     <= 0;	 
			r_enbl_rate_two <= 0;	 
			r_enbl_rate_one <= 0;  
		end 
		else begin
			// Contador para selección de tasa
			if(r_count_max < 2'b11)
				r_count_max <= r_count_max + 1'b1; 
			else 
				r_count_max <= 2'b0;
			// Habilitación de tasas: 50MHz cuando el contador es par, 25MHz cuando es múltiplo de 4
			if(r_count_max % 2 == 0)
				r_enbl_rate_two <= 1'b1;   
			else 
				r_enbl_rate_two <= 1'b0;  
			if(r_count_max % 4 == 0)
				r_enbl_rate_one <= 1'b1;   
			else 
				r_enbl_rate_one <= 1'b0; 	
		end 		
	end // end always: generación de tasas

	//========= Lógica de salidas de datos (FSE, SLCR, ERR y COEFF) ===========
	always @(posedge i_clock) begin 
		if(i_reset) begin 	
			r_count_slcr_bits_errs <= 0;
			r_count_fse            <= 0; 
			// r_count_coeffs se actualiza en bloque aparte
		end  
		else begin 
			// Contador para datos FSE (tasa de 50MHz)
			if(r_count_fse < N_DEPTH_DATA && r_enbl_rate_two)
				r_count_fse <= r_count_fse + 1'b1;
			else if(r_count_fse == N_DEPTH_DATA && r_enbl_rate_two)
				r_count_fse <= 0; 

			// Contador para SLCR y ERR (tasa de 25MHz)
			if(r_count_slcr_bits_errs < N_DEPTH_DATA && r_enbl_rate_one)
				r_count_slcr_bits_errs <= r_count_slcr_bits_errs + 1'b1;
			else if(r_count_slcr_bits_errs == N_DEPTH_DATA && r_enbl_rate_one)
				r_count_slcr_bits_errs <= 0; 

			// Salida de datos FSE (50MHz)
			if (r_enbl_rate_two) begin 
				o_data_fse_I <= r_data_fse_I[r_count_fse];			    
				o_data_fse_Q <= ~r_data_fse_I[r_count_fse];			 
			end  
			else begin 
				o_data_fse_I <= o_data_fse_I; 
				o_data_fse_Q <= o_data_fse_Q; 		
			end  
			
			// Salida de datos SLCR y ERR (25MHz)
			if (r_enbl_rate_one) begin 
				o_data_input_slcr_I <= r_data_input_slcr_I[r_count_slcr_bits_errs];
				o_data_input_slcr_Q <= ~r_data_input_slcr_I[r_count_slcr_bits_errs];
				o_data_err_I        <= r_data_err_I[r_count_slcr_bits_errs];
				o_data_err_Q        <= ~r_data_err_I[r_count_slcr_bits_errs];
			end 
			else begin 
				o_data_input_slcr_I <= o_data_input_slcr_I;	 
				o_data_input_slcr_Q <= o_data_input_slcr_Q; 
				o_data_err_I        <= o_data_err_I;		 
				o_data_err_Q        <= o_data_err_Q;		 
			end
		end
	end // end always: salidas de datos FSE, SLCR y ERR


	//========= Actualización del contador de coeficientes en bloques de 11 (buffer circular) ===========
	always @(posedge i_clock) begin 
		if(i_reset) begin 
			r_count_coeffs <= 0;
		end  
		else if(r_enbl_rate_one) begin 
			if (r_count_coeffs + (N_COEFF-1) >= N_DEPTH_DATA) 
				r_count_coeffs <= 0;
			else 
				r_count_coeffs <= r_count_coeffs + (N_COEFF);
		end 
	end 

	//========= Lógica de concatenación de coeficientes usando un ciclo for y corrimientos ===========
	always @(posedge i_clock) begin

		if(i_reset) begin 
			temp_data_coeff = 0;
		end 
		else begin 
			if (r_enbl_rate_one) begin
				// Se concatenan 11 coeficientes de 28 bits, aplicando wrap-around cuando sea necesario
				for (i = 0; i < N_COEFF; i = i + 1) begin
					if (r_count_coeffs + i < N_DEPTH_DATA)
						temp_data_coeff = (temp_data_coeff << NBT_COEFF) | r_data_coeff_I[r_count_coeffs + i];
					else
						temp_data_coeff = (temp_data_coeff << NBT_COEFF) | r_data_coeff_I[r_count_coeffs + i - N_DEPTH_DATA];
				end
				o_data_coeff_I <= temp_data_coeff;
				// Se asigna                    
				o_data_coeff_Q <= ~temp_data_coeff;
			end
			else begin
				o_data_coeff_I <= o_data_coeff_I;
				o_data_coeff_Q <= o_data_coeff_Q;
			end
		end 
	end

	//========= Lógica para contadores de bits y errores ===========
	always @(posedge i_clock) begin
		if(i_reset) begin 
			r_count_bits_and_errs <= 64'h0;					
		end 
		else begin 
			if(r_count_bits_and_errs < 64'hFFFFFFFFFFFFFFFF) begin 		
				r_count_bits_and_errs <= r_count_bits_and_errs + 1'b1;		
				o_count_bit_I <= r_count_bits_and_errs;		
				o_count_bit_Q <= r_count_bits_and_errs;		
				o_count_err_I <= r_count_bits_and_errs + 1'b1;		
				o_count_err_Q <= r_count_bits_and_errs + 1'b1;
			end 
			else begin 
				r_count_bits_and_errs <= 64'h0;
			end 	
		end
	end // end always: contadores de bits y errores

	//========= Asignación de las señales de habilitación de tasa ===========
	assign o_enbl_rate_two = r_enbl_rate_two;
	assign o_enbl_rate_one = r_enbl_rate_one;



endmodule 
//		 
//		module table_for_log 
//		(
//			// 	
//			input		i_clock, 
//			input		i_reset, 
//		
//			output reg signed [	 7:0] o_data_fse_I				,
//			output reg signed [	 7:0] o_data_fse_Q				,
//			output reg signed [	12:0] o_data_input_slcr_I	,	 
//			output reg signed [	12:0] o_data_input_slcr_Q	,
//			output reg signed [	27:0] o_data_coeff_I			,
//			output reg signed [	27:0] o_data_coeff_Q			,
//			output reg signed [	12:0] o_data_err_I				,
//			output reg signed [	12:0] o_data_err_Q				,
//			output reg 			 	[	63:0] o_count_bit_I				, 
//			output reg    		[	63:0] o_count_bit_Q				, 
//			output reg    		[	63:0] o_count_err_I				,
//		output reg    		[	63:0] o_count_err_Q				,
//		output 										o_enbl_rate_two			, 
//		output										o_enbl_rate_one 		
//	
//	);
//	
//		
//		//========= Local parameters============
//		localparam N_DEPTH_DATA = 8000;
//		localparam FILE_FSE_I  					  = "/home/danielito/Escritorio/CorreccionDeEfectosDeCanal/rtl/build/Ram_and_GPIO/Modulos/Data_for_Test/data_fse_I.dat"   ;	
//	//	localparam FILE_FSE_Q  					  = "/home/danielito/Escritorio/CorreccionDeEfectosDeCanal/rtl/build/Ram_and_GPIO/Modulos/Data_for_Test/data_fse_Q.dat"   ;	
//		localparam FILE_SLCR_I 					  = "/home/danielito/Escritorio/CorreccionDeEfectosDeCanal/rtl/build/Ram_and_GPIO/Modulos/Data_for_Test/data_slcr_I.dat"  ;	
//	//	localparam FILE_SLCR_Q 					  = "/home/danielito/Escritorio/CorreccionDeEfectosDeCanal/rtl/build/Ram_and_GPIO/Modulos/Data_for_Test/data_slcr_Q.dat"  ;	
//		localparam FILE_COEFF_I					  = "/home/danielito/Escritorio/CorreccionDeEfectosDeCanal/rtl/build/Ram_and_GPIO/Modulos/Data_for_Test/data_coeffs_I.dat";	
//	//	localparam FILE_COEFF_Q					  = "/home/danielito/Escritorio/CorreccionDeEfectosDeCanal/rtl/build/Ram_and_GPIO/Modulos/Data_for_Test/data_coeffs_Q.dat";	
//		localparam FILE_ERR_I  					  = "/home/danielito/Escritorio/CorreccionDeEfectosDeCanal/rtl/build/Ram_and_GPIO/Modulos/Data_for_Test/data_err_I.dat"   ;	
//	//	localparam FILE_ERR_Q  					  = "/home/danielito/Escritorio/CorreccionDeEfectosDeCanal/rtl/build/Ram_and_GPIO/Modulos/Data_for_Test/data_err_Q.dat"   ;	
//	
//		//========= Registers 
//		reg [	$clog2(N_DEPTH_DATA)-1:0]	r_count_slcr_bits_errs	; // Count data slcr bista nd errs 
//		reg [	$clog2(N_DEPTH_DATA)-1:0]	r_count_fse							; // Count data fse 
//		reg [	$clog2(N_DEPTH_DATA)-1:0]	r_count_coeffs					; // Count data coeffs
//		reg [								 			 1:0]	r_count_max		 		 	 		;	// Count for rate's
//		reg 														r_enbl_rate_two 				;	// for 50MHz 
//		reg 														r_enbl_rate_one 				; // for 25MHz
//	
//	
//	
//		//============ Registers for datas ================
//		reg signed [	 7:0] r_data_fse_I			  [					  N_DEPTH_DATA-1:0];	
//	//	reg signed [	 7:0] r_data_fse_Q			  [					  N_DEPTH_DATA-1:0];	
//		reg signed [	12:0] r_data_input_slcr_I [N_DEPTH_DATA-1:0];	
//	//	reg signed [	12:0] r_data_input_slcr_Q [N_DEPTH_DATA-1:0];	
//		reg signed [	12:0] r_data_err_I			  [N_DEPTH_DATA-1:0];	
//	//	reg signed [	12:0] r_data_err_Q			  [N_DEPTH_DATA-1:0];	
//		reg signed [	27:0] r_data_coeff_I		  [				 N_DEPTH_DATA-1:0];	
//	//	reg signed [	27:0] r_data_coeff_Q		  [				 N_DEPTH_DATA-1:0];	
//	
//	
//		//======= Register for counter err and bits ========
//		reg 			 [  63:0]	r_count_bits_and_errs;
//	
//		//========= Init valures ===========
//		initial begin
//			$readmemb(FILE_FSE_I  , r_data_fse_I			 , 0, 					 N_DEPTH_DATA-1);
//	//		$readmemb(FILE_FSE_Q  , r_data_fse_Q			 , 0, 					 N_DEPTH_DATA-1);
//			$readmemb(FILE_SLCR_I , r_data_input_slcr_I, 0, N_DEPTH_DATA-1);
//	//		$readmemb(FILE_SLCR_Q , r_data_input_slcr_Q, 0, N_DEPTH_DATA-1);
//			$readmemb(FILE_ERR_I  , r_data_err_I			 , 0, N_DEPTH_DATA-1);
//	//		$readmemb(FILE_ERR_Q  , r_data_err_Q			 , 0, N_DEPTH_DATA-1);
//			$readmemb(FILE_COEFF_I, r_data_coeff_I		 , 0, 				N_DEPTH_DATA-1);
//	//		$readmemb(FILE_COEFF_Q, r_data_coeff_Q		 , 0, 				N_DEPTH_DATA-1);		
//		end 
//	
//		
//		// Logic counter and rate's
//		always @(posedge i_clock) begin 
//			if(i_reset) begin 
//				r_count_max		  <= 0;	 
//				r_enbl_rate_two	<= 0;	 
//				r_enbl_rate_one	<= 0;  
//			end 
//			else begin
//				// counter for rate's
//				if(r_count_max < 2'b11)
//					r_count_max	<= 	r_count_max + 1'b1; 
//				else r_count_max <= 2'b0;
//				// set enbls rate's
//				if(r_count_max % 2 == 0) r_enbl_rate_two <= 1'b1;   
//				else r_enbl_rate_two <= 1'b0;  
//				if(r_count_max % 4 == 0) r_enbl_rate_one <= 1'b1;   
//				else r_enbl_rate_one <= 1'b0; 	
//			end 		
//		end // end always  
//	
//	
//		// Logic for data output from log 
//		always @(posedge i_clock) begin 
//			if(i_reset) begin 	
//	
//				r_count_slcr_bits_errs <= 0;
//			  r_count_fse					   <= 0; 
//				r_count_coeffs			   <= 0;
//	
//			end  
//			else begin 
//					// Counter for assigned log data to output 
//				if(r_count_fse < N_DEPTH_DATA && r_enbl_rate_two) r_count_fse <= r_count_fse + 1'b1;
//				else if(r_count_fse == N_DEPTH_DATA && r_enbl_rate_two)  r_count_fse <= 0; 
//	
//				if(r_count_slcr_bits_errs < N_DEPTH_DATA && r_enbl_rate_one) r_count_slcr_bits_errs <= r_count_slcr_bits_errs + 1'b1;
//				else if(r_count_slcr_bits_errs == N_DEPTH_DATA && r_enbl_rate_one) r_count_slcr_bits_errs <= 0; 
//	
//				if(r_count_coeffs < N_DEPTH_DATA && r_enbl_rate_one) r_count_coeffs <= r_count_coeffs + 1'b1;
//				else if(r_count_coeffs == N_DEPTH_DATA && r_enbl_rate_one) r_count_coeffs <= 0; 
//	
//	
//				// rate 50MHz
//				if (r_enbl_rate_two) begin 
//					o_data_fse_I	<=	r_data_fse_I [r_count_fse];			    
//					o_data_fse_Q	<=	~r_data_fse_I[r_count_fse];			 
//	 		
//				end	// Rate 25 MHz 		
//				else begin 
//					o_data_fse_I			  <=	o_data_fse_I			 ; 
//					o_data_fse_Q			  <=	o_data_fse_Q			 ; 		
//	
//				end  
//				
//				if (r_enbl_rate_one) begin 
//					o_data_input_slcr_I <= r_data_input_slcr_I [r_count_slcr_bits_errs];
//					o_data_input_slcr_Q <= ~r_data_input_slcr_I[r_count_slcr_bits_errs];
//					o_data_err_I			  <= r_data_err_I			   [r_count_slcr_bits_errs];
//					o_data_err_Q			  <= ~r_data_err_I			 [r_count_slcr_bits_errs];
//					o_data_coeff_I		  <= r_data_coeff_I		   [			  r_count_coeffs];
//					o_data_coeff_Q		  <= ~r_data_coeff_I		 [			  r_count_coeffs];
//				end 
//				else begin 
//					o_data_input_slcr_I <=	o_data_input_slcr_I;	 
//					o_data_input_slcr_Q	<=	o_data_input_slcr_Q; 
//					o_data_coeff_I		 	<=	o_data_coeff_I		 ; 
//					o_data_coeff_Q		 	<=	o_data_coeff_Q		 ; 
//					o_data_err_I			 	<=	o_data_err_I			 ; 
//					o_data_err_Q			 	<=	o_data_err_Q			 ; 
//				end
//	
//			end
//		end // end always 
//	
//		// Logic for output bits and errs
//		always @(posedge i_clock) begin
//	
//			if(i_reset) begin 
//				r_count_bits_and_errs	<= 64'h0 ;					
//			end 
//			else begin 
//					
//				if(r_count_bits_and_errs < 64'hFFFFFFFFFFFFFFFF) begin 		
//					r_count_bits_and_errs <= r_count_bits_and_errs + 1'b1;		
//	
//					o_count_bit_I	<=	r_count_bits_and_errs 			;		
//					o_count_bit_Q <=	r_count_bits_and_errs			  ;		
//					o_count_err_I <=	r_count_bits_and_errs + 1'b1;		
//					o_count_err_Q <=	r_count_bits_and_errs + 1'b1;
//				end 
//				else begin 
//					r_count_bits_and_errs	<= 64'h0;
//				end 	
//	
//			end // else if(i_reset)
//	
//		end // end always 
//	
//		// Asign valid rate 
//		assign	o_enbl_rate_two = r_enbl_rate_two;
//		assign	o_enbl_rate_one = r_enbl_rate_one;
//	
//	
//	
//	
//	endmodule
