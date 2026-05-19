// Systolic array with synced input and output.
module sa_top #(
    parameter int SIZE  = 4,
    parameter int WIDTH = 32
)(
    input logic clk,
    input logic rst_n,


    input logic [SIZE-1:0][WIDTH-1:0]  i_a,
    input logic                        i_a_vld,

    input logic                        i_we,

    output logic [SIZE-1:0][WIDTH-1:0] o_c,
    input  logic                       i_c_vld,
    output logic                       o_c_vld
);

    logic [SIZE-1:0][WIDTH-1:0] a_aligned;
    logic [SIZE-1:0]            a_vld_aligned;
    logic [SIZE-1:0]            c_vld_aligned;
    logic [SIZE-1:0]            we_aligned;

    logic [SIZE-1:0] we_pe = { 1'b1, { SIZE - 1{1'b0} } };

    always_ff @(posedge clk) begin
        if (i_we) begin
            we_pe <= {we_pe[0], we_pe[SIZE-1:1]};
        end
    end

    logic [SIZE - 1:0] we_raw;
    assign we_raw = i_we ? we_pe : 0;

    generate
        for (genvar i = 0; i < SIZE; i++) begin : gen_INPUT
            if (i == 0) begin
                assign a_aligned    [i] = i_a[i];
                assign a_vld_aligned[i] = i_a_vld;
                assign c_vld_aligned[i] = i_c_vld;
                assign we_aligned   [i] = we_raw[i];
            end else begin
                sr #(
                    .WIDTH(WIDTH),
                    .DEPTH(i)
                ) sr_a_inst (
                    .clk    (clk),
                    .i_vld  (i_a_vld),
                    .i_data (i_a[i]),
                    .o_vld  (a_vld_aligned[i]),
                    .o_data (a_aligned[i])
                );

                sr #(
                    .WIDTH(1),
                    .DEPTH(i)
                ) sr_c_vld_inst (
                    .clk    (clk),
                    .i_vld  (i_c_vld),
                    .i_data (),
                    .o_vld  (c_vld_aligned[i]),
                    .o_data ()
                );

                sr #(
                    .WIDTH(1),
                    .DEPTH(i)
                ) sr_we_inst (
                    .clk    (clk),
                    .i_vld  (we_raw[i]),
                    .i_data (),
                    .o_vld  (we_aligned[i]),
                    .o_data ()
                );
            end
        end
    endgenerate

    logic [SIZE-1:0]            o_c_vld_raw;
    logic [SIZE-1:0][WIDTH-1:0] o_c_raw;

    sa_core #(
        .WIDTH(WIDTH),
        .SIZE(SIZE)
    ) sa_core_inst(
        .clk     (clk),
        .rst_n   (rst_n),
        .i_we    (we_aligned),
        .i_a_vld (a_vld_aligned),
        .i_a     (a_aligned),
        .i_c_vld (c_vld_aligned),
        .o_c_vld (o_c_vld_raw),
        .o_c     (o_c_raw)
    );

    logic [SIZE-1:0] o_c_vld_arr;

    generate
    for (genvar i = 0; i < SIZE; i++) begin : gen_OUTPUT
        if (i == SIZE - 1) begin
            assign o_c_vld_arr[i] = o_c_vld_raw[i];
            assign o_c[i] = o_c_raw[i];
        end else begin
            sr #(
                .WIDTH(WIDTH),
                .DEPTH(SIZE-1-i)
            ) sr_inst (
                .clk    (clk),
                .i_vld  (o_c_vld_raw[i]),
                .i_data (o_c_raw[i]),
                .o_vld  (o_c_vld_arr[i]),
                .o_data (o_c[i])
            );
        end
    end
    endgenerate

    assign o_c_vld = &o_c_vld_arr;

endmodule

