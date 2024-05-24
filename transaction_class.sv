`timescale 1ns/1ps

class transaction_class;
    rand logic start;
    rand logic [7:0] R, S1, S2;
    logic completed;
    logic [7:0] BestDist;
    logic [3:0] motionX, motionY;
    logic [7:0] AddressR;
    logic [9:0] AddressS1, AddressS2;

    function void display(string name);
        $display("-------------------------------------------------------");
        $display("----------- %s ----------", name);
        $display("-------------------------------------------------------");
        $display("- Time        = %0d ns", $time);
        $display("- R  = %0h S1 = %0h, S2 = %0h", R, S1, S2);
        $display("- start       = %0d", start);
        $display("- completed   = %0d", completed);
        $display("- AddressR    = %0h", AddressR);
        $display("- AddressS1   = %0h", AddressS1);
        $display("- AddressS2   = %0h", AddressS2);
        $display("- BestDist    = %0h", BestDist);
        $display("- motionX     = %0h", motionX);
        $display("- motionY     = %0h", motionY);
        $display("-------------------------------------------------------");
    endfunction
endclass
