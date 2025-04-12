`timescale 1ns/1ps

  
module block_ram #(
  parameter RAM_WIDTH       = 32   ,            
  parameter RAM_DEPTH       = 32768,                  
  parameter RAM_PERFORMANCE = ""   ,
  parameter INIT_FILE       = ""                       
)
(
  output [        RAM_WIDTH-1:0] o_data_output,

  input  [$clog2(RAM_DEPTH)-1:0] i_write_addr ,
  input  [$clog2(RAM_DEPTH)-1:0] i_read_addr  ,
  input  [      RAM_WIDTH - 1:0] i_data_input ,
  input                          i_write_en   ,
  input                          i_read_en    ,
  input                          i_reset      ,
  input                          clk       
);

  reg [RAM_WIDTH-1:0] BlockRAM [RAM_DEPTH-1:0];
  reg [RAM_WIDTH-1:0] RAM_DATA = {RAM_WIDTH{1'b0}};
  

  // The following code either initializes the memory values to a specified file or to all zeros to match hardware
  generate
    if (INIT_FILE != "") begin: use_init_file
      initial
        $readmemh(INIT_FILE, BlockRAM, 0, RAM_DEPTH-1);
    end else begin: init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
          BlockRAM[ram_index] = {RAM_WIDTH{1'b0}};
    end
  endgenerate

  // Reading and writing RAM 
  always @(posedge clk) begin
    if (i_write_en) begin
        BlockRAM[i_write_addr] <= i_data_input;
    end
    else begin
        BlockRAM[i_write_addr] <= BlockRAM[i_write_addr];
    end
    
    if (i_read_en) begin
        RAM_DATA <= BlockRAM[i_read_addr];
    end begin
        RAM_DATA <= RAM_DATA;
    end
  end

  //  The following code generates HIGH_PERFORMANCE (use output register) or LOW_LATENCY (no output register)
  generate
    if (RAM_PERFORMANCE == "LOW_LATENCY") begin: no_output_register
        // The following is a 1 clk cycle read latency at the cost of a longer clk-to-out timing
        assign o_data_output = RAM_DATA;
       
    end else begin: output_register
        // The following is a 2 clk cycle read latency with improve clk-to-out timing
        reg [RAM_WIDTH-1:0] r_data_output = {RAM_WIDTH{1'b0}};
        
        always @(posedge clk) begin
          if (i_reset) begin
              r_data_output <= {RAM_WIDTH{1'b0}};
          end
          //else if ( ) begin
          else begin
              r_data_output <= RAM_DATA;
          end
        end
        
        assign o_data_output = r_data_output;
       
    end
  endgenerate
				
						
endmodule

