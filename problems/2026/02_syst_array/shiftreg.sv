// Shift register for systolic array.
module shiftreg #(
    parameter int DEPTH = 1,
    parameter int WIDTH = 32
)(
    input  logic             clk,
    input  logic             rst_n,

    input  logic             i_vld,
    input  logic [WIDTH-1:0] i_data,

    output logic             o_vld,
    output logic [WIDTH-1:0] o_data
);

generate
    if (DEPTH == 0) begin : g_PASSTROUGH
        assign o_data = i_data;
        assign o_vld = i_vld;
    end
    else if (DEPTH == 1) begin
        logic filled;
        logic [WIDTH-1:0] r;

        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                r <= '0;
            end
            else begin
                if (i_vld) begin
                    r <= i_data;
                    filled <= 1'b1;
                end
                if (filled) begin
                    o_vld <= 1;
                    o_data <= r;
                end
            end
        end
    end
    else begin
        logic [$clog2(DEPTH):0] cnt;  // Count to determine when the output of the shiftreg output becomes valid.
        logic [WIDTH-1:0] r [DEPTH];

        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                r <= '0;
            end
            else begin
                if (i_vld) begin
                    r <= {i_data, r[0:DEPTH-2]};
                    cnt <= cnt + 1;
                end
                if (cnt == DEPTH) begin
                    o_vld <= 1;
                end
            end
        end

        always_ff @(posedge clk or negedge rst_n) begin
            if (o_vld) begin
                o_data <= r[DEPTH-1];
                cnt <= cnt - 1;
            end
        end
    end
endgenerate

endmodule

