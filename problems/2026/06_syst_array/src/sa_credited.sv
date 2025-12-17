// Systolic array with credits.
module sa_credited #(
    parameter WIDTH = 32,
    parameter SIZE = 4,
    parameter CREDIT = 8
)(
    input  logic clk,
    input  logic rst_n,

    input  logic                       i_vld,
    output logic                       o_rdy,
    input  logic                       i_we,
    input  logic [SIZE-1:0][WIDTH-1:0] i_a,

    output logic                       o_vld,
    input  logic                       i_rdy,
    output logic [SIZE-1:0][WIDTH-1:0] o_c
);

logic o_c_vld;
logic [SIZE - 1:0][WIDTH - 1:0] o_c_syst;

sa_top #(.WIDTH(WIDTH), .SIZE(SIZE)) sa (
    .clk        (clk),
    .rst_n      (rst_n),
    .i_a        (i_a),
    .i_a_vld    (o_rdy && i_vld),
    .i_we       (i_we && o_rdy && i_vld),
    .i_c_vld    (!i_we && o_rdy && i_vld),
    .o_c_vld    (o_c_vld),
    .o_c        (o_c_syst)
);

logic fifo_full;
fifo #(.DATA_WIDTH(SIZE * WIDTH), .DEPTH(CREDIT)) fifo_inst (
    .clk(clk),
    .rst_n(rst_n),
    .i_vld(o_c_vld),
    .i_data(o_c_syst),
    .o_rdy(fifo_full),
    .o_vld(o_vld),
    .i_rdy(i_rdy),
    .o_data(o_c)
);

credit_cnt #(.MAX_CRD(CREDIT)) credit_cnt_inst (
    .clk    (clk),
    .rst_n  (rst_n),
    .i_inc  (o_vld & i_rdy),
    .i_vld  (i_vld & !i_we),
    .o_rdy  (o_rdy)
);

endmodule


