`timescale 1ns/1ps
`include "environment.sv"

program test_program(main_if intf);
    test_environment env;

    initial begin
        env = new(intf);
        env.build();
        env.run();
        env.wrap_up();
    end
endprogram
