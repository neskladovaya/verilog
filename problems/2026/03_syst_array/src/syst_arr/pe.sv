// Processing element for systolic array.
module pe #(
    parameter int WIDTH = 32
)(
    input logic clk,
    input logic rst_n,

    input  logic             i_a_vld,
    input  logic [WIDTH-1:0] i_a,
    input  logic             i_we,

    input  logic             i_c_vld,
    input  logic [WIDTH-1:0] i_c,

    output logic             o_a_vld,
    output logic [WIDTH-1:0] o_a,
    output logic             o_c_vld,
    output logic [WIDTH-1:0] o_c,
    output logic             o_we
);

    logic [WIDTH-1:0] a;
    logic [WIDTH-1:0] b;
    logic [WIDTH-1:0] c;
    logic             a_vld;
    logic             c_vld;

    // Data Flow.
    always_ff @(posedge clk or negedge rst_n) begin
        a <= i_a;
        if (i_c_vld & i_a_vld) begin
            c <= i_a * b + i_c;
        end
    end

    // Control flow.
    always_ff @(posedge clk or negedge rst_n) begin
        a_vld <= i_a_vld;
        c_vld <= i_a_vld && i_c_vld;
        o_we  <= i_we;
    end

    // Write enable.
    always_ff @(posedge clk or negedge rst_n) begin
        if (i_we) begin
            b <= i_a;
        end
    end

    // Assign outputs.
    assign o_a_vld = a_vld;
    assign o_a     = a;
    assign o_c_vld = c_vld;
    assign o_c     = c;

endmodule

