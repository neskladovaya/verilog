// FIFO module for data flow control.
module fifo #(
    parameter ADDRW = 4,
    parameter DATAW = 8
)(
    input  logic clk,

    input  logic                 i_rd_en,
    output logic [DATAW-1:0]     o_rd_data,

    input  logic                 i_wr_en,
    input  logic [DATAW-1:0]     i_wr_data,

    output logic                 o_full,
    output logic                 o_empty
);

    // Pointers (extra bit for full/empty detection)
    logic [ADDRW:0] rd_ptr = {{ADDRW{1'b0}}, 1'b0};
    logic [ADDRW:0] wr_ptr = {{ADDRW{1'b0}}, 1'b0};

    // Register file (1 read / 1 write)
    rf_1r1w #(
        .ADDRW(ADDRW),
        .DATAW(DATAW)
    ) u_rf_1r1w (
        .clk       (clk),

        .i_rd_addr (rd_ptr[ADDRW-1:0]),
        .o_rd_data (o_rd_data),

        .i_wr_addr (wr_ptr[ADDRW-1:0]),
        .i_wr_data (i_wr_data),
        .i_wr_en   (i_wr_en)
    );

    // Status flags
    assign o_full  = (rd_ptr[ADDRW-1:0] == wr_ptr[ADDRW-1:0]) &&
                     (rd_ptr[ADDRW]     != wr_ptr[ADDRW]);

    assign o_empty = (rd_ptr[ADDRW-1:0] == wr_ptr[ADDRW-1:0]) &&
                     (rd_ptr[ADDRW]     == wr_ptr[ADDRW]);

    // Pointer updates
    always_ff @(posedge clk) begin
        if (i_rd_en) begin
            rd_ptr <= rd_ptr + 1;
        end

        if (i_wr_en) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

endmodule

