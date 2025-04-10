/*
	* ======== Definition the finaly menu ========== 
	* 1 - Reset del DSP
	* 2 - Enbl or Disable Aaptive filter 
	* 3 - Log data in RAM 
	* 		|__ Data FSE (Input)  (Sub options)
	*			|__ Data input Slcr 
	*			|__ Data coeffs 
	*			|__ Data error
	*	4 - Read data from RAM 
	*	5 - Capture bits and err from PRBS 
	*	6 - Read bits and err from PRBS 
	*	7 - Finish program 
	* */

/*
 * Ejemplo selec de fase:  
 * 0x03 OPC principal 
 * 0x80 enbl del RF siempre va ese valor
 * 0x0A relleno  
 * 0x03 seccion de subopcion 
 * Trama completa ----- > 0x03800A03 Formato para tb
*/

//Error and Bits
//|   000   | ||LEI||
//|   001   | ||HEI||
//|   010   | ||LBI||
//|   011   | ||HBI||
//|   100   | ||LEQ||
//|   101   | ||HEQ||
//|   110   | ||LBQ||
//|   111   | ||HBQ||


/////////////////////////////////////////////////////////////////////////////
// Cosas a loguear: 	
// 1 - Entrada del FSE S(8,7) 							Tasa 2 BR*2 = 50 MHz
// 2 - Entrada del Slicer S(12,9)       	  Tasa 2 BR*2 = 50 MHz
// 3 - Coeficientes de I e Q S(28,25) 			Tasa 1 BR   = 25 MHz CON RETARDO 
// 4 - Entrada del error S(12,9) 						Tasa 1 BR		= 25 MHz 
///////////////////////////////////////////////////////////////////////////// 

module top_hw_custom
( 
//			//	Descomentar para testeo
//	   	input   							clockdsp								,
//	   	input   							i_reset 								,
//	   	input				 [	31:0] gpio_output_to_input_dsp, //	Estimulos de entrada para testeo
//			//	Salidas
//			output		   [	31:0] gpio_input_to_output_dsp									
	//-------Comnentar para simulacion----------- //
	input           clock100   ,   
  input           i_reset    ,
  input           in_rx_uart ,
  output          out_tx_uart    
);

  //___Parametros del TOP (SACAR PARA LA IMPLEMENTACION FINAL)
	parameter NBT_GPIOS        = 32;


	// ======= Conection MicroBlazer ========  // Comentar para Test bench
  wire                    locked     						  ;
  wire    	              soft_reset 						  ;
  wire [NBT_GPIOS- 1 : 0] gpio_input_to_output_dsp;	
  wire [NBT_GPIOS- 1 : 0] gpio_output_to_input_dsp;	
  wire                    clockdsp  							; 
  
  
	// ======= Conection ctrl_ram ========== //  
	// regs 
  reg  [ 2:0]	r_data_selec_for_log;
  reg       	r_enbl_write        ; 
	reg 				r_enbl_read_from_ram;
  reg  [15:0]	r_read_adrs     		;
	// wires
	wire [31:0]	w_data_ram_for_read ;	

 
	// ==== Conection Register File ==== // 
  reg        	r_reset      						 ;
	reg       	r_log_bits_and_errs    	 ;
  reg 				r_enbl_read_bits_and_errs;
//  reg	[ 3:0]	r_switch     			 			 ;
  reg [63:0]	r_count_err_Q			       ;
  reg [63:0]	r_count_err_I						 ;
  reg [63:0]	r_count_bit_Q						 ;
  reg [63:0]	r_count_bit_I						 ;
  reg [ 2:0]	r_mux_read_bits_and_errs ;
 

  // ========== Conection DSP ============= // 
  wire        [31:0] w_data_bits_and_errs;

	wire signed [	7:0] w_data_fse_I	 			 ;	
	wire signed [	7:0] w_data_fse_Q	 			 ;	
	wire signed [11:0] w_data_input_slcr_I ;									
	wire signed [11:0] w_data_input_slcr_Q ;		
	wire signed [87:0] w_data_coeff_I			 ;		
	wire signed [87:0] w_data_coeff_Q			 ;	
	wire signed [11:0] w_data_err_I	 			 ;	
	wire signed [11:0] w_data_err_Q	 			 ;	
  wire        [63:0] w_count_err_Q 			 ;
  wire        [63:0] w_count_err_I 			 ;
  wire        [63:0] w_count_bit_Q 			 ;
  wire        [63:0] w_count_bit_I 			 ;
 	wire  						 w_enbl_rate_two		 ;
	wire	  					 w_enbl_rate_one		 ;


	// ======= Conection VIO e ILA ==========
	wire w_reset_from_vio;


	//=======================================================
	// 										Instances 											 //
	//=======================================================


	//==========================================
	//            DSP Designe 								//
	//==========================================
	/*
	*		ISNTANCIAR DSP COMPLETO !!!!
	 */

//		//			   Descomentar para testeo 
//		//==========================================
//		//            Block for debug 						//
//		//==========================================
//	  table_for_log
//			u_table_for_log
//			(
//				.i_clock						(clockdsp						), 
//				.i_reset						(w_reset_from_vio 	), 
//				.o_data_fse_I				(w_data_fse_I	 			),
//				.o_data_fse_Q				(w_data_fse_Q	 			),
//				.o_data_input_slcr_I(w_data_input_slcr_I),	 
//				.o_data_input_slcr_Q(w_data_input_slcr_Q),
//				.o_data_coeff_I			(w_data_coeff_I			),
//				.o_data_coeff_Q			(w_data_coeff_Q			),
//				.o_data_err_I				(w_data_err_I	 			),
//				.o_data_err_Q				(w_data_err_Q	 			),
//				.o_count_bit_I			(w_count_bit_I 			), 
//				.o_count_bit_Q			(w_count_bit_Q 			), 				
//				.o_count_err_I			(w_count_err_I 			), 
//				.o_count_err_Q			(w_count_err_Q 			),
//				.o_enbl_rate_two		(w_enbl_rate_two		),  
//				.o_enbl_rate_one		(w_enbl_rate_one		)
//			
//			);


  ///////////////////////////////////////////
  // Logueo control for RAM
  ///////////////////////////////////////////  
  ctrl_ram
    u_ctrl_ram
			(
      	.i_clock							(clock100    				 ), // Cambiar a clockdsp para tb
 				.i_reset							(w_reset_from_vio    ),
				.i_data_selec_for_log	(r_data_selec_for_log), 
				.i_enbl_write					(r_enbl_write				 ),
				.i_enbl_read					(r_enbl_read_from_ram),
				.i_read_adrs	 				(r_read_adrs 				 ), 
				.i_data_fse_I					(w_data_fse_I				 ),
				.i_data_fse_Q					(w_data_fse_Q				 ),			
				.i_data_input_slcr_I	(w_data_input_slcr_I ),	
				.i_data_input_slcr_Q	(w_data_input_slcr_Q ),	
				.i_data_coeff_I				(w_data_coeff_I			 ),
				.i_data_coeff_Q				(w_data_coeff_Q			 ),
				.i_data_err_I					(w_data_err_I				 ),						
				.i_data_err_Q					(w_data_err_Q				 ),
				.i_enbl_rate_two			(w_enbl_rate_two	 	 ),
				.i_enbl_rate_one			(w_enbl_rate_one 		 ),
				.o_data_for_read			(w_data_ram_for_read )
				
			);



	//==========================================
	//            MicroBlazer 								//
	//==========================================
  MicroGPIO    
     u_MicroGPIO 
     (
        .clock100         (clockdsp    						 ),  // Clock aplicacion
        .gpio_rtl_tri_i   (gpio_input_to_output_dsp),  // GPIO input data
        .gpio_rtl_tri_o   (gpio_output_to_input_dsp),  // GPIO output data
        .o_lock_clock     (locked      						 ),  // Signal Lock Clock        
        .reset            (i_reset    						 ),  // Hard Reset
        .sys_clock        (clock100    						 ),  // Clock de FPGA
        .usb_uart_rxd     (in_rx_uart  						 ),  // UART Rx
        .usb_uart_txd     (out_tx_uart 						 )   // UART Tx
      );

	//==========================================
	//            VIO / ILA  						   		//
	//==========================================

  VIO
    u_VIO
    (
     .clk_0         (clock100 			 ),
     .probe_out0_0  (w_reset_from_vio)
     );

  ILA
   u_ILA
    (
     .clk_0    (clock100					 ), 
     .probe0_0 (w_data_fse_I			 ),  // FSE I  8  
     .probe1_0 (w_data_fse_Q			 ),  // FSE Q
     .probe2_0 (w_data_input_slcr_I),  // SLCR I 12
     .probe3_0 (w_data_input_slcr_Q),  // SLCR Q
     .probe4_0 (gpio_output_to_input_dsp)        
     );


	//==========================================
	//            Register file 						  //
	//==========================================


  always @(posedge clock100) begin // Cambiar clock100 por clockdsp para simulacion
     if(w_reset_from_vio == 1'b1) begin
        r_reset      							<= 1'b1 ;
//        r_switch     							<= 4'b0 ;
        r_data_selec_for_log		  <= 3'b0 ;
        r_enbl_write        		 	<= 1'b0 ;
				r_enbl_read_from_ram		  <= 1'b0 ;
        r_count_err_Q       			<= 64'b0;
        r_count_err_I       			<= 64'b0;
        r_count_bit_Q       		  <= 64'b0;
        r_count_bit_I       		  <= 64'b0;
        r_enbl_read_bits_and_errs	<= 1'b0 ;
				r_mux_read_bits_and_errs  <= 3'b0 ;
        r_log_bits_and_errs 		  <= 1'b0 ;
      //r_flag_capture 						<= 1'b0 ;
        r_read_adrs  							<= 16'b0;
     
     end
     else begin   
        if(gpio_output_to_input_dsp[23] == 1'b1)begin
            case (gpio_output_to_input_dsp[31:24])
                8'h01: r_reset        <= gpio_output_to_input_dsp[0]  ; 					// 0 Reset for DSP 
//                8'h02: r_switch[1:0]  <= gpio_output_to_input_dsp[1:0]; 				// 1 Enable Adaptive Filter ? 
                8'h03: 
											begin
                      	r_data_selec_for_log	<= gpio_output_to_input_dsp[2:0];	// 3 Login data in RAM,
												r_enbl_write					<= gpio_output_to_input_dsp[3]  ;	// Signal enbl for write data in RAM
						     				//paso_wave     				<= gpio_output_to_input_dsp[11:8];	// Selec frec (SACAR)
						     			end								 
                8'h04: 
											begin                          																// 4 Read data from RAM
                      	r_enbl_read_from_ram	<= gpio_output_to_input_dsp[16]	 ;      
                        r_read_adrs[15:0]			<= gpio_output_to_input_dsp[15:0];	// Addrs for read in RAM
                      end
                8'h05: 
											begin                           														// 5 Log bits and err from BER    
                      	r_log_bits_and_errs	<= gpio_output_to_input_dsp[0];
                        //r_flag_capture		<= r_log_bits_and_errs;
                      end
                8'h06:
											begin 
												r_mux_read_bits_and_errs	<= gpio_output_to_input_dsp[2:0];  // 6 Read bits and err 
												r_enbl_read_bits_and_errs <= gpio_output_to_input_dsp[3]	;
											end		
           endcase

           if (r_log_bits_and_errs) begin
                r_count_err_Q	<=	w_count_err_Q;	 
                r_count_err_I	<=	w_count_err_I;	 
                r_count_bit_Q <=	w_count_bit_Q; 	 
                r_count_bit_I <=	w_count_bit_I; 	 
            end 

        end //Fin de if(gpio_output_to_input_dsp[23] == 1'b1)
     end //Fin de else begin    
  end //Fin de always
																							                           
assign gpio_input_to_output_dsp	= (r_enbl_read_from_ram == 1'b1)	? w_data_ram_for_read : (r_enbl_read_bits_and_errs == 1'b1) 
																																	? w_data_bits_and_errs : 32'b0; // Selec data for Micro

assign w_data_bits_and_errs = (r_mux_read_bits_and_errs == 3'b000) ? r_count_err_I [31:0] : (r_mux_read_bits_and_errs == 3'b001) ? r_count_err_I [63:32] :
                         			(r_mux_read_bits_and_errs == 3'b010) ? r_count_bit_I [31:0] : (r_mux_read_bits_and_errs == 3'b011) ? r_count_bit_I [63:32] : // Bits and errs
                         			(r_mux_read_bits_and_errs == 3'b100) ? r_count_err_Q [31:0] : (r_mux_read_bits_and_errs == 3'b101) ? r_count_err_Q [63:32] :
                         			(r_mux_read_bits_and_errs == 3'b110) ? r_count_bit_Q [31:0] :  r_count_bit_Q  [63:32];

// assign w_enbl_log_bits_and_errs	=	r_log_bits_and_errs; 
endmodule


