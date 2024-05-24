`timescale 1ns/1ps

interface consolidated_if(input bit clk);
    // Interface signals
    logic start;
    logic completed;
    logic [7:0] BestDist;
    logic [3:0] motionX, motionY;
    logic [7:0] R, S1, S2;
    logic [7:0] AddressR;
    logic [9:0] AddressS1, AddressS2;
    integer Expected_motionX;
    integer Expected_motionY;
    logic [7:0] R_mem[`RMEM_MAX-1:0];
    logic [7:0] S_mem[`SMEM_MAX-1:0];

    // Driver clocking block
    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output R, S1, S2, start, R_mem, S_mem, Expected_motionX, Expected_motionY;
        input BestDist, motionX, motionY, completed, AddressR, AddressS1, AddressS2;
    endclocking

    // Monitor clocking block
    clocking monitor_cb @(posedge clk);
        default input #1 output #1;
        input R, S1, S2, Expected_motionX, Expected_motionY, motionX, motionY, AddressR, AddressS1, AddressS2, completed, BestDist, R_mem, S_mem;
    endclocking

    // Driver modport
    modport DRIVER (clocking driver_cb, input clk, start);

    // Monitor modport
    modport MONITOR (clocking monitor_cb, input clk, start);

endinterface : consolidated_if
