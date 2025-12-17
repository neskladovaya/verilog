// Credit counter for data flow control.
module credit_cnt #(
    parameter int MAX_CRD = 8
)(
    input  logic clk,
    input  logic rst_n,

    input  logic i_inc,

    input  logic i_vld,
    output logic o_rdy
);

    localparam int CRD_W = $clog2(MAX_CRD + 1);
    logic [CRD_W-1:0] credit_cnt = MAX_CRD[CRD_W-1:0];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            credit_cnt <= MAX_CRD[CRD_W-1:0];
        end
        else begin
            unique case ({i_vld && o_rdy, i_inc})
                2'b10:
                    if (credit_cnt != 0)
                        credit_cnt <= credit_cnt - 1'b1;
                2'b01:
                    if (credit_cnt != MAX_CRD[CRD_W-1:0])
                        credit_cnt <= credit_cnt + 1;
                default: credit_cnt <= credit_cnt;
            endcase
        end
    end

    assign o_rdy = (credit_cnt > 0);

endmodule
