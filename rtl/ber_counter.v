`timescale 1ns/1ps


module ber_counter #(
  parameter PRBS_MAX_CYCLES = 511
)
(
//  // Ports to uBlaze
//  output [63:0] o_accum_err       ,
//  output [63:0] o_accum_tot       ,
//  //
  output o_sync_done_led          ,
  output o_ber_ok_led             ,
  
  input  i_ctrl                   ,
  input  i_rx_bit                 ,
  input  i_new_bit_from_prbs      ,
  input  i_synchro_en             ,
  input  i_prbs_cmp_curr_addr_done,
  input  i_ber_counter_en         ,
  input  i_en_rx                  , 
  input  i_reset                  , 
  input  clk  
);


  // Local parameters to define the number of bits needed for PRBS cycle indexing
  localparam PRBS_CYCLE_BITS = $clog2(PRBS_MAX_CYCLES);

  // Internal registers and wires
  reg [PRBS_MAX_CYCLES-1:0] r_shifter  ; // Shift register for storing PRBS bits
  reg [               63:0] r_accum_err; // Accumulated error bits counter
  reg [               63:0] r_accum_tot; // Accumulated total bits counter
  reg [PRBS_CYCLE_BITS-1:0] r_error_min; // Minimum detected error for synchronization
  reg [PRBS_CYCLE_BITS-1:0] r_idx      ; // Index for synchronization buffer
  reg [PRBS_CYCLE_BITS-1:0] r_lat      ; // Detected latency value



  always @(posedge clk) begin
    if (i_reset==1'b1 || i_en_rx==1'b0) begin
        r_shifter    <= {PRBS_MAX_CYCLES{1'b0}};
        r_accum_err  <= {64{1'b0}}             ;
        r_accum_tot  <= {64{1'b0}}             ;
        r_error_min  <= PRBS_MAX_CYCLES        ;
        r_idx        <= {PRBS_CYCLE_BITS{1'b0}};
        r_lat        <= {PRBS_CYCLE_BITS{1'b0}};
    end
    else begin
        // Process only when control signal is enabled (at rate 1=BR)
        if (i_ctrl==1'b1) begin
            
            // Synchronization mode
            if (i_synchro_en==1'b1) begin
                r_shifter   <= {r_shifter[PRBS_MAX_CYCLES-2:0] , i_new_bit_from_prbs};
                r_accum_tot <= {64{1'b0}}                                            ;
                
                if (i_prbs_cmp_curr_addr_done!=1'b1) begin
                    r_accum_err <= r_accum_err + {{63'b0} , (r_shifter[r_idx]^i_rx_bit)};
                    
                    r_error_min <= r_error_min;
                    r_lat       <= r_lat      ;
                    r_idx       <= r_idx      ;
                end
                else begin
                      // Update minimum error and latency if a better synchronization is found
                      if (r_accum_err[(PRBS_CYCLE_BITS-1) -: PRBS_CYCLE_BITS] < r_error_min) begin
                          r_error_min <= r_accum_err[(PRBS_CYCLE_BITS-1) -: PRBS_CYCLE_BITS];
                          r_lat       <= r_idx                                              ;
                      end
                      else begin
                          r_error_min <= r_error_min;
                          r_lat       <= r_lat      ;
                      end
                      
                      r_idx       <= r_idx + {{(PRBS_CYCLE_BITS-1){1'b0}} , 1'b1};
                      r_accum_err <= {64{1'b0}}                                  ;
                end
                
            end
            // BER counting mode
            else if (i_ber_counter_en==1'b1) begin
                r_shifter   <= {r_shifter[PRBS_MAX_CYCLES-2:0] , i_new_bit_from_prbs};
                
                r_accum_err <= r_accum_err + {{63{1'b0}} , (r_shifter[r_lat]^i_rx_bit)};
                r_accum_tot <= r_accum_tot + {{63{1'b0}} , 1'b1}                       ;
                
                r_error_min <= r_error_min;
                r_idx       <= r_idx      ;
                r_lat       <= r_lat      ;
                
            end
            // Wait for synchronization to start
            else begin
                r_shifter   <= r_shifter  ;
                r_accum_err <= r_accum_err;
                r_accum_tot <= r_accum_tot;
                r_error_min <= r_error_min;
                r_idx       <= r_idx      ;
                r_lat       <= r_lat      ;
            end
            
        // Maintain values unchanged for OS clock cycles
        end
        else begin
            r_shifter   <= r_shifter  ;
            r_accum_err <= r_accum_err;
            r_accum_tot <= r_accum_tot;
            r_error_min <= r_error_min;
            r_idx       <= r_idx      ;
            r_lat       <= r_lat      ;
        end
        
    end
  end


  // Output assignment: it's HIGH if ber<16.13e-3 (for SNR=7dB)
  assign o_sync_done_led = i_ber_counter_en; // límite
  assign o_ber_ok_led    = (64*r_accum_err < r_accum_tot) ? 1'b1 : 1'b0 ; // límite


//  // Data assignments to uBlaze
//  assign o_accum_err  = r_accum_err                                  ;
//  assign o_accum_tot  = r_accum_tot                                  ;


endmodule

