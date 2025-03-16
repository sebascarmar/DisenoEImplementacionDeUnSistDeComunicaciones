//==============================================================================
// Author: Juarez Daniel 
// Date: 03/2025
// Description: Module generates a complete sine and cosine wave starting from 
//				1/4 wave of each. The output frequency for a step of 0 is 10kHz 
//				and for a step of 10 is 100Hz.
//==============================================================================
module wave_sin_and_cos
#
(
	parameter READ_WIDTH    = 8   , // width of the data    
	parameter READ_DEPTH    = 2500, // depth of the data   
	parameter INIT_FILE_SIN = ""  , // path to the file with the data     
	parameter INIT_FILE_COS = ""    // 	
)
(
	input 							i_clock  , // system clock
	input 							i_reset  , // system reset
	input						    i_enable , // module enable
	input	 	   [7:0]			i_step	 , // step of the wave
	output signed  [READ_WIDTH-1:0]	o_dataSin, // Signal Sin output
	output signed  [READ_WIDTH-1:0]	o_dataCos   // Signal Cos output  
);
//___Registers___//
reg signed [READ_WIDTH-1:0] read_vector_Sin [READ_DEPTH-1:0];
reg signed [READ_WIDTH-1:0] read_vector_Cos [READ_DEPTH-1:0];
reg signed [READ_WIDTH-1:0] RegdatosSin ;
reg signed [READ_WIDTH-1:0] RegdatosCos ;
reg		   [13:0]	  	    Regcount    ; 
reg 	   [11:0]		    RegPtr	    ;

wire [13:0] limit1; //value of limit1: 2500
wire [13:0] limit2; //value of limit2: 2499
wire [13:0] limit3; //value of limit3: 5000
wire [13:0] limit4; //value of limit4: 4999
wire [13:0] limit5; //value of limit5: 7500
wire [13:0] limit6; //value of limit6: 7499
wire [14:0] limit7; //value of limit7: 10000

// Fill the arrays with the values from the .dat files
initial begin
	$readmemb(INIT_FILE_SIN, read_vector_Sin, 0, READ_DEPTH-1);
	$readmemb(INIT_FILE_COS, read_vector_Cos, 0, READ_DEPTH-1);
end  

always @(posedge i_clock) begin 

	if (i_reset)begin					
		Regcount  	<= 14'b0;
		RegPtr      <= 12'b0;
		RegdatosSin <= 8'b0 ;
		RegdatosCos <= 8'b0 ;
	end
	else if(i_enable == 1'b1) begin
		//RegPtr <= 2499;   
		if (Regcount < limit1) begin
			RegdatosSin	<=  read_vector_Sin[RegPtr];     //Take the first 1/4 wave 
			RegdatosCos	<=	read_vector_Cos[RegPtr];                  
			if (((1'b1 << i_step)- 1'b1) != 1'b0) RegPtr <= RegPtr + ((1'b1 << i_step)-1'b1);
			else RegPtr <= RegPtr + ((1'b1 << i_step));
			
		end 
		 
		else if (Regcount > limit2 && Regcount < limit3) begin
			RegdatosSin	<=	read_vector_Sin[RegPtr];     //Take the 2nd 1/4 wave
			RegdatosCos <=	-read_vector_Cos[RegPtr];
			
			if (((1'b1 << i_step)- 1'b1) != 1'b0) RegPtr <= RegPtr - ((1'b1 << i_step)-1'b1);
			else RegPtr <= RegPtr - ((1'b1 << i_step));				
		end

		else if (Regcount > limit4 && Regcount < limit5) begin
			RegdatosSin	<=	-read_vector_Sin[RegPtr];	//Take the 3rd 1/4 wave
			RegdatosCos	<=	-read_vector_Cos[RegPtr];
			
			if (((1'b1 << i_step)- 1'b1) != 1'b0) RegPtr <= RegPtr + ((1'b1 << i_step)-1'b1);
			else RegPtr <= RegPtr + ((1'b1 << i_step));
		end

		else if (Regcount > limit6 && Regcount < limit7) begin 
			RegdatosSin	<=	-read_vector_Sin[RegPtr]; //Take the 4th 1/4 wave  
			RegdatosCos	<=	read_vector_Cos[RegPtr];	
				
			if (((1'b1 << i_step)- 1'b1) != 1'b0) RegPtr <= RegPtr - ((1'b1 << i_step)-1'b1);
			else RegPtr <= RegPtr - ((1'b1 << i_step)); 		
		end

		else RegPtr <=  RegPtr;         
		if(Regcount < (15'd9999 >> i_step)) begin
		   Regcount	<=	Regcount + 1'b1;
				
		end else if(Regcount == (15'd9999 >> i_step)) begin //CHECK 
			Regcount   <= 0;
			RegPtr	   <= 0;
		end
	  
	end //End of else if begin 	
end //End of always


//___Assignment of the limits depending on the step___//
assign	limit1 = (i_step == 4'd0) ? (14'd2499 >> i_step)  : ( 14'd2500  >> i_step      );
assign	limit2 = (i_step == 4'd0) ? (14'd2499 >> i_step)  : ((14'd2500  >> i_step)-1'b1);
assign 	limit3 = (i_step == 4'd0) ? (14'd4999 >> i_step)  : ((14'd5000  >> i_step)     );
assign  limit4 = (i_step == 4'd0) ? (14'd4999 >> i_step)  : ((14'd5000  >> i_step)-1'b1);
assign 	limit5 = (i_step == 4'd0) ? (14'd7499 >> i_step)  : ((14'd7500  >> i_step)     );
assign 	limit6 = (i_step == 4'd0) ? (14'd7499 >> i_step)  : ((14'd7500  >> i_step)-1'b1);
assign  limit7 = (i_step == 4'd0) ? (15'd9999 >> i_step)  : ( 15'd10000 >> i_step      );

//___Assignment of the outputs___//
assign	o_dataSin = RegdatosSin;
assign	o_dataCos = RegdatosCos;

endmodule
