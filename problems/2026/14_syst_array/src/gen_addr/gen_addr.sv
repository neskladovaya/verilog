// Address generation module (refactored)
module gen_addr #(
    parameter WIDTH  = 16,
    parameter SIZE   = 4,
    parameter ADDR_W = 32
)(
    input  logic                clk,
    input  logic                rst_n,

    input  logic                i_start,
    input  logic                is_b,
    input  logic [ADDR_W-1:0]   addr_ab,
    input  logic [ADDR_W-1:0]   addr_c,

    output logic                o_done,

    output logic [ADDR_W-1:0]   araddr,
    output logic [7:0]          arlen,
    output logic [2:0]          arsize,
    output logic [1:0]          arburst,
    output logic                arvalid,
    input  logic                arready,

    input  logic                rvalid,
    input  logic                rready,
    input  logic                rlast,

    output logic [ADDR_W-1:0]   awaddr,
    output logic [7:0]          awlen,
    output logic [2:0]          awsize,
    output logic [1:0]          awburst,
    output logic                awvalid,
    input  logic                awready,

    input  logic                bvalid,
    input  logic                bready
);

    // Parameters
    localparam AXI_DATA_WIDTH = WIDTH * SIZE;
    localparam BURST_LEN      = SIZE;

    // FSM
    typedef enum logic [1:0] {
        ST_IDLE,
        ST_ACTIVE,
        ST_DONE
    } state_t;

    state_t state, state_next;

    // Constant assignments
    assign arsize  = $clog2(AXI_DATA_WIDTH / 8);
    assign awsize  = $clog2(AXI_DATA_WIDTH / 8);

    assign arburst = 2'b01; // INCR
    assign awburst = 2'b01;

    assign arlen   = BURST_LEN - 1;
    assign awlen   = BURST_LEN - 1;

    assign araddr  = addr_ab;
    assign awaddr  = addr_c;

    // Handshake helpers
    wire ar_fire = arvalid & arready;
    wire aw_fire = awvalid & awready;

    wire read_done  = rvalid & rready & rlast;
    wire write_done = bvalid & bready;

    wire op_done = is_b ? read_done : write_done;

    // Next-state logic
    always_comb begin
        state_next = state;

        unique case (state)
            ST_IDLE: begin
                if (i_start)
                    state_next = ST_ACTIVE;
            end

            ST_ACTIVE: begin
                if (op_done)
                    state_next = ST_DONE;
            end

            ST_DONE: begin
                state_next = ST_IDLE;
            end
        endcase
    end

    // Sequential logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= ST_IDLE;
            arvalid <= 1'b0;
            awvalid <= 1'b0;
            o_done  <= 1'b0;
        end else begin
            state <= state_next;

            if (state != ST_DONE)
                o_done <= 1'b0;

            unique case (state)
                ST_IDLE: begin
                    if (i_start) begin
                        arvalid <= 1'b1;
                        awvalid <= ~is_b;
                    end
                end

                ST_ACTIVE: begin
                    if (ar_fire)
                        arvalid <= 1'b0;

                    if (aw_fire)
                        awvalid <= 1'b0;
                end

                ST_DONE: begin
                    o_done <= 1'b1;
                end
            endcase
        end
    end

endmodule

