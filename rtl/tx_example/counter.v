//===============================================================
// AUTOR: Juarez Daniel 
// AÑO:   2025  
// NOMBRE: counter module for enable data from PRBS module  
//===============================================================
module counter(
    
        input  clock,
        input  i_reset,        
        input  i_enable,
        output [2:0] o_counter_mux,
        output o_validPrbs
    );
    
    // Register to hold the counter value
    reg [2:0] counter_reg_prbs;   
    // Register to indicate valid PRBS
    reg       validPrbs; 

    always @(posedge clock) begin
        if (i_reset) begin
            // Reset counter and validPrbs
            counter_reg_prbs    <= 2'b00;
            validPrbs           <= 1'b0 ;
        end
        else if (i_enable == 1'b1) begin
            if (counter_reg_prbs < 2'b11) begin
                // Increment counter if less than 4
                counter_reg_prbs <= counter_reg_prbs + 2'b01;
                validPrbs <= 1'b0;
            end else begin
                // Hold counter and set validPrbs
                counter_reg_prbs <= counter_reg_prbs;
                validPrbs <= 1'b1; 
                // Reset counter
                counter_reg_prbs <= 2'b00;
            end    
        end else begin
            // Maintain current state
            counter_reg_prbs    <= counter_reg_prbs;
            validPrbs           <= validPrbs;
        end    
    end

    // Assign outputs
    assign o_counter_mux = counter_reg_prbs; 
    assign o_validPrbs   = validPrbs;  

endmodule
