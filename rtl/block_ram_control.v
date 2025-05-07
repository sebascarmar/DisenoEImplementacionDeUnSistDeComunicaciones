`timescale 1ns/1ps

module block_ram_control 
#(
  parameter NBT_I_EQLZR     =  8           ,
  parameter NBT_O_EQLZR     = 12           ,
  parameter NBT_TAPS        = 10           ,
  parameter NUM_TAPS        =  9           ,
  parameter N_DELAY         = 500          ,
  parameter RAM_WIDTH       = 32           ,            
  parameter RAM_DEPTH       = 32768        ,                  
  parameter RAM_PERFORMANCE = "LOW_LATENCY",
  parameter INIT_FILE       = ""             
)
(
  output signed [              RAM_WIDTH-1 :0] o_data_for_read     , 
  input         [                         2:0] i_data_sel_for_log  ,
  input                                        i_en_write          ,
  input                                        i_en_read           ,
  input         [      $clog2(RAM_DEPTH)-1 :0] i_read_adrs         ,
  input  signed [            NBT_I_EQLZR-1 :0] i_data_i_eqlzr_i    ,
  input  signed [            NBT_I_EQLZR-1 :0] i_data_i_eqlzr_q    ,
  input  signed [            NBT_O_EQLZR-1 :0] i_data_o_eqlzr_i    ,
  input  signed [            NBT_O_EQLZR-1 :0] i_data_o_eqlzr_q    ,
  input  signed [      NBT_TAPS*NUM_TAPS-1 :0] i_data_taps_i       ,
  input  signed [      NBT_TAPS*NUM_TAPS-1 :0] i_data_taps_q       ,
  input             			       i_control_for_rate_2,
  input             			       i_control_for_rate_1,
  input             			       i_reset             ,
  input             			       clk
);

  // Internal conections 
  // Local parameter
  localparam N_BITS_FOR_RAM_ADDRS = $clog2(RAM_DEPTH);
  // wire
  wire [RAM_WIDTH-1:0] w_data_for_log;
  // register 
  reg                                   r_flag_for_log_taps          ;
  reg                                   r_en_periodic_tap_capture    ;
  reg                                   r_en_write_for_ram           ;
  reg        [N_BITS_FOR_RAM_ADDRS-1:0] r_counter_adrs               ;
  reg        [    $clog2(NUM_TAPS)-1:0] r_counter_num_taps           ;
  reg        [     $clog2(N_DELAY)-1:0] r_count_delay                ;
  reg signed [            NBT_TAPS-1:0] r_data_coeff_I [NUM_TAPS-1:0];
  reg signed [            NBT_TAPS-1:0] r_data_coeff_Q [NUM_TAPS-1:0];


  
  // Inputs taps registers: converts a packed 1D input into a 2D register array
  genvar i;
  generate
    for (i = 0; i < NUM_TAPS; i = i + 1) begin
      always @(posedge clk) begin
        if (r_en_periodic_tap_capture == 1'b0) begin
          r_data_coeff_I[i] <= i_data_taps_i[(i+1)*NBT_TAPS-1 -: NBT_TAPS];
          r_data_coeff_Q[i] <= i_data_taps_q[(i+1)*NBT_TAPS-1 -: NBT_TAPS];
        end 
        else begin 
          r_data_coeff_I[i] <= r_data_coeff_I[i];
          r_data_coeff_Q[i] <= r_data_coeff_Q[i]; 
        end 
      end
    end
  endgenerate

  //============= Instances ================
  //========================================
  //              Block RAM               //
  //========================================              
  block_ram #(
    .RAM_WIDTH       (RAM_WIDTH      ),
    .RAM_DEPTH       (RAM_DEPTH      ),
    .RAM_PERFORMANCE (RAM_PERFORMANCE),
    .INIT_FILE       (INIT_FILE      )
  ) u_block_ram (
    .o_data_output (o_data_for_read                          ),
    .i_write_addr  (r_counter_adrs                           ),
    .i_read_addr   (i_read_adrs                              ),
    .i_data_input  (w_data_for_log                           ),
    .i_write_en    (r_en_write_for_ram || r_flag_for_log_taps),
    .i_read_en     (i_en_read                                ),
    .i_reset       (i_reset                                  ),
    .clk           (clk                                      )
  );


  //====== Logic for coefficient data collection delay ======
  always @(posedge clk) begin 
    if (i_reset) begin 
        r_counter_num_taps        <= 0;
        r_count_delay             <= 0;
        r_en_periodic_tap_capture <= 0;
        r_flag_for_log_taps       <= 0;
    end 
    else begin 
      // Delay counter to enable coefficients storage
      // Only for i_data_sel_for_log == 3'b011
        if (r_count_delay < N_DELAY-1 && i_data_sel_for_log == 3'b011 && r_counter_adrs < 15'h7FF8) begin 
            r_counter_num_taps        <= 0;
            r_count_delay             <= r_count_delay + 1;
            r_en_periodic_tap_capture <= 0;
            r_flag_for_log_taps       <= 0;
        end 
        else begin
            r_en_periodic_tap_capture <= 1;     // After the delay time has elapsed, the taps are retained for storage.
            if (r_en_periodic_tap_capture) begin
                // While counter < 500 and i_data_sel_for_log = 3 and r_counter = 32760
                if (r_counter_num_taps < NUM_TAPS-1 && i_data_sel_for_log == 3'b011 && r_counter_adrs < 15'h7FF8) begin
                    r_counter_num_taps   <= r_counter_num_taps + 1; // Coefficients continue to be storage 
                    r_count_delay        <= r_count_delay;
                    r_flag_for_log_taps  <= 1;
                end 
                else begin
                    r_counter_num_taps   <= 0;
                    r_count_delay        <= 0;
                    r_flag_for_log_taps  <= 0;
            end // end if(r_en_periodic_tap_capture) 
        end 
        else begin
            r_count_delay          <= r_count_delay;
            r_counter_num_taps     <= 0;
            r_flag_for_log_taps    <= 1;
        end
      end  
    end // end else if(i_reset)
  end // end always count delay


  // ====== Always with the logic of choosing data to storage in RAM ======
  always @(posedge clk) begin
    if (i_reset) begin
        r_counter_adrs     <= 0;
        r_en_write_for_ram <= 0;
    end 
    else begin
      if (i_en_write) begin         // Flank detector     
          r_en_write_for_ram <= 1;
      end 
      else begin
        if (r_en_write_for_ram) begin
              if ((i_data_sel_for_log == 3'b001 || i_data_sel_for_log == 3'b010)) begin 
                  if (r_counter_adrs < 15'h7FFF) begin // Max counter limit (32768) for opt 1 or 2
                      r_en_write_for_ram <= r_en_write_for_ram;
                  end 
                  else begin
                      r_en_write_for_ram <= 0;
                  end
          end 
          else begin
            // Max counter limit (32760) for opc 3
            if (r_flag_for_log_taps && r_counter_adrs < 15'h7FF8) begin
                r_en_write_for_ram <= r_en_write_for_ram;
            end 
            else begin
                r_en_write_for_ram <= 0;
            end
          end
        end 
        else begin 
              r_en_write_for_ram <= r_en_write_for_ram; 
        end 
      end
      // counter addres for option 1, 2 or 3. 
      if (r_en_write_for_ram && !i_en_read && i_control_for_rate_2 && i_data_sel_for_log == 3'b001) begin
          r_counter_adrs <= r_counter_adrs + 1;
      end 
      else if (r_en_write_for_ram && !i_en_read && i_control_for_rate_1 && i_data_sel_for_log == 3'b010) begin
          r_counter_adrs <= r_counter_adrs + 1;
      end 
      else if (!i_en_read && r_flag_for_log_taps && i_data_sel_for_log == 3'b011) begin
          r_counter_adrs <= r_counter_adrs + 1;
      end 
      else begin
          if (r_counter_adrs == 15'h7FFF || i_read_adrs == 15'h7FF7) begin
            r_counter_adrs <= 0;
          end 
          else begin
              r_counter_adrs <= r_counter_adrs;
          end
      end
    end // end else begin ... 
  end // end always 


  // Data allocation for storage in RAM
  assign w_data_for_log = (i_data_sel_for_log == 3'b001) 
                          ? {{8{i_data_i_eqlzr_i[NBT_I_EQLZR-1]}}, i_data_i_eqlzr_i, {8{i_data_i_eqlzr_q[NBT_I_EQLZR-1]}}, i_data_i_eqlzr_q} // Output equalizer
                          :(i_data_sel_for_log == 3'b010)
                          ? {{4{i_data_o_eqlzr_i[NBT_O_EQLZR-1]}}, i_data_o_eqlzr_i, {4{i_data_o_eqlzr_q[NBT_O_EQLZR-1]}}, i_data_o_eqlzr_q} // Input equalizer
                          :((i_data_sel_for_log == 3'b011) && r_flag_for_log_taps) 
                          ? {{6{r_data_coeff_I[r_counter_num_taps][NBT_TAPS-1]}}, r_data_coeff_I[r_counter_num_taps], {6{r_data_coeff_Q[r_counter_num_taps][NBT_TAPS-1]}}, r_data_coeff_Q[r_counter_num_taps]} // Equalizer taps I
                          : {32{1'b0}};

endmodule

