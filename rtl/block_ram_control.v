`timescale 1ns/1ps


module block_ram_control 
#(
  parameter NBT_I_EQLZR     =     8				 ,	 
  parameter NBT_O_EQLZR     =    12				 ,
  parameter NBT_TAPS        =    10				 ,
  parameter NUM_TAPS        =     9				 ,
  parameter N_DELAY         =   250				 ,
  parameter RAM_WIDTH       =    32				 ,            
  parameter RAM_DEPTH       = 32768				 ,                  
  parameter RAM_PERFORMANCE = "LOW_LATENCY",
  parameter INIT_FILE       = ""             
)
(
  // outputs	
  output signed [        RAM_WIDTH-1 :0] o_data_for_read     , 
  // inputs		
  input         [										2:0] i_data_sel_for_log  , 
  input                                  i_en_write        	 , 
  input                                  i_en_read           , 
  input         [$clog2(RAM_DEPTH)-1 :0] i_read_adrs         , 
  input  signed [      NBT_I_EQLZR-1 :0] i_data_i_eqlzr_i    , 
  input  signed [      NBT_I_EQLZR-1 :0] i_data_i_eqlzr_q    , 
  input  signed [      NBT_O_EQLZR-1 :0] i_data_o_eqlzr_i 	 , 
  input  signed [      NBT_O_EQLZR-1 :0] i_data_o_eqlzr_q 	 , 
  input  signed [NBT_TAPS*NUM_TAPS-1 :0] i_data_taps_i       , 
  input  signed [NBT_TAPS*NUM_TAPS-1 :0] i_data_taps_q       ,	 
  input                                  i_control_for_rate_2, 
  input                                  i_control_for_rate_1, 	
  input                                  i_reset             ,
  input                                  clk
);

	// localparam 
	localparam N_BITS_FOR_RAM_ADDRS = $clog2(RAM_DEPTH);

	// registers
	reg 														r_flag_for_log_taps					 ; 
  reg       	                    r_en_periodic_tap_capture    ;
	reg 														r_en_write_for_ram			     ;
  reg [N_BITS_FOR_RAM_ADDRS-1 :0] r_counter_adrs               ; 
  reg [ 	 $clog2(NUM_TAPS)-1 :0] r_counter_num_taps           ; 
  reg [     $clog2(N_DELAY)-1 :0] r_count_delay                ;
	// bidimentional registers
  reg signed [  	 NBT_TAPS-1 :0] r_data_coeff_I [NUM_TAPS-1:0];
  reg signed [  	 NBT_TAPS-1 :0] r_data_coeff_Q [NUM_TAPS-1:0];
	// internal wires
  wire [					RAM_WIDTH-1 :0] w_data_for_log;


  // generate serialized to parallel coefficient data
  genvar i;
  generate
      for (i = 0; i < NUM_TAPS; i = i + 1) begin 
      	always @(posedge clk) begin
            if (r_en_periodic_tap_capture== 1'b0) begin
                r_data_coeff_I[i] <= i_data_taps_i[(i+1)*NBT_TAPS-1 -: NBT_TAPS];
                r_data_coeff_Q[i] <= i_data_taps_q[(i+1)*NBT_TAPS-1 -: NBT_TAPS];
            end
						else begin 
								r_data_coeff_I[i] <=	r_data_coeff_I[i];
								r_data_coeff_Q[i] <=	r_data_coeff_Q[i]; 
						end 
        end // end always
      end // end for 
  endgenerate

	//==========================//
	//	  Instance Block RAM		//
	//==========================//	  
  block_ram #(
    .RAM_WIDTH       (RAM_WIDTH      ),               
    .RAM_DEPTH       (RAM_DEPTH      ),                     
    .RAM_PERFORMANCE (RAM_PERFORMANCE),
    .INIT_FILE       (INIT_FILE      )                            
  ) u_block_ram (
    .o_data_output(o_data_for_read	 ), // Output data read from RAM
    .i_write_addr (r_counter_adrs 	 ), // Input direccion for write data in block RAM 
    .i_read_addr  (i_read_adrs    	 ), // Input direccion for read data in block RAM  
    .i_data_input (w_data_for_log 	 ), // Input data for log in block RAM
    .i_write_en   (r_en_write_for_ram || r_flag_for_log_taps), // Signal enable for write data 
    .i_read_en    (i_en_read    		 ), // Signal enable for read data
    .i_reset      (i_reset        	 ), // Reset output reg (only for HIGH_PERMORMANCE) 
    .clk          (clk            	 )  // System clock 
    );

	
	// ======== Logic for coefficient data collection delay =============

  always @(posedge clk) begin 
    if(i_reset) begin 
        r_counter_num_taps				<= 0;
        r_count_delay         		<= 0;
        r_en_periodic_tap_capture <= 0; 
				r_flag_for_log_taps 			<= 0;
    end
    else begin 
        // Delay counter to enable coefficients storage
				if (r_count_delay < N_DELAY-1) begin 
						r_counter_num_taps 				<= 4'b0000; 
            r_count_delay 			 			<= r_count_delay + 1'b1;
						r_en_periodic_tap_capture <= 1'b0;
						r_flag_for_log_taps 			<= 1'b0;
				end 		
        else begin

						r_en_periodic_tap_capture	<= 1'b1; // Enable flag for storage coefficients 
						if (r_en_periodic_tap_capture) begin 				
          		  if (r_counter_num_taps < (NUM_TAPS-1)) begin	
										r_counter_num_taps	<= r_counter_num_taps + 1'b1;
										r_count_delay 			<= r_count_delay;
										r_flag_for_log_taps 								<= 1'b1;
          		  end
          		  else begin 
          		  	 r_counter_num_taps	<= 4'b0000;
          		  	 r_count_delay      <= {$clog2(N_DELAY-1){1'b0}};
									 r_flag_for_log_taps								<= 1'b0;
          		  end
						end 		
						else begin 
								r_count_delay 		 <= r_count_delay;
								r_counter_num_taps <= 4'b0000;
								r_flag_for_log_taps							 <= 1'b1;
						end  
        end  
    end // end else if (i_reset)
  end // end always for count delay


	//========== Data allocation for RAM storage ==========//
  always @(posedge clk) begin
    if(i_reset == 1'b1) begin
        r_counter_adrs 		 <= {(N_BITS_FOR_RAM_ADDRS){1'b0}};		
			  r_en_write_for_ram <= 1'b0;
    end
    else begin

				if (i_en_write==1'b1) begin
						r_en_write_for_ram <= 1'b1;
				end
				else begin
						if(r_en_write_for_ram) begin 				
								if ((i_data_sel_for_log == 3'b001 || i_data_sel_for_log == 3'b010)) begin 
									if (r_counter_adrs < 15'h7FFF) begin // 32767 Hex
											r_en_write_for_ram <= r_en_write_for_ram;
									end
									else begin
											r_en_write_for_ram <= 1'b0;
									end 	
								end
								else  begin
									if (r_flag_for_log_taps==1'b1 && r_counter_adrs < 15'h7FF8) begin // 32760 Hex
											r_en_write_for_ram <= r_en_write_for_ram;
									end
									else begin
											r_en_write_for_ram <= 1'b0;
									end 	
								end 
						end
						else begin 
								r_en_write_for_ram <= r_en_write_for_ram; 
						end 
				end

      // FSE data storage
        if (r_en_write_for_ram && !i_en_read && i_control_for_rate_2 && i_data_sel_for_log == 3'b001 ) begin
        		r_counter_adrs <= r_counter_adrs + 1'b1;
        end
        // Input slicer or errors data storage
        else if (r_en_write_for_ram && !i_en_read && i_control_for_rate_1 && i_data_sel_for_log == 3'b010) begin
            r_counter_adrs <= r_counter_adrs + 1'b1;
        end
        // Coefficients data storage
        else if (!i_en_read && r_flag_for_log_taps && i_data_sel_for_log == 3'b011) begin
        		r_counter_adrs <= r_counter_adrs + 1'b1;
        end			
        else begin
						if (r_counter_adrs == 15'h7FFF)begin 
								r_counter_adrs <= {15{1'b0}}; 		
						end
						else begin 
            		r_counter_adrs <= r_counter_adrs;
						end 
        end

    end // end else alwaysQuick Access
  end// end always 

  // Assign internal wires 
  assign w_data_for_log = (i_data_sel_for_log == 3'b001) 
                          ? {{8{1'b0}}, i_data_i_eqlzr_i, {8{1'b0}}, i_data_i_eqlzr_q} // Output equalizer
                          :(i_data_sel_for_log == 3'b010)
                          ? {{4{1'b0}}, i_data_o_eqlzr_i, {4{1'b0}}, i_data_o_eqlzr_q} // Input equalizer
                          :((i_data_sel_for_log == 3'b011) && r_flag_for_log_taps) 
                          ? {{6{1'b0}}, r_data_coeff_I[r_counter_num_taps], {6{1'b0}}, r_data_coeff_Q[r_counter_num_taps]} // Equalizer taps I
                          : {32{1'b0}};
endmodule

