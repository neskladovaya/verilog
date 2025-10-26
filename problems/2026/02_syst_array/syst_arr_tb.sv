`timescale 1ns/1ps

module syst_arr_tb;

logic clk   = 1'b0;
logic rst_n = 1'b1;

always begin
    #1 clk = ~clk;
end

parameter WIDTH = 32;
parameter SIZE = 2;

logic             we;
logic             a_vld;
logic [WIDTH-1:0] a_row [SIZE];
logic             c_vld;
logic [WIDTH-1:0] c_row [SIZE];

syst_arr #(.SIZE(2), .WIDTH(32)) syst_arr (
    .clk     (clk),
    .rst_n   (rst_n),
    .i_we    (we),
    .i_a_row_vld (a_vld),
    .i_a_row (a_row),
    .o_c_row_vld (c_vld),
    .o_c_row (c_row)
);

initial begin
    $dumpvars;
    we = 0;
    rst_n = 1'b0; #1; rst_n = 1'b1; #2;

    a_vld = 1; a_row = {32'd1, 32'd2};
    #2;
    we = 1; a_vld = 1; a_row = {32'd3, 32'd4};

    #5

    $finish;
end

endmodule

