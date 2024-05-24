`timescale 1ns/1ps

interface main_if(input bit clk);
    logic start;
    logic completed;
    logic [7:0] BestDist;
    logic [3:0] motionX, motionY;
    logic [7:0] R, S1, S2;
    logic [7:0] AddressR;
    logic [9:0] AddressS1, AddressS2;

    clocking cb @(posedge clk);
        default input #1 output #1;
        output R, S1, S2, start;
        input BestDist, motionX, motionY, completed, AddressR, AddressS1, AddressS2;
    endclocking

    modport test (clocking cb, input clk);
endinterface

interface mem_est_if(input bit clk);
    logic start;
    logic [7:0] R, S1, S2;
    logic [7:0] BestDist;
    logic [3:0] motionX, motionY;
    logic completed;
    logic [7:0] AddressR;
    logic [9:0] AddressS1, AddressS2;

    clocking cb @(posedge clk);
        default input #1 output #1;
        output R, S1, S2, start;
        input BestDist, motionX, motionY, completed, AddressR, AddressS1, AddressS2;
    endclocking

    modport mem_est (clocking cb, input clk);
endinterface
