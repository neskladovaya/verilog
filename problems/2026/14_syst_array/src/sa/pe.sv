 module pe #(
    parameter int WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,

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

    // ---------------- Data path ----------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            a <= '0;
            c <= '0;
        end else begin
            a <= i_a;

            if (i_c_vld && i_a_vld) begin
                c <= i_a * b + i_c;
            end
        end
    end

    // ---------------- Control ----------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            a_vld <= 1'b0;
            c_vld <= 1'b0;
            o_we  <= 1'b0;
        end else begin
            a_vld <= i_a_vld;
            c_vld <= i_a_vld && i_c_vld;
            o_we  <= i_we;
        end
    end

    // ---------------- B register ----------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            b <= '0;
        end else if (i_we) begin
            b <= i_a;
        end
    end

    // ---------------- Outputs ----------------
    assign o_a_vld = a_vld;
    assign o_a     = a;
    assign o_c_vld = c_vld;
    assign o_c     = c;

endmodule
