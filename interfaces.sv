`timescale 1ns/1ps

interface main_if(input bit clk);
    // Interface signals
    logic start;
    logic completed;
    logic [7:0] BestDist;
    logic [3:0] motionX, motionY;
    logic [7:0] R, S1, S2;
    logic [7:0] AddressR;
    logic [9:0] AddressS1, AddressS2;

    // Driver clocking block
    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output R, S1, S2, start;
        input BestDist, motionX, motionY, completed, AddressR, AddressS1, AddressS2;
    endclocking

    // Driver modport
    modport DRIVER (clocking driver_cb, input clk);

endinterface : main_if

interface mem_est_if(input bit clk);
    // Signals
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
        output R_mem, S_mem, R, S1, S2, Expected_motionX, Expected_motionY;
        input BestDist, motionX, motionY, AddressR, AddressS1, AddressS2, completed;
    endclocking
    
    // Clocking block for monitor
    clocking ME_monitor_cb @(posedge clk);
        default input #1 output #1;
        input R_mem, S_mem, R, S1, S2, Expected_motionX, Expected_motionY, motionX, motionY, AddressR, AddressS1, AddressS2, completed, BestDist;
    endclocking
    
    // Modport for driver
    modport ME_DRIVER (clocking ME_driver_cb, input clk, start);
    
    // Modport for monitor
    modport ME_MONITOR (clocking ME_monitor_cb, input clk, start);

endinterface : mem_est_if
