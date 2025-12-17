module sa_w_gen_addr
    import axi_pkg::*;
#(
    parameter WIDTH  = 16,
    parameter SIZE   = 4,
    parameter CREDIT = 8
)(
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic                    i_addr_gen_en,
    input  logic                    i_we,
    input  logic [AXI_ADDR_W - 1:0] base_addr_a,
    input  logic [AXI_ADDR_W - 1:0] base_addr_b,
    input  logic [AXI_ADDR_W - 1:0] base_addr_c,

    // WA
    output logic [AXI_ADDR_W - 1:0] m_axi_awaddr,
    output logic                    m_axi_awid,
    output logic [AXI_LEN_W  - 1:0] m_axi_awlen,
    output logic [AXI_SIZE_W - 1:0] m_axi_awsize,
    output logic [AXI_BRST_W - 1:0] m_axi_awburst,
    output logic [AXI_PROT_W - 1:0] m_axi_awprot,
    output logic                    m_axi_awvalid,
    input  logic                    m_axi_awready,

    // W
    output logic [AXI_DATA_W - 1:0] m_axi_wdata,
    output logic                    m_axi_wvalid,
    input  logic                    m_axi_wready,
    output logic                    m_axi_wlast,

    // B
    input  logic [AXI_RESP_W - 1:0] m_axi_bresp,
    input  logic                    m_axi_bid,
    input  logic                    m_axi_bvalid,
    output logic                    m_axi_bready,

    // AR
    output logic [AXI_ADDR_W - 1:0] m_axi_araddr,
    output logic                    m_axi_arid,
    output logic [AXI_LEN_W  - 1:0] m_axi_arlen,
    output logic [AXI_SIZE_W - 1:0] m_axi_arsize,
    output logic [AXI_BRST_W - 1:0] m_axi_arburst,
    output logic [AXI_PROT_W - 1:0] m_axi_arprot,
    output logic                    m_axi_arvalid,
    input  logic                    m_axi_arready,

    // R
    input  logic [AXI_DATA_W - 1:0] m_axi_rdata,
    input  logic                    m_axi_rid,
    input  logic [AXI_RESP_W - 1:0] m_axi_rresp,
    input  logic                    m_axi_rlast,
    input  logic                    m_axi_rvalid,
    output logic                    m_axi_rready

);

    gen_addr #(
        .WIDTH(WIDTH),
        .SIZE(SIZE)
    ) addr_gen_inst (
        .clk(clk),
        .rst_n(rst_n),

        .i_en(i_addr_gen_en),
        .i_we(i_we),
        .base_addr_a(base_addr_a),
        .base_addr_b(base_addr_b),
        .base_addr_c(base_addr_c),

        .awaddr (m_axi_awaddr),
        .awlen  (m_axi_awlen),
        .awsize (m_axi_awsize),
        .awburst(m_axi_awburst),
        .awvalid(m_axi_awvalid),
        .awready(m_axi_awready),

        .araddr (m_axi_araddr),
        .arlen  (m_axi_arlen),
        .arsize (m_axi_arsize),
        .arburst(m_axi_arburst),
        .arvalid(m_axi_arvalid),
        .arready(m_axi_arready)
    );

    sa_credited #(
        .WIDTH(WIDTH),
        .SIZE(SIZE),
        .CREDIT(CREDIT)
    ) sa_credited_inst (
        .clk    (clk),
        .rst_n  (rst_n),
        .i_we   (i_we),
        .i_vld  (m_axi_rvalid),
        .o_rdy  (m_axi_rready),
        .i_a    (m_axi_rdata ),
        .o_vld  (m_axi_wvalid),
        .i_rdy  (m_axi_wready),
        .o_c    (m_axi_wdata )
    );

    assign m_axi_bready = 1'b1;
    assign m_axi_wlast = (cnt == 2'(SIZE - 1));

    // Last counter
    logic [$clog2(SIZE)-1:0] cnt = 0;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 0;
        else begin
            if (m_axi_wvalid)
                cnt <= cnt + 1'b1;
        end
    end

endmodule

