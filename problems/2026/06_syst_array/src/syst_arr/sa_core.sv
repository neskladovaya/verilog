// Systolic array core (unaligned).
module sa_core #(
    parameter int SIZE  = 4,
    parameter int WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,

    input  logic [SIZE-1:0][WIDTH-1:0] i_a,
    input  logic [SIZE-1:0]            i_a_vld,
    input  logic [SIZE-1:0]            i_we,

    output logic [SIZE-1:0][WIDTH-1:0] o_c,
    output logic [SIZE-1:0]            o_c_vld,
    input  logic [SIZE-1:0]            i_c_vld
);

    logic [WIDTH-1:0] a_bus     [SIZE:0][SIZE:0];
    logic             a_vld_bus [SIZE:0][SIZE:0];

    logic [WIDTH-1:0] c_bus     [SIZE:0][SIZE:0];
    logic             c_vld_bus [SIZE:0][SIZE:0];

    logic             we_bus    [SIZE:0][SIZE:0];

    genvar i, j;
    generate
        for (i = 0; i < SIZE; i++) begin : gen_A
            assign a_bus     [i][0] = i_a     [i];
            assign a_vld_bus [i][0] = i_a_vld [i];
        end

        for (j = 0; j < SIZE; j++) begin : gen_C
            assign c_bus     [0][j] = '0;
            assign c_vld_bus [0][j] = i_c_vld [j];
        end

        for (j = 0; j < SIZE; j++) begin : gen_WE
            assign we_bus    [0][j] = i_we    [j];
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

                    .i_a_vld (a_vld_bus [i][j]),
                    .i_a     (a_bus     [i][j]),
                    .i_we    (we_bus    [i][j]),

                    .i_c_vld (c_vld_bus [i][j]),
                    .i_c     (c_bus     [i][j]),

                    .o_a_vld (a_vld_bus [i][j+1]),
                    .o_a     (a_bus     [i][j+1]),
                    .o_c_vld (c_vld_bus [i+1][j]),
                    .o_c     (c_bus     [i+1][j]),
                    .o_we    (we_bus    [i+1][j])
                );
            end
        end
    endgenerate

    generate
        for (j = 0; j < SIZE; j++) begin : gen_BOTTOM
            assign o_c[j]     = c_bus[SIZE][j];
            assign o_c_vld[j] = c_vld_bus[SIZE][j];
        end
    endgenerate
endmodule

