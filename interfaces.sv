`ifndef INTERFACES_SV
`define INTERFACES_SV

interface main_if(input bit clk);
  logic start;
  logic completed;
  logic [7:0] BestDist;
  logic [3:0] motionX, motionY;
  logic [7:0] R, S1, S2;
  logic [7:0] AddressR;
  logic [9:0] AddressS1, AddressS2;
endinterface

interface mem_est_if(input bit clk);
  logic start;
  logic completed;
  logic [7:0] BestDist;
  logic [3:0] motionX, motionY;
  logic [7:0] R, S1, S2;
  logic [7:0] AddressR;
  logic [9:0] AddressS1, AddressS2;
endinterface

`endif
