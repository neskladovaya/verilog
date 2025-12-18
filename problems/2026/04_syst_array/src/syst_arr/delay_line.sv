// Delay line for WE signal.
module delay_line #(
    parameter int SIZE = 4
)(
    input logic clk,
    input logic rst_n,

    input  logic            i_we,
    output logic [SIZE-1:0] o_we
);

    logic [SIZE-1:0] we_sr;
    logic [SIZE-1:0] we_rotr = 1'b1 << (SIZE-1);

    always_ff @(posedge clk) begin
        if (i_we) begin
            we_rotr <= {we_rotr[0], we_rotr[SIZE-1:1]};
        end
    end
    assign we_sr = i_we ? we_rotr : '0;

    genvar i;
    generate
        for (i = 0; i < SIZE; i++) begin : gen_SHIFTREG_WE
            sr #(
                .DEPTH(i),
                .WIDTH(1)
            ) we_sr_inst (
                .clk   (clk),
                .rst_n (rst_n),
                .i_vld (we_sr[i]),
                .i_data(),
                .o_vld (o_we[i]),
                .o_data()
            );
        end
    endgenerate

endmodule

