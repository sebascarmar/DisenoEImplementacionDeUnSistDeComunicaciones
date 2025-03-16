module top_fir
#(
    parameter NB_INPUT   = 8,    // Number of bits of the input (format S(8,7))
    parameter NBF_INPUT  = 7,    // Number of fractional bits of the input
    parameter NB_OUTPUT  = 8,    // Number of bits of the output
    parameter NBF_OUTPUT = 7,    // Number of fractional bits of the output
    // The coefficients are in format S(16,15)
    parameter NB_COEFF   = 16,   // Total number of bits of the coefficient
    parameter NBF_COEFF  = 15,   // Number of fractional bits of the coefficient
    parameter N_COEFFS   = 17,   // Total number of coefficients
    parameter INIT_FILE = " "
)
(
    input                         i_clock    ,  // system clock
    input                         i_reset    ,  // system reset   
    input                         i_valid    ,  // Enable    
    input  signed [NB_INPUT -1:0] i_symb_I   ,  // Input sample I S(8,7)
    input  signed [NB_INPUT -1:0] i_symb_Q   ,  // Input sample Q S(8,7)
    output signed [NB_INPUT+NB_COEFF+4:0] o_fir_full_symbI, 
    output signed [NB_INPUT+NB_COEFF+4:0] o_fir_full_symbQ, 
    output signed [NB_OUTPUT-1:0]         o_fir_symbI     ,  // Output sample I
    output signed [NB_OUTPUT-1:0]         o_fir_symbQ        // Output sample Q

);

    //==========================================================================
    // Calculation of widths for operations
    //==========================================================================

    // Product of a sample (NB_INPUT) by a coefficient (NB_COEFF)
    // will have NB_PROD bits; the fractional part will be the sum of the fractions.
    localparam NB_PROD = NB_INPUT + NB_COEFF;           // NB_PROD = 24
    // To sum N_COEFFS products, bits are added according to the number of sums
    localparam NB_ADD  = NB_PROD + $clog2(N_COEFFS);    // NB_ADD = 28  
    localparam NBF_ADD = NBF_INPUT + NBF_COEFF;         // NBF_ADD = 22
    localparam NBI_ADD = NB_ADD - NBF_ADD;              // NBI_ADD = 6
    localparam NBI_OUTPUT = NB_OUTPUT - NBF_OUTPUT;     // NBI_OUTPUT = 1  
    localparam NB_SAT  = NBI_ADD - NBI_OUTPUT;          // NB_SAT = 5

    //==========================================================================
    // Declaration of registers and memories
    //==========================================================================

    // Shift Register to store previous samples
    // (N_COEFFS-1) registers are required (the current input is processed directly)
    reg signed [NB_INPUT-1:0] shift_reg_I [0:N_COEFFS-2];
    reg signed [NB_INPUT-1:0] shift_reg_Q [0:N_COEFFS-2];

    // Memory for the coefficients (format S(16,15)) that will be loaded from a .dat file
    reg signed [NB_COEFF-1:0] coeff [0:N_COEFFS-1];
    initial begin
        // The file "coefficients.dat" must contain 17 binary values of 16 bits each.
        $readmemb(INIT_FILE, coeff, 0, N_COEFFS-1);
    end

    //==========================================================================
    // Shift Register: Updates the sample chain on each clock edge.
    //==========================================================================
    integer j;
    always @(posedge i_clock) begin
        if (i_reset) begin
            // Reset the sample chain
            for (j = 0; j < N_COEFFS-1; j = j+1) begin
                shift_reg_I[j] <= {NB_INPUT{1'b0}};
                shift_reg_Q[j] <= {NB_INPUT{1'b0}};
            end
        end else if (i_valid) begin
            // Shift: the most recent sample is stored in position 0
            for (j = N_COEFFS-2; j > 0; j = j-1) begin
                shift_reg_I[j] <= shift_reg_I[j-1];
                shift_reg_Q[j] <= shift_reg_Q[j-1];
            end
            shift_reg_I[0] <= i_symb_I;
            shift_reg_Q[0] <= i_symb_Q;
        end
    end

    //==========================================================================
    // Multipliers: Generate the 17 products
    //==========================================================================

    wire signed [NB_PROD-1:0] prod_I [0:N_COEFFS-1];
    wire signed [NB_PROD-1:0] prod_Q [0:N_COEFFS-1];

    // Product 0: Current input * coefficient 0
    assign prod_I[0] = i_symb_I * coeff[0];
    assign prod_Q[0] = i_symb_Q * coeff[0];

    // For coefficients 1 to (N_COEFFS-1), the stored samples are multiplied
    genvar i;
    generate
        for (i = 1; i < N_COEFFS; i = i+1) begin : gen_products
            assign prod_I[i] = shift_reg_I[i-1] * coeff[i];
            assign prod_Q[i] = shift_reg_Q[i-1] * coeff[i];
        end
    endgenerate

    //==========================================================================
    // Adder: Sum of all products
    //==========================================================================

    reg signed [NB_ADD-1:0] sum_I;
    reg signed [NB_ADD-1:0] sum_Q;
    integer k;
    always @(*) begin
        sum_I = prod_I[0];
        sum_Q = prod_Q[0];
        for (k = 1; k < N_COEFFS; k = k+1) begin
            sum_I = sum_I + prod_I[k];
            sum_Q = sum_Q + prod_Q[k];
        end
    end

    //==========================================================================
    // Saturation logic: Adjusts the output to the desired width
    //==========================================================================

    assign o_fir_symbI = ( ~|sum_I[NB_ADD-1 -: NB_SAT+1] || &sum_I[NB_ADD-1 -: NB_SAT+1] ) ?
                                            sum_I[NB_ADD-(NBI_ADD-NBI_OUTPUT) - 1 -: NB_OUTPUT] :
                                            (sum_I[NB_ADD-1]) ? {1'b1, {NB_OUTPUT-1{1'b0}}} : {1'b0, {NB_OUTPUT-1{1'b1}}};

    assign o_fir_symbQ = ( ~|sum_Q[NB_ADD-1 -: NB_SAT+1] || &sum_Q[NB_ADD-1 -: NB_SAT+1] ) ?
                                            sum_Q[NB_ADD-(NBI_ADD-NBI_OUTPUT) - 1 -: NB_OUTPUT] :
                                            (sum_Q[NB_ADD-1]) ? {1'b1, {NB_OUTPUT-1{1'b0}}} : {1'b0, {NB_OUTPUT-1{1'b1}}};
    assign o_fir_full_symbI = sum_I;  
    assign o_fir_full_symbQ = sum_Q;  

endmodule
