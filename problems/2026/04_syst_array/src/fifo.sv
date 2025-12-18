// FIFO module for data flow control.
module fifo #(
    parameter int DATA_WIDTH = 32,
    parameter int DEPTH = 8
)(
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic [DATA_WIDTH-1:0]   i_data,
    input  logic                    i_vld,
    output logic                    o_rdy,

    output logic [DATA_WIDTH-1:0]   o_data,
    output logic                    o_vld,
    input  logic                    i_rdy
);

    localparam DEPTH_W = $clog2(DEPTH + 1);
    localparam ADDR_WIDTH = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    logic [ADDR_WIDTH:0]   wr_addr, rd_addr;
    logic [ADDR_WIDTH:0]   count;

    logic fifo_full, fifo_empty;

    assign fifo_full  = (count == DEPTH[DEPTH_W-1:0]);
    assign fifo_empty = (count == 0);

    // Write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_addr <= '0;
        end else if (i_vld && o_rdy) begin
            mem[wr_addr[ADDR_WIDTH-1:0]] <= i_data;
            wr_addr <= wr_addr + 1;
        end
    end

    // Read
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_addr <= '0;
        end else if (o_vld && i_rdy) begin
            rd_addr <= rd_addr + 1;
        end
    end

    // Count logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= '0;
        end else begin
            case ({i_vld && o_rdy, o_vld && i_rdy})
                2'b10: count <= count + 1;
                2'b01: count <= count - 1;
                default: count <= count;
            endcase
        end
    end

    assign o_rdy = !fifo_full;
    assign o_vld = !fifo_empty;
    assign o_data  = mem[rd_addr[ADDR_WIDTH-1:0]];

endmodule

