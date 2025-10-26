 module axis_fifo #(
    parameter int DATA_WIDTH = 16,
    parameter int DEPTH = 16
)(
    input  logic                    clk,
    input  logic                    rst_n,

    // AXI-Stream Slave Interface (input)
    input  logic [DATA_WIDTH-1:0]   s_axis_tdata,
    input  logic                    s_axis_tvalid,
    output logic                    s_axis_tready,
    input  logic                    s_axis_tlast,

    // AXI-Stream Master Interface (output)
    output logic [DATA_WIDTH-1:0]   m_axis_tdata,
    output logic                    m_axis_tvalid,
    input  logic                    m_axis_tready,
    output logic                    m_axis_tlast
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [DEPTH-1:0]      last_flags;  // store tlast per word

    logic [ADDR_WIDTH:0]   wr_addr, rd_addr;
    logic [ADDR_WIDTH:0]   count;

    logic fifo_full, fifo_empty;

    assign fifo_full  = (count == 5'(DEPTH));
    assign fifo_empty = (count == 0);

    // Write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_addr <= '0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            mem[wr_addr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
            last_flags[wr_addr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
            wr_addr <= wr_addr + 1;
        end
    end

    // Read
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_addr <= '0;
        end else if (m_axis_tvalid && m_axis_tready) begin
            rd_addr <= rd_addr + 1;
        end
    end

    // Count logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= '0;
        end else begin
            case ({s_axis_tvalid && s_axis_tready, m_axis_tvalid && m_axis_tready})
                2'b10: count <= count + 1;  // write only
                2'b01: count <= count - 1;  // read only
                default: count <= count;    // same number of ops
            endcase
        end
    end

    assign s_axis_tready = !fifo_full;

    assign m_axis_tvalid = !fifo_empty;
    assign m_axis_tdata  = mem[rd_addr[ADDR_WIDTH-1:0]];
    assign m_axis_tlast  = last_flags[rd_addr[ADDR_WIDTH-1:0]];

endmodule
