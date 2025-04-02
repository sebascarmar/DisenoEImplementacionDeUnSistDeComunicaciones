`timescale 1ns/1ps


module ber_control #(
  parameter PRBS_MAX_CYCLES = 511                ,
  parameter START_SYN       = PRBS_MAX_CYCLES*690, // 352590
  parameter START_CNT       = START_SYN + 511*511  // 613711
)
(
  output o_start_synchro          ,
  output o_prbs_cmp_curr_addr_done,
  output o_start_ber_counter      ,
  
  input  i_ctrl                   , 
  input  i_reset                  , 
  input  clk       
);
  
  // Local parameters for internal operations and output saturation
  localparam COUNTER_BITS    = $clog2(START_CNT)      ;
  localparam PRBS_CYCLE_BITS = $clog2(PRBS_MAX_CYCLES);
  
  // Internal registers
  reg [   COUNTER_BITS-1:0] r_counter    ;
  reg [PRBS_CYCLE_BITS-1:0] r_prbs_cycles;


  // Counter
  always @(posedge clk) begin: control
    if (i_reset==1'b1) begin
        r_counter     <= {COUNTER_BITS{1'b0}}   ;
        r_prbs_cycles <= {PRBS_CYCLE_BITS{1'b0}};
    end
    else begin
        // Process only when control signal is enabled (at rate 1=BR)
        if (i_ctrl==1'b1) begin
            // Wait for START_SYN cycles before initiating synchronization
            if (r_counter<START_SYN) begin
                r_counter <= r_counter + { {(COUNTER_BITS-1){1'b0}} , 1'b1 };
                
                r_prbs_cycles <= {PRBS_CYCLE_BITS{1'b0}};
                
            end
            // Perform synchronization over 511*511 received symbols
            else if (r_counter<START_CNT) begin
                r_counter <= r_counter + { {(COUNTER_BITS-1){1'b0}} , 1'b1 };
                
                if (r_prbs_cycles<PRBS_MAX_CYCLES-1) begin
                    r_prbs_cycles <= r_prbs_cycles + { {(PRBS_CYCLE_BITS-1){1'b0}} , 1'b1 };
                end
                else begin
                    r_prbs_cycles <= {PRBS_CYCLE_BITS{1'b0}};
                end
               
            end
            // After synchronization, counters remain unchanged to set final flags
            else begin
                r_counter     <= r_counter;
                r_prbs_cycles <= r_prbs_cycles;
            end
            
        end
        // Maintain values unchanged for OS clock cycles
        else begin
            r_counter     <= r_counter;
            r_prbs_cycles <= r_prbs_cycles;
        end
       
    end
    
  end // End of always block for counter control
  
  
  // Output assignments
  assign o_start_synchro           = (r_counter>=START_SYN && r_counter<START_CNT) ? 1'b1 : 1'b0;
  assign o_prbs_cmp_curr_addr_done = (r_prbs_cycles==PRBS_MAX_CYCLES-1) ? 1'b1 : 1'b0           ;
  assign o_start_ber_counter       = (r_counter>=START_CNT) ? 1'b1 : 1'b0                       ;


 endmodule

