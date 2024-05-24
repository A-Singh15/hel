`timescale 1ns/1ps

interface main_if(input bit clk);
    // Interface signals
    logic start;
    logic [7:0] BestDist;
    logic [3:0] motionX;
    logic [3:0] motionY;
    logic completed;
    logic [7:0] AddressR;
    logic [9:0] AddressS1, AddressS2;
    logic [7:0] R, S1, S2;

    // Clocking block for driver
    clocking cb @(posedge clk);
        default input #1 output #1;
        output start, R, S1, S2;
        input BestDist, motionX, motionY, completed, AddressR, AddressS1, AddressS2;
    endclocking

    // Modport for driver
    modport test (clocking cb, input clk);
endinterface

interface mem_est_if(input bit clk);
    // Interface signals
    logic start;
    logic [7:0] BestDist;
    logic [3:0] motionX;
    logic [3:0] motionY;
    logic completed;
    logic [7:0] AddressR;
    logic [9:0] AddressS1, AddressS2;
    logic [7:0] R, S1, S2;

    // Clocking block for driver
    clocking cb @(posedge clk);
        default input #1 output #1;
        output start, R, S1, S2;
        input BestDist, motionX, motionY, completed, AddressR, AddressS1, AddressS2;
    endclocking

    // Modport for driver
    modport DRIVER (clocking cb, input clk);
endinterface
