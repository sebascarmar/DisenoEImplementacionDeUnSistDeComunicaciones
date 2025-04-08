//////////////////////////////////////////////
// Test bench para el manejo del gpio y RAM	//
////////////////////////////////////////////// 

`timescale 1ns / 1ps

module tb_ram_and_gpio();

		//	Descomentar para testeo
   	reg   							clockdsp								;
   	reg   							i_reset 								;
		//	Estimulos de entrada para testeo
   	reg				 [	31:0] gpio_output_to_input_dsp;  	
		//	Salidas
		wire		   [	31:0] gpio_input_to_output_dsp;									

					
	top_hw_custom
		u_top_hw_custom
		( 
   		.clockdsp								 	(clockdsp								 ),
   		.i_reset 								  (i_reset 								 ),
  		.gpio_output_to_input_dsp (gpio_output_to_input_dsp),    	
			.gpio_input_to_output_dsp (gpio_input_to_output_dsp)	
		);

	//====== Variables for TB =========	
	integer i;

	//Initial

    initial begin
        clockdsp					  = 1'b0;
        i_reset   					= 1'b1;	
        #100;          
        i_reset   					= 1'b0;  

		/*
			1 - 0x01800001 / 0x01800000  
			2 - 0x02800001 / 0x02800000
			3 - 0x03800009 -> FSE 
					0x0380000A -> Slcr
					0x0380000B -> coeffs 
					0x0380000C -> err 	/ 0x03800000 
			4 - 0x04800001 / 0x04800000
			5 - 0x05480001 / 0x05800000
			6 - 0x06800001 / 0x04800000

			// Cosas a loguear: 	
			// 1 - Entrada del FSE S(8,7) 							Tasa 2 BR*2 = 50 MHz
			// 2 - Entrada del Slicer S(12,9)       	  Tasa 1 BR   = 25 MHz
			// 3 - Coeficientes de I e Q S(28,25) 			Tasa 1 BR   = 25 MHz CON RETARDO 
			// 4 - Entrada del error S(12,9) 						Tasa 1 BR		= 25 MHz 

		*/

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
	* 
	
	*/

		///////////// Teste de las tramas /////////////

    gpio_output_to_input_dsp =	32'h01800001;   // 1ra opc reset       
    #100;                 
    gpio_output_to_input_dsp =	32'h01800000;   // fin de reset  
    #100; 
    gpio_output_to_input_dsp =	32'h02800001;   // 2da opc set adaptive filter    
    #100;   
    gpio_output_to_input_dsp =	32'h02800000;   // reset opc2     
    #100;   


		gpio_output_to_input_dsp =	32'h03800009;  // 3ra opc, subopc1 Escritura de datos FSE
		#640000;
	
		gpio_output_to_input_dsp =	32'h03800000;  // Reset write 
		#5000;
		
		for (i = 0; i<32000; i = i+1) begin 
			gpio_output_to_input_dsp =  32'h04810000 + i;	// Reading data 
			#10;
		end 
		gpio_output_to_input_dsp =	32'h04800000;  // 4ta opc reset reading
		#50000;
		

		gpio_output_to_input_dsp =	32'h0380000A;  // 3ra opc, subopc2 Escritura de datos SLCR
		#1280000;
	
		gpio_output_to_input_dsp =	32'h03800000;  // Reset write 
		#5000;
		
		for (i = 0; i<32000; i = i+1) begin 
			gpio_output_to_input_dsp =  32'h04810000 + i;	// Reading data 
			#10;
		end 
		gpio_output_to_input_dsp =	32'h04800000;  // 4ta opc reset reading
		#50000;
	

		gpio_output_to_input_dsp =	32'h0380000B;  // 3ra opc, subopc2 Escritura de datos COEFF with 250 delay
		#8352000;
		// #7598330;
	
		gpio_output_to_input_dsp =	32'h03800000;  // Reset write 
		#5000;
		
		for (i = 0; i<32000; i = i+1) begin 
			gpio_output_to_input_dsp =  32'h04810000 + i;	// Reading data 
			#10;
		end 
		gpio_output_to_input_dsp =	32'h04800000;  // 4ta opc reset reading
		#50000;
	

		$finish;
end

	//Clock
	always #5 clockdsp = ~clockdsp; 

endmodule
