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

`define	NBT_I_EQLZR         8	
`define	NBT_O_EQLZR        12	
`define	NUM_TAPS            9	
`define	NBT_TAPS            8	
`define	NBT_GPIOS          32	
`define	NBT_COUNT_BITS_ERR 64 


module top #(
  parameter NBT_I_EQLZR        = `NBT_I_EQLZR       ,	 
  parameter NBT_O_EQLZR        = `NBT_O_EQLZR       ,
  parameter NBT_TAPS           = `NBT_TAPS          ,
  parameter NBT_GPIOS          = `NBT_GPIOS         ,
  parameter NBT_COUNT_BITS_ERR = `NBT_COUNT_BITS_ERR,	
  parameter NUM_TAPS           = `NUM_TAPS 					
)
( 
//// Descomentar para testeo
//input         clockdsp                ,
//input         i_reset                 ,
//input  [31:0] gpio_output_to_input_dsp, //	Estimulos de entrada para testeo
//output [31:0] gpio_input_to_output_dsp
//// Comentar para testeo
  output       o_tx_uart   ,
  output [3:0] o_normal_led,

  input        i_rx_uart   ,
  input        i_sw        ,
  input        i_reset     ,	
  input        clk
);


	// ======= Conection MicroBlazer ========  // Comentar para Test bench
  wire                    locked                  ;
  wire                    soft_reset              ;
  wire [NBT_GPIOS- 1 : 0] gpio_input_to_output_dsp;	
  wire [NBT_GPIOS- 1 : 0] gpio_output_to_input_dsp;	
  wire                    clockdsp                ; 
  
  
	// ======= Conection ctrl_ram ========== //  
	// regs 
  reg                   r_enbl_write        ; 
  reg                   r_enbl_read_from_ram;
  reg  [           2:0] r_data_selec_for_log;
  reg  [          15:0] r_read_adrs         ;
  // wires
  wire [NBT_GPIOS-1 :0]	w_data_ram_for_read ;	
			 

	// ==== Conection Register File ==== // 
  reg                           r_rst_soft                  ;
  reg                           r_log_bits_and_errs      ;
  reg                           r_enbl_read_bits_and_errs;
  reg [NBT_COUNT_BITS_ERR-1 :0]	r_accum_err_Q            ;
  reg [NBT_COUNT_BITS_ERR-1 :0]	r_accum_err_I            ;
  reg [NBT_COUNT_BITS_ERR-1 :0]	r_accum_bit_Q            ;
  reg [NBT_COUNT_BITS_ERR-1 :0]	r_accum_bit_I            ;
  reg [                    2:0]	r_mux_read_bits_and_errs ;
	// wire 
  wire [        NBT_GPIOS-1 :0] w_data_bits_and_errs     ;	


  // ========== Conection DSP ============= // 
  wire signed [       NBT_I_EQLZR-1 :0] w_data_i_eqlzr_I    ;	
  wire signed [       NBT_I_EQLZR-1 :0] w_data_i_eqlzr_Q    ;	
  wire signed [       NBT_O_EQLZR-1 :0] w_data_o_eqlzr_I    ;									
  wire signed [       NBT_O_EQLZR-1 :0] w_data_o_eqlzr_Q    ;		
  wire signed [ NBT_TAPS*NUM_TAPS-1 :0] w_data_taps_I       ;		
  wire signed [ NBT_TAPS*NUM_TAPS-1 :0] w_data_taps_Q       ;	
  wire        [NBT_COUNT_BITS_ERR-1 :0] w_accum_err_Q       ;
  wire        [NBT_COUNT_BITS_ERR-1 :0] w_accum_err_I       ;
  wire        [NBT_COUNT_BITS_ERR-1 :0] w_accum_bit_Q       ;
  wire        [NBT_COUNT_BITS_ERR-1 :0] w_accum_bit_I       ;
  wire                                  w_control_for_rate_2;
  wire                                  w_control_for_rate_1;

	// ======= Conection VIO e ILA ==========
  wire [3:0] w_normal_led     ;
  wire       w_reset          ;
  wire       w_sw             ;
  wire       w_select_from_vio;
  wire       w_reset_from_vio ;
  wire       w_sw_from_vio    ;
    
  // SELECCIONA ENTRE MANEJO FÍSICO DE LA FPGA O MEDIANTE VIO
  assign w_reset  = w_select_from_vio ? ~w_reset_from_vio : ~i_reset;
  assign w_sw     = w_select_from_vio ? w_sw_from_vio : i_sw        ;


	//=======================================================
	// 										Instances 											 //
	//=======================================================

	//==========================================
	//            VIO / ILA  						   		//
	//==========================================
  //ila_a
  ila_k
    u_ila (
    //.clk_100MHz(clk         ),
    .clk_200MHz(clk         ),
    .probe0_0  (w_normal_led)
  );

  //vio_a
  vio_k
    u_vio (
    //.clk_100MHz  (clk              ),
    .clk_200MHz  (clk              ),
    .probe_in0_0 (w_normal_led     ),
    .probe_out0_0(w_select_from_vio),
    .probe_out1_0(w_reset_from_vio ),
    .probe_out2_0(w_sw_from_vio    )
  );


	//==========================================
	//            MicroBlazer 								//
	//==========================================
  MicroGPIO    
     u_MicroGPIO 
     (
        .clk           (clockdsp                ),// Clock aplicacion
        .gpio_rtl_tri_i(gpio_input_to_output_dsp),// GPIO input data
        .gpio_rtl_tri_o(gpio_output_to_input_dsp),// GPIO output data
        //  ( .gpio_rtl_0_tri_i(data_from_regf_to_gpio2),  // GPIO in's
        //    .gpio_rtl_tri_o  (gpio1_to_regf          ),  // GPIO out's
        .o_lock_clock  (locked                  ),// Signal Lock Clock        
        .reset         (i_reset                 ),// Hard Reset
        .sys_clock     (clk                     ),// Clock de FPGA
        .usb_uart_rxd  (in_rx_uart              ),// UART Rx
        .usb_uart_txd  (out_tx_uart             ) // UART Tx
      );


	//==========================================
	//            DSP Designe 								//
	//==========================================
  qpsk_comm_sys #()
    u_qpsk_comm_sys(
      .o_data_i_eqlzr_I    (w_data_i_eqlzr_I      ),//output FSE I
      .o_data_i_eqlzr_Q    (w_data_i_eqlzr_Q      ),//output FSE Q
      .o_data_o_eqlzr_I    (w_data_o_eqlzr_I      ),//input slcr I
      .o_data_o_eqlzr_Q    (w_data_o_eqlzr_Q      ),//input slcr Q	
      .o_data_taps_I       (w_data_taps_I         ),//coeff I
      .o_data_taps_Q       (w_data_taps_Q         ),//coeff Q
      .o_accum_err_I       (w_accum_err_I         ),//count err I
      .o_accum_tot_I       (w_accum_bit_I         ),//count bit I
      .o_accum_err_Q       (w_accum_err_Q         ),//count err Q
      .o_accum_tot_Q       (w_accum_bit_Q         ),//count bit Q  
      .o_control_for_rate_2(w_control_for_rate_2  ),//w_control_for_rate_2
      .o_control_for_rate_1(w_control_for_rate_1  ),//rate one 
      .o_normal_led        (w_normal_led          ),
      .i_sw                (w_sw                  ),
      .i_reset             (~w_reset || r_rst_soft), // reset from vio
      .clk                 (clockdsp              )  // clock from MicroBlaze   
    );

  ///////////////////////////////////////////
  // Logueo control for RAM
  ///////////////////////////////////////////  
  block_ram_control
    u_block_ram_control
    (
      .o_data_for_read     (w_data_ram_for_read ),				
      .i_data_selec_for_log(r_data_selec_for_log), 
      .i_enbl_write        (r_enbl_write        ),
      .i_enbl_read         (r_enbl_read_from_ram),
      .i_read_adrs         (r_read_adrs         ), 
      .i_data_fse_I        (w_data_i_eqlzr_I    ),
      .i_data_fse_Q        (w_data_i_eqlzr_Q    ),			
      .i_data_input_slcr_I (w_data_o_eqlzr_I    ),	
      .i_data_input_slcr_Q (w_data_o_eqlzr_Q    ),	
      .i_data_coeff_I      (w_data_taps_I       ),
      .i_data_coeff_Q      (w_data_taps_Q       ),
      .i_enbl_rate_two     (w_control_for_rate_2),
      .i_enbl_rate_one     (w_control_for_rate_1),
      .i_reset             (w_reset             ),
      .i_clock             (clk                 ) // Cambiar a clockdsp para tb				
     );


	// DEBERIA ESTAR EN UN MODULO ESTO 
	//==========================================
	//            Register file 						  //
	//==========================================


  always @(posedge clk) begin // Cambiar clk por clockdsp para simulacion
     if(w_reset== 1'b1) begin
        r_rst_soft               <= 1'b1 ;
        r_data_selec_for_log     <= 3'b0 ;
        r_enbl_write             <= 1'b0 ;
        r_enbl_read_from_ram     <= 1'b0 ;
        r_accum_err_Q            <= 64'b0;
        r_accum_err_I            <= 64'b0;
        r_accum_bit_Q            <= 64'b0;
        r_accum_bit_I            <= 64'b0;
        r_enbl_read_bits_and_errs<= 1'b0 ;
        r_mux_read_bits_and_errs <= 3'b0 ;
        r_log_bits_and_errs      <= 1'b0 ;
        r_read_adrs              <= 16'b0;
        
     end
     else begin   
        if(gpio_output_to_input_dsp[23] == 1'b1)begin
            case (gpio_output_to_input_dsp[31:24])
                8'h01: begin
                    r_rst_soft        <= gpio_output_to_input_dsp[0]  ; 					// 0 Reset for DSP 
                end
                
                //8'h02: begin
                //    r_switch[1:0]  <= gpio_output_to_input_dsp[1:0]; 				// 1 Enable Adaptive Filter ? 
                //end
                
                8'h03: begin
                    r_data_selec_for_log<= gpio_output_to_input_dsp[2:0];	// 3 Login data in RAM,
                    r_enbl_write        <= gpio_output_to_input_dsp[3]  ;	// Signal enbl for write data in RAM
                end								 
                
                8'h04: begin // 4 Read data from RAM
                    r_enbl_read_from_ram<= gpio_output_to_input_dsp[16]	 ;      
                    r_read_adrs[15:0]   <= gpio_output_to_input_dsp[15:0];	// Addrs for read in RAM
                end
               
                8'h05: begin 
                    r_log_bits_and_errs	<= gpio_output_to_input_dsp[0];
                end
                
                8'h06: begin
                    r_mux_read_bits_and_errs  <= gpio_output_to_input_dsp[2:0];  // 6 Read bits and err 
                    r_enbl_read_bits_and_errs <= gpio_output_to_input_dsp[3]	;
                end		
                
           endcase
            
           if (r_log_bits_and_errs) begin
                r_accum_err_Q <= w_accum_err_Q;	 
                r_accum_err_I <= w_accum_err_I;	 
                r_accum_bit_Q <= w_accum_bit_Q; 	 
                r_accum_bit_I <= w_accum_bit_I; 	 
            end 
            
        end //Fin de if(gpio_output_to_input_dsp[23] == 1'b1)
     end //Fin de else begin    
  end //Fin de always
																							                           


assign gpio_input_to_output_dsp	=   (r_enbl_read_from_ram == 1'b1)
                                   ? w_data_ram_for_read
                                   :((r_enbl_read_bits_and_errs == 1'b1)
                                   ? w_data_bits_and_errs
                                   : 32'b0); // Selec data for Micro

assign w_data_bits_and_errs = (r_mux_read_bits_and_errs == 3'b000)
                             ? r_accum_err_I [31:0]
                             :(r_mux_read_bits_and_errs == 3'b001)
                             ? r_accum_err_I [63:32]
                             :(r_mux_read_bits_and_errs == 3'b010)
                             ? r_accum_bit_I [31:0]
                             :(r_mux_read_bits_and_errs == 3'b011)
                             ? r_accum_bit_I [63:32]
                             :(r_mux_read_bits_and_errs == 3'b100)
                             ? r_accum_err_Q [31:0]
                             :(r_mux_read_bits_and_errs == 3'b101)
                             ? r_accum_err_Q [63:32]
                             :(r_mux_read_bits_and_errs == 3'b110)
                             ? r_accum_bit_Q [31:0]
                             : r_accum_bit_Q [63:32]             ;


  assign o_normal_led = w_normal_led;

endmodule


