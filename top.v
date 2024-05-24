`timescale 1ns/1ps

/* Module For Top Level Hierarchy */
module top_level (
    input logic clk,
    input logic start_signal,
    output logic [7:0] best_distance,
    output logic [3:0] motion_vector_x,
    output logic [3:0] motion_vector_y,
    output logic process_completed,
    output logic [7:0] address_ref,
    output logic [9:0] address_search1,
    output logic [9:0] address_search2,
    input logic [7:0] ref_data,
    input logic [7:0] search_data1,
    input logic [7:0] search_data2
);
    wire [15:0] mux_control, new_distance, pe_ready;
    wire comp_start_signal;
    wire [3:0] vector_x, vector_y;
    wire [127:0] accumulate_result;

    control_unit ctrl_u(
        .clk(clk),
        .start(start_signal),
        .mux_control(mux_control),
        .new_distance(new_distance),
        .comp_start(comp_start_signal),
        .pe_ready(pe_ready),
        .vector_x(vector_x),
        .vector_y(vector_y),
        .address_ref(address_ref),
        .address_search1(address_search1),
        .address_search2(address_search2),
        .completed(process_completed)
    );

    pe_total pe_u(
        .clk(clk),
        .ref_data(ref_data),
        .search_data1(search_data1),
        .search_data2(search_data2),
        .mux_control(mux_control),
        .new_distance(new_distance),
        .accumulate_result(accumulate_result)
    );

    comparator comp_u(
        .clk(clk),
        .comp_start(comp_start_signal),
        .accumulate_result(accumulate_result),
        .pe_ready(pe_ready),
        .vector_x(vector_x),
        .vector_y(vector_y),
        .best_distance(best_distance),
        .motion_vector_x(motion_vector_x),
        .motion_vector_y(motion_vector_y)
    );
endmodule

/* Module For Processing Element (PE) */
module processing_element (
    input clk,
    input [7:0] ref_data, search_data1, search_data2,
    input mux_control, new_distance,
    output [7:0] accumulate_result, pipe_reg
);
    reg [7:0] accumulate_reg, accumulate_in, diff, diff_temp;
    reg carry;

    always @(posedge clk) pipe_reg <= ref_data;
    always @(posedge clk) accumulate_reg <= accumulate_in;

    always @(*) begin
        diff = ref_data - (mux_control ? search_data1 : search_data2);
        diff_temp = -diff;
        if (diff < 0) diff = diff_temp;
        {carry, accumulate_in} = accumulate_reg + diff;
        if (carry == 1) accumulate_in = 8'hFF; // saturated
        if (new_distance == 1) accumulate_in = diff;
    end
    assign accumulate_result = accumulate_reg;
endmodule

/* Module For The Last Processing Element (PEend) */
module processing_element_end (
    input clk,
    input [7:0] ref_data, search_data1, search_data2,
    input mux_control, new_distance,
    output [7:0] accumulate_result
);
    reg [7:0] accumulate_reg, accumulate_in, diff, diff_temp;
    reg carry;

    always @(posedge clk) accumulate_reg <= accumulate_in;

    always @(*) begin
        diff = ref_data - (mux_control ? search_data1 : search_data2);
        diff_temp = -diff;
        if (diff < 0) diff = diff_temp;
        {carry, accumulate_in} = accumulate_reg + diff;
        if (carry == 1) accumulate_in = 8'hFF; // saturated
        if (new_distance == 1) accumulate_in = diff;
    end
    assign accumulate_result = accumulate_reg;
endmodule

/* Module For Control Unit */
module control_unit (
    input clk,
    input start_signal,
    output reg [15:0] mux_control, new_distance, pe_ready,
    output reg comp_start_signal,
    output reg [3:0] vector_x, vector_y,
    output reg [7:0] address_ref,
    output reg [9:0] address_search1, address_search2,
    output reg process_completed
);
    parameter total_count = 16 * (16 * 16) + 15; // 4111

    reg [12:0] count, count_temp;
    integer i;

    always @(posedge clk) begin
        if (start_signal == 0) count <= 12'b0;
        else if (process_completed == 0) count <= count_temp;
    end

    always @(*) begin
        count_temp = count + 1'b1;
        for (i = 0; i < 16; i = i + 1) begin
            new_distance[i] = (count[7:0] == i);    
            pe_ready[i] = (new_distance[i] && !(count < 256));    
            mux_control[i] = (count[3:0] >= i);
            comp_start_signal = (!(count < 256));
        end

        address_ref = count[7:0];
        address_search1 = (count[11:8] + count[7:4]) * 32 + count[3:0];
        address_search2 = ((count[11:0] - 16) * 32 + (count[11:0] - 16) + 16);

        vector_x = count[3:0] - 8; 
        vector_y = count[11:8] - 9;

        process_completed = (count[12:0] == total_count); // 4111
    end
endmodule

/* Module For Comparator Unit */
module comparator (
    input clk,
    input comp_start_signal,
    input [127:0] accumulate_result,
    input [15:0] pe_ready,
    input [3:0] vector_x, vector_y,
    output reg [7:0] best_distance,
    output reg [3:0] motion_vector_x, motion_vector_y
);
    reg [7:0] new_distance;
    reg new_best;
    integer n;

    always @(posedge clk) begin
        if (comp_start_signal == 0) best_distance <= 8'hFF; // initialize to highest value
        else if (new_best == 1) begin
            best_distance <= new_distance;
            motion_vector_x <= vector_x;
            motion_vector_y <= vector_y;
        end
    end

    always @(*) begin
        new_distance = 8'hFF;
        for (n = 0; n <= 15; n = n + 1) begin
            if (pe_ready[n] == 1) begin
                case (n)
                    4'b0000: new_distance = accumulate_result[7:0];
                    4'b0001: new_distance = accumulate_result[15:8]; 
                    4'b0010: new_distance = accumulate_result[23:16]; 
                    4'b0011: new_distance = accumulate_result[31:24];
                    4'b0100: new_distance = accumulate_result[39:32]; 
                    4'b0101: new_distance = accumulate_result[47:40]; 
                    4'b0110: new_distance = accumulate_result[55:48]; 
                    4'b0111: new_distance = accumulate_result[63:56]; 
                    4'b1000: new_distance = accumulate_result[71:64]; 
                    4'b1001: new_distance = accumulate_result[79:72]; 
                    4'b1010: new_distance = accumulate_result[87:80]; 
                    4'b1011: new_distance = accumulate_result[95:88]; 
                    4'b1100: new_distance = accumulate_result[103:96]; 
                    4'b1101: new_distance = accumulate_result[111:104]; 
                    4'b1110: new_distance = accumulate_result[119:112]; 
                    4'b1111: new_distance = accumulate_result[127:120];
                    default: new_distance = 8'hFF;  
                endcase
            end
        end

        if ((|pe_ready == 0) || (comp_start_signal == 0)) new_best = 0;
        else if (new_distance < best_distance) new_best = 1;
        else new_best = 0;
    end
endmodule

/* Module For Total 16 Processing Elements (PEtotal) */
module pe_total (
    input clk,
    input [7:0] ref_data, search_data1, search_data2,
    input [15:0] mux_control, new_distance,
    output [127:0] accumulate_result
);
    wire [7:0] pipe_reg0, pipe_reg1, pipe_reg2, pipe_reg3, pipe_reg4, pipe_reg5, pipe_reg6, pipe_reg7, pipe_reg8, pipe_reg9, pipe_reg10, pipe_reg11, pipe_reg12, pipe_reg13, pipe_reg14;

    processing_element pe0 (clk, ref_data, search_data1, search_data2, mux_control[0], new_distance[0], accumulate_result[7:0], pipe_reg0);
    processing_element pe1 (clk, pipe_reg0, search_data1, search_data2, mux_control[1], new_distance[1], accumulate_result[15:8], pipe_reg1);
    processing_element pe2 (clk, pipe_reg1, search_data1, search_data2, mux_control[2], new_distance[2], accumulate_result[23:16], pipe_reg2);
    processing_element pe3 (clk, pipe_reg2, search_data1, search_data2, mux_control[3], new_distance[3], accumulate_result[31:24], pipe_reg3);
    processing_element pe4 (clk, pipe_reg3, search_data1, search_data2, mux_control[4], new_distance[4], accumulate_result[39:32], pipe_reg4);
    processing_element pe5 (clk, pipe_reg4, search_data1, search_data2, mux_control[5], new_distance[5], accumulate_result[47:40], pipe_reg5);
    processing_element pe6 (clk, pipe_reg5, search_data1, search_data2, mux_control[6], new_distance[6], accumulate_result[55:48], pipe_reg6);
    processing_element pe7 (clk, pipe_reg6, search_data1, search_data2, mux_control[7], new_distance[7], accumulate_result[63:56], pipe_reg7);
    processing_element pe8 (clk, pipe_reg7, search_data1, search_data2, mux_control[8], new_distance[8], accumulate_result[71:64], pipe_reg8);
    processing_element pe9 (clk, pipe_reg8, search_data1, search_data2, mux_control[9], new_distance[9], accumulate_result[79:72], pipe_reg9);
    processing_element pe10 (clk, pipe_reg9, search_data1, search_data2, mux_control[10], new_distance[10], accumulate_result[87:80], pipe_reg10);
    processing_element pe11 (clk, pipe_reg10, search_data1, search_data2, mux_control[11], new_distance[11], accumulate_result[95:88], pipe_reg11);
    processing_element pe12 (clk, pipe_reg11, search_data1, search_data2, mux_control[12], new_distance[12], accumulate_result[103:96], pipe_reg12);
    processing_element pe13 (clk, pipe_reg12, search_data1, search_data2, mux_control[13], new_distance[13], accumulate_result[111:104], pipe_reg13);
    processing_element pe14 (clk, pipe_reg13, search_data1, search_data2, mux_control[14], new_distance[14], accumulate_result[119:112], pipe_reg14);
    processing_element_end pe15 (clk, pipe_reg14, search_data1, search_data2, mux_control[15], new_distance[15], accumulate_result[127:120]);
endmodule

/* Module For Reference Block (Memory) */
module ref_memory (
    input clk,
    input [7:0] address_ref,
    output logic [7:0] ref_data
);
    logic [7:0] ref_memory_array[0:255];

    always @(*) ref_data = ref_memory_array[address_ref];
endmodule

/* Module For Search Block (Memory) */
module search_memory (
    input clk,
    input [9:0] address_search1, address_search2,
    output logic [7:0] search_data1, search_data2
);
    logic [7:0] search_memory_array[0:1023];

    always @(*) begin
        search_data1 = search_memory_array[address_search1];
        search_data2 = search_memory_array[address_search2];
    end
endmodule
