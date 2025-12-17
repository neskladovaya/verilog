`timescale 1ns/1ps

module syst_arr_tb;

logic clk   = 1'b0;
logic rst_n = 1'b1;

always begin
    #1 clk = ~clk;
end

parameter WIDTH = 32;
parameter SIZE = 4;

logic                          we;
logic                       a_vld;
logic [SIZE-1:0][WIDTH-1:0] a_rows;
logic                       c_vld;
logic                     o_c_vld;
logic [SIZE-1:0][WIDTH-1:0] c_rows;

sa_top  #(.SIZE(SIZE), .WIDTH(WIDTH)) syst_arr (
    .clk        (clk),
    .rst_n      (rst_n),
    .i_we       (we),
    .i_a_vld    (a_vld),
    .i_a        (a_rows),
    .o_c_vld    (o_c_vld),
    .o_c        (c_rows),
    .i_c_vld    (c_vld)
);

import "DPI-C" function void mat_mul(
    input int a[4][4],
    input int b[4][4]
);

initial begin
    $dumpfile("dump.vcd");
    $dumpvars;

    we      = 0;
    a_vld   = 0;
    c_vld   = 0;
    repeat (1) @(posedge clk);

    for (int i = SIZE - 1; i >= 0; i--) begin
        // Turn on -- turn off.
        a_vld = 0;
        we = 0;
        @(posedge clk);
        for (int j = 0; j < SIZE; j++) begin
            a_rows[j] = j * SIZE + i + 1;
        end
        a_vld = 1;
        we = 1;
        @(posedge clk);
    end

    we = 0;
    repeat (10) @(posedge clk);

    for (int i = 0; i < SIZE; i++) begin
        // Turn on -- turn off.
        a_vld = 0;
        c_vld = 0;
        @(posedge clk);
        a_vld = 1;
        c_vld = 1;
        for (int j = 0; j < SIZE; j++) begin
            a_rows[j] = i * SIZE + j + 1;
        end
        @(posedge clk);
    end

    a_vld = 0;
    c_vld = 0;

    while (!o_c_vld);
        @(posedge clk);

    for (int i = 0; i < SIZE; i++) begin
        for (int j = 0; j < SIZE; j++) begin
            int c_val = c_rows[j];
            $display("%d", c_val);
        end
        @(posedge clk);
        while (!o_c_vld);
            @(posedge clk);
    end

    #20ns;
    $finish();
end

endmodule

