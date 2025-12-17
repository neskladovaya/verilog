// Systolic array with synced input and output.
module sa_top #(
    parameter int SIZE  = 4,
    parameter int WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,

    input  logic [SIZE-1:0][WIDTH-1:0] i_a,
    input  logic                       i_a_vld,

    input  logic                       i_we,

    output logic [SIZE-1:0][WIDTH-1:0] o_c,
    output logic                       o_c_vld,
    input  logic                       i_c_vld
);

    logic [SIZE-1:0][WIDTH-1:0] a_aligned;
    logic [SIZE-1:0]            a_vld_aligned;
    logic [SIZE-1:0]            c_vld_aligned;
    logic [SIZE-1:0]            we_aligned;

    logic [SIZE-1:0][WIDTH-1:0] c_raw;
    logic [SIZE-1:0]            c_raw_vld;
    logic [SIZE-1:0]            c_vld_arr;

    genvar i, j;
    generate
        for (i = 0; i < SIZE; i++) begin : gen_SHIFTREG_A
            sr #(
                .DEPTH(i),
                .WIDTH(WIDTH)
            ) a_sr_inst (
                .clk    (clk),
                .rst_n  (rst_n),
                .i_vld  (i_a_vld),
                .i_data (i_a[i]),
                .o_vld  (a_vld_aligned[i]),
                .o_data (a_aligned[i])
            );
            sr #(
                .DEPTH(i),
                .WIDTH(1)
            ) c_sr_inst (
                .clk    (clk),
                .rst_n  (rst_n),
                .i_vld  (i_c_vld),
                .i_data (),
                .o_vld  (c_vld_aligned[i]),
                .o_data ()
            );
        end
    endgenerate

    generate
        for (j = 0; j < SIZE; j++) begin : gen_SHIFTREG_C
            sr #(
                .DEPTH(SIZE-j-1),
                .WIDTH(WIDTH)
            ) c_sr_inst (
                .clk    (clk),
                .rst_n  (rst_n),
                .i_vld  (c_raw_vld[j]),
                .i_data (c_raw[j]),
                .o_vld  (c_vld_arr[j]),
                .o_data (o_c[j])
            );
        end
    endgenerate

    delay_line #(
        .SIZE (SIZE)
    ) delay_line_inst (
        .clk      (clk),
        .rst_n    (rst_n),
        .i_we     (i_we),
        .o_we     (we_aligned)
    );

    sa_core #(
        .SIZE (SIZE),
        .WIDTH(WIDTH)
    ) sa_core_inst (
        .clk      (clk),
        .rst_n    (rst_n),
        .i_a      (a_aligned),
        .i_a_vld  (a_vld_aligned),
        .i_we     (we_aligned),
        .o_c      (c_raw),
        .o_c_vld  (c_raw_vld),
        .i_c_vld  (c_vld_aligned)
    );

    assign o_c_vld = &c_vld_arr;

endmodule

