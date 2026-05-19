// Shift register for systolic array.
module sr #(
    parameter int WIDTH = 16,
    parameter int DEPTH = 1
) (
    input  logic clk,

    input  logic             i_vld,
    input  logic [WIDTH-1:0] i_data,

    output logic             o_vld,
    output logic [WIDTH-1:0] o_data
);

logic [WIDTH-1:0] data[DEPTH-1:0];
logic             vld [DEPTH-1:0];

always_ff @(posedge clk) begin
    vld [0] <= i_vld;
    data[0] <= i_data;

    for (int i = 1; i < DEPTH; i++) begin
        vld [i] <= vld [i-1];
        data[i] <= data[i-1];
    end
end

assign o_vld  = vld [DEPTH-1];
assign o_data = data[DEPTH-1];

endmodule

