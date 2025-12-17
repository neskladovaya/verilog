module sa_axi
    import axi_pkg::*;
#(
    parameter WIDTH  = 16,
    parameter SIZE   = 4,
    parameter CREDIT = 8
)(
    input  logic                    clk,
    input  logic                    rst_n,

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
    output logic                    m_axi_rready,

    // AW lite
    input  logic [31:0] s_axil_awaddr,
    input  logic [2:0]  s_axil_awprot,
    input  logic        s_axil_awvalid,
    output logic        s_axil_awready,

    // W lite
    input  logic [31:0] s_axil_wdata,
    input  logic [3:0]  s_axil_wstrb,
    input  logic        s_axil_wvalid,
    output logic        s_axil_wready,

    // B lite
    output logic [1:0]  s_axil_bresp,
    output logic        s_axil_bvalid,
    input  logic        s_axil_bready,

    // AR lite
    input  logic [31:0] s_axil_araddr,
    input  logic [2:0]  s_axil_arprot,
    input  logic        s_axil_arvalid,
    output logic        s_axil_arready,

    // R lite
    output logic [31:0] s_axil_rdata,
    output logic [1:0]  s_axil_rresp,
    output logic        s_axil_rvalid,
    input  logic        s_axil_rready
);

    logic addr_en;
    logic we;
    logic [AXI_ADDR_W - 1:0] a_addr;
    logic [AXI_ADDR_W - 1:0] b_addr;
    logic [AXI_ADDR_W - 1:0] c_addr;

    axil2reg_wr #(.ADDR_WIDTH(32),
                  .DATA_WIDTH(32)
    ) axil_intf_inst (
        .clk(clk),
        .rst_n(rst_n),

        .s_axil_awaddr (s_axil_awaddr),
        .s_axil_awprot (s_axil_awprot),
        .s_axil_awvalid(s_axil_awvalid),
        .s_axil_awready(s_axil_awready),

        .s_axil_wdata  (s_axil_wdata),
        .s_axil_wvalid (s_axil_wvalid),
        .s_axil_wready (s_axil_wready),

        .s_axil_bresp  (s_axil_bresp),
        .s_axil_bvalid (s_axil_bvalid),
        .s_axil_bready (s_axil_bready),

        .o_addr_en     (addr_en),
        .o_we          (we),
        .o_addr_a      (a_addr),
        .o_addr_b      (b_addr),
        .o_addr_c      (c_addr)
    );

    gen_addr #(
        .WIDTH(WIDTH),
        .SIZE(SIZE)
    ) addr_gen_inst (
        .clk(clk),
        .rst_n(rst_n),

        .i_en       (addr_en),
        .i_we       (we),
        .base_addr_a(a_addr),
        .base_addr_b(b_addr),
        .base_addr_c(c_addr),

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
        .i_we   (we),
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
            if (m_axi_wvalid && m_axi_wready)
                cnt <= cnt + 1'b1;
        end
    end

endmodule

