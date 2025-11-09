`timescale 1ns/1ps

module syst_arr_tb;

logic clk   = 1'b0;
logic rst_n = 1'b1;

always begin
    #1 clk = ~clk;
end

parameter WIDTH = 32;
parameter SIZE = 2;

logic                          we;
logic                       a_vld;
logic [SIZE-1:0][WIDTH-1:0] a_row;
logic                       c_vld;
logic [SIZE-1:0][WIDTH-1:0] c_row;

sa_top  #(.SIZE(2), .WIDTH(32)) syst_arr (
    .clk     (clk),
    .rst_n   (rst_n),
    .i_b_we    ({2{we}}),
    .i_a_vld ({2{a_vld}}),
    .i_a (a_row),
    .o_c_vld (c_vld),
    .o_c (c_row)
);

int A [SIZE][SIZE] = '{'{32'd1, 32'd2}, '{32'd3, 32'd4}};
int B [SIZE][SIZE] = '{'{32'd1, 32'd0}, '{32'd0, 32'd1}};

import "DPI-C" function void mat_mul(
    input int a[2][2],
    input int b[2][2]
);

initial begin
   mat_mul(A, B);
end

initial begin
    $dumpvars;
    we = 0;
    rst_n = 1'b0; #1; rst_n = 1'b1; #2;

    a_vld = 1; a_row = {32'd1, 32'd2};
    #2;
    we = 1; a_vld = 1; a_row = {32'd3, 32'd4};

    #6;

    $finish;
end

endmodule

