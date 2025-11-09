// Systolic array.
module sa_core #(
    parameter int SIZE  = 4,
    parameter int WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,

    input  logic [SIZE-1:0][WIDTH-1:0] i_a,
    input  logic [SIZE-1:0]            i_a_vld,

    input  logic [SIZE-1:0][WIDTH-1:0] i_b,
    input  logic [SIZE-1:0]            i_b_we,

    output logic [SIZE-1:0][WIDTH-1:0] o_c,
    output logic [SIZE-1:0]            o_c_vld
);

    logic [SIZE:0][SIZE-1:0][WIDTH-1:0] a_bus;
    logic [SIZE-1:0][SIZE:0][WIDTH-1:0] c_bus;

    logic [SIZE:0][SIZE-1:0] a_vld_bus;
    logic [SIZE-1:0][SIZE:0] c_vld_bus;
    logic [SIZE-1:0][SIZE-1:0] we_bus;

    genvar i, j;
    generate
        for (i = 0; i < SIZE; i++) begin : gen_A
            assign a_bus[0][i]    = i_a[i];
            assign a_vld_bus[0][i]= i_a_vld[i];
        end

        for (j = 0; j < SIZE; j++) begin : gen_C
            assign c_bus[j][0]     = '0;
            assign c_vld_bus[j][0] = 1'b1;
        end
    endgenerate

    generate
        for (i = 0; i < SIZE; i++) begin : gen_ROW
            for (j = 0; j < SIZE; j++) begin : gen_COL
                pe #(
                    .WIDTH(WIDTH)
                ) pe_inst (
                    .clk   (clk),
                    .rst_n (rst_n),

                    .i_a_vld (a_vld_bus[j][i]),
                    .i_a     (a_bus[j][i]),
                    .i_we    (i_b_we[j]),

                    .i_c_vld (c_vld_bus[i][j]),
                    .i_c     (c_bus[i][j]),

                    .o_a_vld (a_vld_bus[j+1][i]),
                    .o_a     (a_bus[j+1][i]),
                    .o_c_vld (c_vld_bus[i][j+1]),
                    .o_c     (c_bus[i][j+1]),
                    .o_we    (we_bus[i][j])
                );
            end
        end
    endgenerate

    generate
        for (j = 0; j < SIZE; j++) begin
            assign o_c[j]     = c_bus[SIZE-1][j+1];
            assign o_c_vld[j] = c_vld_bus[SIZE-1][j+1];
        end
    endgenerate
endmodule

