// top_tb.v
// ------------------------------------------------------------------
// This is the testbench file for motion estimator.
// Relative files: top.v main_top.v
// Created by: Jia Huang, Da-Hsien Lin, Xu Zhou
// 2009.5
// ------------------------------------------------------------------

`timescale 1ns/10ps
/*module timeunit;
   initial $timeformat(-9,1," ns",10);
endmodule*/

// Here is the testbench proper:
module top_testbench ( ) ;

    // Test bench gets wires for all device under test (DUT) outputs:

   wire [7:0] BestDist;
   wire [3:0] motionX, motionY;

   // Regs for all DUT inputs:
   reg               clock;
   reg               start;
  
   reg completed;
   reg [7:0]	    Rmem[255:0]; 
   reg [7:0]	    Smem[1023:0];
   integer 		i;
   integer 		j;
   integer signed x, y;
   wire [7:0] R, S1, S2;
	wire [7:0] AddressR;
	wire [9:0] AddressS1, AddressS2;

//(dut means device under test)
   top dut (
   	.BestDist(BestDist [7:0]),
		.motionX(motionX [3:0]),
		.motionY(motionY [3:0]),
      .clock(clock),
		.start(start),
		.AddressR(AddressR),
		.AddressS1(AddressS1),
		.AddressS2(AddressS2),
		.R(R),
		.S1(S1),
		.S2(S2));

//Referesen and search memories

	ROM_R memR_u(.clock(clock), .AddressR(AddressR), .R(R));

	ROM_S memS_u(.clock(clock), .AddressS1(AddressS1), .AddressS2(AddressS2), .S1(S1), .S2(S2));


  // Setup clock to automatically strobe with a period of 20.
   always #10 clock = ~clock;

   initial
     begin
     	$vcdpluson;
        // First setup up to monitor all inputs and outputs
        $monitor ("time=%5d ns, clock =%b, start =%b, BestDist =%b, motionX =%d, motionY =%d, count =%d", $time, clock, start , BestDist[7:0], motionX[3:0], motionY[3:0], dut.ctl_u.count[12:0]);
	
        // First initialize all registers
	$readmemh("ref.txt", memR_u.Rmem);
	$readmemh("search.txt", memS_u.Smem);
	clock = 1'b0;
	start = 1'b0;
	completed = 1'b1;

	@(posedge clock);#10;
	start = 1'b1;
	completed = 1'b0;
	
	for(i=0;i<4112;i=i+1)
		begin
		  
                  if (dut.comp_u.newBest == 1'b1) 
		    begin
                      $display("New Result Coming!");
		    end
		    @(posedge clock);#10;
		end

	start = 1'b0;
	completed = 1'b1;

	@(posedge clock);#10;

        if (motionX >= 8)
	 x = motionX - 16;
	else
	 x = motionX;

	if (motionY >= 8)
	  y = motionY - 16;
        else
	  y = motionY;
	
	if (BestDist == 8'b11111111)
		$display("Not Found the frame in the Search Window!");
	else
	    begin
	        if (BestDist == 8'b00000000)
		    $display("Absolutely Found the frame the Search Window : motionX  = %d , motionY =  %d ", x , y);
		else
		    $display("Almost Found the frame the Search Window : BestDist = %d, motionX  = %d , motionY =  %d ", BestDist, x, y );
	    end

	$display("All tests completed\n\n");

        $finish;
     end

   // This is to create a dump file for offline viewing.
   initial
     begin
        $dumpfile ("top.dump");
        $dumpvars (0, top_testbench);
     end 

endmodule // top_testbench
