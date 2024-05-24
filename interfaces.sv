`timescale 1ns/1ps

// Main interface declaration
interface main_if(input bit clk);
    logic start;
    logic completed;
    logic [7:0] BestDist;
    logic [3:0] motionX, motionY;
    logic [7:0] R, S1, S2;
    logic [7:0] AddressR;
    logic [9:0] AddressS1, AddressS2;

    // Driver clocking block
    clocking cb @(posedge clk);
        default input #1 output #1;
        output R;
        output S1;
        output S2;
        output start;
        input BestDist;
        input motionX;
        input motionY;
        input completed;
        input AddressR;
        input AddressS1;
        input AddressS2;
    endclocking

    // Modport for driving signals
    modport test (clocking cb, input clk);
endinterface : main_if

// Memory Estimator Interface
interface mem_est_if(input bit clk);
    bit start;
    logic [3:0] motionX;
    logic [3:0] motionY;
    integer Expected_motionX;
    integer Expected_motionY;
    logic [7:0] AddressR;
    logic [9:0] AddressS1;
    logic [9:0] AddressS2;
    logic [7:0] R;
    logic [7:0] S1;
    logic [7:0] S2;
    logic [7:0] BestDist;
    logic completed;
    logic [7:0] R_mem[`RMEM_MAX-1:0];
    logic [7:0] S_mem[`SMEM_MAX-1:0];

    // Clocking block for driver
    clocking ME_driver_cb @(posedge clk);
        default input #1 output #1;
        output R_mem;
        output S_mem;
        output R;
        output S1;
        output S2;
        output Expected_motionX;
        output Expected_motionY;
        input BestDist;
        input motionX, motionY;
        input AddressR;
        input AddressS1;
        input AddressS2;
        input completed;
    endclocking

    // Clocking block for monitor
    clocking ME_monitor_cb @(posedge clk);
        default input #1 output #1;
        input R_mem;
        input S_mem;
        input R;
        input S1;
        input S2;
        input Expected_motionX;
        input Expected_motionY;
        input motionX, motionY;
        input AddressR;
        input AddressS1;
        input AddressS2;
        input completed;
        input BestDist;
    endclocking

    // Modport for driver
    modport ME_DRIVER (clocking ME_driver_cb, input clk, start);

    // Modport for monitor
    modport ME_MONITOR (clocking ME_monitor_cb, input clk, start);
endinterface
