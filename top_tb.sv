`timescale 1ns/1ps

module top_tb();
    bit clk;
    always #10 clk = ~clk;

    initial begin
        $display("** Testbench Start **");
        mem_intf.start = 1'b0;
        repeat(2) @(posedge clk);
        mem_intf.start = 1'b1;
    end

    mem_est_if mem_intf(clk);
    ref_memory memR_u(.clk(clk), .address_ref(mem_intf.address_ref), .ref_data(mem_intf.R));
    search_memory memS_u(.clk(clk), .address_search1(mem_intf.address_search1), .address_search2(mem_intf.address_search2), .search_data1(mem_intf.S1), .search_data2(mem_intf.S2));

    assign memR_u.ref_memory_array = mem_intf.R_mem;
    assign memS_u.search_memory_array = mem_intf.S_mem;

    test_env test_instance(mem_intf);

    initial begin
        $vcdpluson();
        $dumpfile("dump.vcd"); $dumpvars;
    end

    top_level dut(
        .clk(mem_intf.clk),
        .start_signal(mem_intf.start),
        .best_distance(mem_intf.BestDist),
        .motion_vector_x(mem_intf.motionX),
        .motion_vector_y(mem_intf.motionY),
        .address_ref(mem_intf.address_ref),
        .address_search1(mem_intf.address_search1),
        .address_search2(mem_intf.address_search2),
        .ref_data(mem_intf.R),
        .search_data1(mem_intf.S1),
        .search_data2(mem_intf.S2),
        .process_completed(mem_intf.completed)
    );

    bind dut coverage_assertion assertion_instance(
        .clk(mem_intf.clk),
        .start_signal(mem_intf.start),
        .best_distance(mem_intf.BestDist),
        .motion_vector_x(mem_intf.motionX),
        .motion_vector_y(mem_intf.motionY),
        .process_completed(mem_intf.completed)
    );
endmodule
