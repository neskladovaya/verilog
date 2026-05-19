// Systolic array with credits.
module sa_credited #(
    parameter WIDTH   = 16,
    parameter SIZE    = 4,
    parameter CREDITS = 8
)(
    input  logic                        clk,
    input  logic                        rst_n,

    input  logic                        i_vld,
    input  logic                        is_b,
    input  logic [SIZE-1:0][WIDTH-1:0]  i_ab,
    input  logic                        i_rdy,

    output logic                        o_vld,
    output logic [SIZE-1:0][WIDTH-1:0]  o_c,
    output logic                        o_rdy
);

    logic i_a_vld;
    logic i_c_vld;
    logic o_c_vld;
    logic i_we;
    logic [SIZE-1:0][WIDTH-1:0] o_c_rows;
    logic o_full;
    logic o_empty;
    logic i_wr_en;
    logic i_rd_en;
    logic inc;

    assign i_we     = is_b & i_a_vld;
    assign i_c_vld  = is_b ? 1'b0 : i_a_vld;
    assign i_wr_en  = o_c_vld & ~o_full;
    assign i_rd_en  = i_rdy   & ~o_empty;
    assign o_vld    = !o_empty;
    assign inc      = o_vld & i_rdy;

    fifo #(
        .ADDRW($clog2(CREDITS + 1)),
        .DATAW(SIZE * WIDTH)
    ) fifo_inst (
        .clk       (clk),
        .i_rd_en   (i_rd_en),
        .o_rd_data (o_c),
        .i_wr_en   (i_wr_en),
        .i_wr_data (o_c_rows),
        .o_full    (o_full),
        .o_empty   (o_empty)
    );

    credit_cnt #(
        .MAX_CRD(CREDITS)
    ) credit_cnt_inst (
        .clk   (clk),
        .rst_n (rst_n),
        .i_inc (inc),
        .is_b  (is_b),
        .i_vld (i_vld),
        .o_vld (i_a_vld),
        .o_rdy (o_rdy)
    );

    sa_top #(
        .WIDTH(WIDTH),
        .SIZE (SIZE)
    ) sa (
        .clk     (clk),
        .rst_n   (rst_n),
        .i_a_vld (i_a_vld),
        .i_a     (i_ab),
        .i_we    (i_we),
        .i_c_vld (i_c_vld),
        .o_c_vld (o_c_vld),
        .o_c     (o_c_rows)
    );

endmodule

