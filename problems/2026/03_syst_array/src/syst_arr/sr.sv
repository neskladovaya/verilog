// Shift register for systolic array.
module sr #(
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
    if (DEPTH == 0) begin : gen_PASSTROUGH
        assign o_data = i_data;
        assign o_vld = i_vld;
    end
    else if (DEPTH == 1) begin : gen_depth1
            always_ff @(posedge clk or negedge rst_n) begin
                o_data <= i_data;
                o_vld  <= i_vld;
            end
        end
    else begin : gen_SHIFTREG
        logic [DEPTH-1:0][WIDTH-1:0] data;
        logic [DEPTH-1:0]            vld ;

        always_ff @(posedge clk) begin
            data <= {i_data, data[DEPTH-1:1]};
            vld  <= {i_vld,  vld [DEPTH-1:1]};
        end

        assign o_data = data[0];
        assign o_vld  = vld [0];
    end
endgenerate

endmodule

