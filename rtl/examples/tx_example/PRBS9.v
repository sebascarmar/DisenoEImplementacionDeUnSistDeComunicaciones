//==============================================================================
// AUTOR: Juarez Daniel 
// AÑO:   2025  
// NOMBRE: Module PRBS Q and I, provides random data for the filters
//==============================================================================
module prbsQI (
    input  clock,
    input  i_reset,
    input  i_enable, 
    input  i_valid,
    output o_PrbsI, 
    output o_PrbsQ
);

//======================
// Variables
//======================    
reg [8:0] ShiftRegPRBSI; 
reg [8:0] ShiftRegPRBSQ;   


    always @(posedge clock) begin
        if (i_reset) begin
            ShiftRegPRBSI  <= 9'b010101011; // Seed I
            ShiftRegPRBSQ  <= 9'b111111110; // Seed Q
        end

        else if(i_enable && i_valid) begin

            ShiftRegPRBSI    <= {ShiftRegPRBSI[7:0],(ShiftRegPRBSI[4]^ShiftRegPRBSI[8])}; // rotate and xor
            ShiftRegPRBSQ    <= {ShiftRegPRBSQ[7:0],(ShiftRegPRBSQ[4]^ShiftRegPRBSQ[8])};
        end
        else begin
            ShiftRegPRBSI <= ShiftRegPRBSI;
            ShiftRegPRBSQ <= ShiftRegPRBSQ; 

        end
    end
    
assign o_PrbsI = ShiftRegPRBSI[8]; // output PRBS I
assign o_PrbsQ = ShiftRegPRBSQ[8]; // output PRBS Q


endmodule 