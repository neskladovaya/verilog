// Systolic array.
module syst_arr #(
    parameter int SIZE  = 2,
    parameter int WIDTH = 32
)(
    input  logic             clk,
    input  logic             rst_n,

    input  logic             i_we  ,
    input  logic             i_a_row_vld ,
    input  logic [WIDTH-1:0] i_a_row [SIZE],
    output logic             o_c_row_vld,
    output logic [WIDTH-1:0] o_c_row [SIZE]
);

    logic             shiftreg2syst_vld  [SIZE];
    logic [WIDTH-1:0] shiftreg2syst_data [SIZE];

    logic             syst2shiftreg_vld  [SIZE];
    logic [WIDTH-1:0] syst2shiftreg_data [SIZE];

    logic             elem_i_a_vld  [SIZE][SIZE];
    logic [WIDTH-1:0] elem_i_a_data [SIZE][SIZE];
    logic             elem_i_c_vld  [SIZE][SIZE];
    logic [WIDTH-1:0] elem_i_c_data [SIZE][SIZE];

    logic             elem_o_a_vld  [SIZE][SIZE];
    logic [WIDTH-1:0] elem_o_a_data [SIZE][SIZE];
    logic             elem_o_c_vld  [SIZE][SIZE];
    logic [WIDTH-1:0] elem_o_c_data [SIZE][SIZE];

    always_comb begin
           elem_i_a_vld[0][0]  = shiftreg2syst_vld[0];
           elem_i_a_vld[1][0]  = shiftreg2syst_vld[1];
           elem_i_a_data[0][0] = shiftreg2syst_data[0];
           elem_i_a_data[1][0] = shiftreg2syst_data[1];

           elem_i_a_vld[0][1]  = elem_o_a_vld[0][0];
           elem_i_a_vld[1][1]  = elem_o_a_vld[1][0];
           elem_i_a_data[0][1] = elem_o_a_data[0][0];
           elem_i_a_data[1][1] = elem_o_a_data[1][0];

           elem_i_c_vld [0][0] = '0;
           elem_i_c_vld [0][1] = '0;
           elem_i_c_data[0][0] = '0;
           elem_i_c_data[0][1] = '0;

           elem_i_c_vld [1][0]  = elem_o_c_vld[0][0];
           elem_i_c_vld [1][1]  = elem_o_c_vld[0][1];
           elem_i_c_data[1][0] = elem_o_c_data[0][0];
           elem_i_c_data[1][1] = elem_o_c_data[0][1];

           syst2shiftreg_vld [0] = elem_o_c_vld [1][0];
           syst2shiftreg_vld [1] = elem_o_c_vld [1][1];
           syst2shiftreg_data[0] = elem_o_c_data[1][0];
           syst2shiftreg_data[1] = elem_o_c_data[1][1];
    end

    // genvar elem_i, elem_j;
    // generate
    //     for (elem_i = 1; elem_i < SIZE; elem_i++) begin : g_ROW
    //         for (elem_j = 1; elem_j < SIZE; elem_j++) begin : g_COLUMN
    //             assign elem_i_a_vld  [i][j] = elem_o_a_vld  [i][j-1];
    //             assign elem_i_a_data [i][j] = elem_o_a_data [i][j-1];
    //             assign elem_i_we     [i][j] = elem_o_we     [i][j-1];
    //             assign elem_i_c_vld  [i][j] = elem_o_c_vld  [i-1][j];
    //             assign elem_i_c_data [i][j] = elem_o_c_data [i-1][j];
    //         end
    //         assign elem_i_a_vld  [i][0] = shiftreg2syst_vld  [i];
    //         assign elem_i_a_data [i][0] = shiftreg2syst_data [i];
    //         assign elem_i_c_vld  [i][0] = elem_o_c_vld  [i][j-1];
    //         assign elem_i_c_data [i][0] = elem_o_c_data [i][j-1];
    //         assign elem_i_we     [i][0] = elem_o_we     [i][j-1];
    //     end
    // endgenerate

    genvar i,j;
    generate
        for (i = 0; i < SIZE; i++) begin : g_ROWS
            shiftreg  #(.WIDTH(WIDTH), .DEPTH(i)) a_sr_inst (
                .clk    (clk),
                .rst_n  (rst_n),
                .i_vld  (i_a_row_vld),
                .i_data (i_a_row[i]),
                .o_vld  (shiftreg2syst_vld[i]),
                .o_data (shiftreg2syst_data[i])
            );
            shiftreg  #(.WIDTH(WIDTH), .DEPTH(i)) c_sr_inst (
                .clk    (clk),
                .rst_n  (rst_n),
                .i_vld  (syst2shiftreg_vld[i]),
                .i_data (syst2shiftreg_data[i]),
                .o_vld  (),
                .o_data (o_c_row[i])
            );
            for (j = 0; j < SIZE; j++) begin : g_COLUMNS
                syst_elem #(.WIDTH(WIDTH)) syst_elem_inst (
                    .clk     (clk),
                    .rst_n   (rst_n),

                    .i_a_vld (elem_i_a_vld  [i][j]),
                    .i_a     (elem_i_a_data [i][j]),
                    .i_c_vld (elem_i_c_vld  [i][j]),
                    .i_c     (elem_i_c_data [i][j]),
                    .i_we    (i_we),

                    .o_a_vld (elem_o_a_vld  [i][j]),
                    .o_a     (elem_o_a_data [i][j]),
                    .o_c_vld (elem_o_c_vld  [i][j]),
                    .o_c     (elem_o_c_data [i][j]),
                    .o_we    ()
                );
            end
        end

    endgenerate

endmodule

