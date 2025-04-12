`timescale 1ns/1ps


module block_ram_control 
#(
  parameter NBT_I_EQLZR     =     8,	 
  parameter NBT_O_EQLZR     =    12,
  parameter NBT_TAPS        =    10,
  parameter NUM_TAPS        =     9,
  parameter N_DELAY         =   250,
  parameter RAM_WIDTH       =    32,            
  parameter RAM_DEPTH       = 32768,                  
  parameter RAM_PERFORMANCE = "LOW_LATENCY",
  parameter INIT_FILE       = ""             
)
(
  // outputs	
  output signed [        RAM_WIDTH-1 :0] o_data_for_read     , 
  // inputs		
  input                                  i_data_selec_for_log, 
  input                                  i_enbl_write        , 
  input                                  i_enbl_read         , 
  input         [$clog2(RAM_DEPTH)-1 :0] i_read_adrs         , 
  input  signed [      NBT_I_EQLZR-1 :0] i_data_fse_I        , 
  input  signed [      NBT_I_EQLZR-1 :0] i_data_fse_Q        , 
  input  signed [      NBT_O_EQLZR-1 :0] i_data_input_slcr_I , 
  input  signed [      NBT_O_EQLZR-1 :0] i_data_input_slcr_Q , 
  input  signed [NBT_TAPS*NUM_TAPS-1 :0] i_data_coeff_I      , 
  input  signed [NBT_TAPS*NUM_TAPS-1 :0] i_data_coeff_Q      ,	 
  input                                  i_enbl_rate_two     , 
  input                                  i_enbl_rate_one     , 	
  input                                  i_reset             ,
  input                                  clk
);

	// registers
  reg [$clog2(RAM_DEPTH)-1 :0] r_counter_adrs               ; 
  reg [ $clog2(NUM_TAPS)-1 :0] r_counter_adrs_coeffs        ; 
  reg [  $clog2(N_DELAY)-1 :0] r_count_delay                ;
  reg                          r_enbl_coeffs                ;
  reg signed [  NBT_TAPS-1 :0] r_data_coeff_I [NUM_TAPS-1:0];
  reg signed [  NBT_TAPS-1 :0] r_data_coeff_Q [NUM_TAPS-1:0];

	// internal wires
  wire                 w_enbl_write  ;
  wire [NBT_TAPS-1 :0] w_data_for_log;


  // generate serialized to parallel coefficient data
  genvar i;
  generate
      for (i = 0; i < NUM_TAPS; i = i + 1) begin 
      	always @(posedge clk) begin
            if (!r_enbl_coeffs) begin
                r_data_coeff_I[i] <= i_data_coeff_I[(i+1)*NBT_TAPS-1 -: NBT_TAPS];
                r_data_coeff_Q[i] <= i_data_coeff_Q[(i+1)*NBT_TAPS-1 -: NBT_TAPS];
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
    .o_data_output(o_data_for_read), // Output data read from RAM
    .i_write_addr (r_counter_adrs ), // Input direccion for write data in block RAM 
    .i_read_addr  (i_read_adrs    ), // Input direccion for read data in block RAM  
    .i_data_input (w_data_for_log ), // Input data for log in block RAM
    .i_write_en   (w_enbl_write   ), // Signal enable for write data 
    .i_read_en    (i_enbl_read    ), // Signal enable for read data
    .i_reset      (i_reset        ), // Reset ram
    .clk          (clk            ) // system clock 
    );


	// ======== Logic for coefficient data collection delay =============
  always @(posedge clk) begin 
    if(i_reset) begin 
        r_count_delay         <= 0;
        r_enbl_coeffs         <= 0;
        r_counter_adrs_coeffs <= 0;
    end
    else begin 
        // Delay counter to enable coefficients storage
        if (r_count_delay < N_DELAY - 1)
            r_count_delay <= r_count_delay + 1'b1;
        else begin
            r_enbl_coeffs  <= 1'b1; // Enable flag for storage coefficients 
        end 
        // Coefficient buffer data count
        if (r_enbl_coeffs) begin
            if (r_counter_adrs_coeffs < (NUM_TAPS-1)) begin
                r_counter_adrs_coeffs <= r_counter_adrs_coeffs + 1'b1;
            end
            else begin 
                r_counter_adrs_coeffs <= 0;
                r_enbl_coeffs         <= 0;
                r_count_delay         <= {$clog2(N_DELAY-1){1'b0}};
            end
        end // end if(r_enbl_coeffs)
    end // end else if (i_reset)
  end // end always for count delay


	//========== Data allocation for RAM storage ==========//
  always @(posedge clk) begin
    if(i_reset == 1'b1) begin
        r_counter_adrs <= 16'b0;		
    end
    else begin
      // FSE data storage
        if (i_enbl_write && !i_enbl_read && i_enbl_rate_two && i_data_selec_for_log == 3'b001 ) begin
            if (r_counter_adrs < 16'h7D00) // 32000 
                r_counter_adrs <= r_counter_adrs + 1'b1;
            else begin 
                r_counter_adrs <= r_counter_adrs;
            end
        end
        // Input slicer or errors data storage
        else if (i_enbl_write && !i_enbl_read && i_enbl_rate_one && i_data_selec_for_log == 3'b010) begin
            if (r_counter_adrs < 16'h7D00) // 32000
                r_counter_adrs <= r_counter_adrs + 1'b1;
            else begin 
                r_counter_adrs <= r_counter_adrs;
            end
        end
        // Coefficients data storage
        else if (i_enbl_write && !i_enbl_read && r_enbl_coeffs && i_data_selec_for_log == 3'b011) begin
            if (r_counter_adrs < 16'h7D00)				        
                r_counter_adrs <= r_counter_adrs + 1'b1;
            else begin  
                r_counter_adrs <= r_counter_adrs;			
            end 	
        end			
        // Enable read, reset counter 
        else if(i_enbl_read == 1'b1) begin 
            r_counter_adrs <= 16'b0;
        end
        else begin 
            r_counter_adrs <= r_counter_adrs;
        end
    end // end else always
  end// end always 

	
  // Assign internal wires 
  assign w_data_for_log = (i_data_selec_for_log == 3'b001) 
                          ? {8'b0, i_data_fse_I, 8'b0, i_data_fse_Q} // Output equalizer
                          :(i_data_selec_for_log == 3'b010)
                          ? {4'b0, i_data_input_slcr_I, 4'b0, i_data_input_slcr_Q} // Input equalizer
                          :((i_data_selec_for_log == 3'b011) && r_enbl_coeffs && (r_counter_adrs < 16'h3E80))// 
                          ? {12'b0, r_data_coeff_I[r_counter_adrs_coeffs]} // Equalizer taps I
                          :((i_data_selec_for_log == 3'b011) && r_enbl_coeffs && (r_counter_adrs >= 16'h3E80))
                          ? {12'b0, r_data_coeff_Q[r_counter_adrs_coeffs]} // Equalizer taps Q
                          : 32'b0;
  
  assign w_enbl_write = i_enbl_write;


endmodule

