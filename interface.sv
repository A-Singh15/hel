
interface interface;
  logic clk;
  logic reset;
  logic [7:0] data_in;
  logic [7:0] data_out;
endinterface

typedef struct {
  logic [7:0] address;
  logic [7:0] data;
  logic valid;
} transaction;
