// Top module.
module sa_axi #(
    parameter WIDTH   = 16,
    parameter SIZE    = 4,
    parameter CREDITS = 8,
    parameter ADDR_W  = 32,
    parameter DATA_W  = SIZE * WIDTH
)(
    input  wire                         clk,
    input  wire                         rst_n,

    output wire                         o_irq,

    output wire [ADDR_W-1:0]    m_axi_araddr,
    output wire                 m_axi_arid,
    output wire [7:0]           m_axi_arlen,
    output wire [2:0]           m_axi_arsize,
    output wire [1:0]           m_axi_arburst,
    output wire [2:0]           m_axi_arprot,
    output wire                 m_axi_arvalid,
    input  wire                 m_axi_arready,

    input  wire [4*WIDTH-1:0]   m_axi_rdata,
    input  wire                 m_axi_rid,
    input  wire [1:0]           m_axi_rresp,
    input  wire                 m_axi_rlast,
    input  wire                 m_axi_rvalid,
    output wire                 m_axi_rready,

    output wire [4*WIDTH-1:0]   m_axi_awaddr,
    output wire                 m_axi_awid,
    output wire [7:0]           m_axi_awlen,
    output wire [2:0]           m_axi_awsize,
    output wire [1:0]           m_axi_awburst,
    output wire [2:0]           m_axi_awprot,
    output wire                 m_axi_awvalid,
    input  wire                 m_axi_awready,

    output wire [4*WIDTH-1:0]   m_axi_wdata,
    output wire                 m_axi_wvalid,
    input  wire                 m_axi_wready,
    output wire                 m_axi_wlast,

    input  wire [1:0]           m_axi_bresp,
    input  wire                 m_axi_bid,
    input  wire                 m_axi_bvalid,
    output wire                 m_axi_bready,

    input  wire [ADDR_W-1:0]    s_axil_awaddr,
    input  wire [2:0]           s_axil_awprot,
    input  wire                 s_axil_awvalid,
    output wire                 s_axil_awready,

    input  wire [ADDR_W-1:0]    s_axil_wdata,
    input  wire [ADDR_W/8-1:0]  s_axil_wstrb,
    input  wire                 s_axil_wvalid,
    output wire                 s_axil_wready,

    output wire [1:0]           s_axil_bresp,
    output wire                 s_axil_bvalid,
    input  wire                 s_axil_bready,

    input  wire [ADDR_W-1:0]    s_axil_araddr,
    input  wire [2:0]           s_axil_arprot,
    input  wire                 s_axil_arvalid,
    output wire                 s_axil_arready,

    output wire [ADDR_W-1:0]    s_axil_rdata,
    output wire [1:0]           s_axil_rresp,
    output wire                 s_axil_rvalid,
    input  wire                 s_axil_rready
);

    wire i_vld;
    wire i_rdy;
    wire o_vld;
    wire o_rdy;
    wire is_b;

    wire [DATA_W-1:0] i_ab;
    wire [DATA_W-1:0] o_c;

    wire start;
    wire is_b;
    wire [ADDR_W-1:0] ab_addr;
    wire [ADDR_W-1:0] c_addr;

    reg [$clog2(SIZE):0] count;

    assign m_axi_arid   = 1'b0;
    assign m_axi_arprot = 3'b000;
    assign m_axi_awid   = 1'b0;
    assign m_axi_awprot = 3'b000;

    csr #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W)
    ) sa_csr_inst (
        .clk            (clk),
        .rst_n          (rst_n),

        .s_axil_awaddr  (s_axil_awaddr),
        .s_axil_awprot  (s_axil_awprot),
        .s_axil_awvalid (s_axil_awvalid),
        .s_axil_awready (s_axil_awready),

        .s_axil_wdata   (s_axil_wdata),
        .s_axil_wstrb   (s_axil_wstrb),
        .s_axil_wvalid  (s_axil_wvalid),
        .s_axil_wready  (s_axil_wready),

        .s_axil_bresp   (s_axil_bresp),
        .s_axil_bvalid  (s_axil_bvalid),
        .s_axil_bready  (s_axil_bready),

        .o_start        (start),
        .o_is_b         (is_b),
        .o_addr_ab      (ab_addr),
        .o_addr_c       (c_addr)
    );

    gen_addr #(
        .WIDTH   (WIDTH),
        .SIZE    (SIZE),
        .ADDR_W  (ADDR_W)
    ) addr_gen_inst (
        .clk        (clk),
        .rst_n      (rst_n),

        .i_start    (start),
        .is_b       (is_b),

        .addr_ab (ab_addr),
        .addr_c  (c_addr),

        .o_done     (o_irq),

        .araddr     (m_axi_araddr),
        .arlen      (m_axi_arlen),
        .arsize     (m_axi_arsize),
        .arburst    (m_axi_arburst),
        .arvalid    (m_axi_arvalid),
        .arready    (m_axi_arready),

        .rvalid     (m_axi_rvalid),
        .rready     (m_axi_rready),
        .rlast      (m_axi_rlast),

        .awaddr     (m_axi_awaddr),
        .awlen      (m_axi_awlen),
        .awsize     (m_axi_awsize),
        .awburst    (m_axi_awburst),
        .awvalid    (m_axi_awvalid),
        .awready    (m_axi_awready),

        .bvalid     (m_axi_bvalid),
        .bready     (m_axi_bready)
    );

    // Data path connections.
    assign is_b      = is_b;

    assign i_ab      = m_axi_rdata;
    assign i_vld     = m_axi_rvalid;
    assign m_axi_rready = o_rdy;

    assign m_axi_wdata  = o_c;
    assign m_axi_wvalid = o_vld;
    assign i_rdy   = m_axi_wready;

    assign m_axi_wlast  = (count == (SIZE - 1)) && o_vld;
    assign m_axi_bready = 1'b1;

    // Counter for WLAST.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 'b0;
        end else if (o_vld && m_axi_wready) begin
            if (count == (SIZE - 1))
                count <= 'b0;
            else
                count <= count + 1'b1;
        end
    end

    sa_credited #(
        .WIDTH   (WIDTH),
        .SIZE    (SIZE),
        .CREDITS (CREDITS)
    ) sa_credited_inst (
        .clk   (clk),
        .rst_n (rst_n),

        .i_vld (i_vld),
        .is_b  (is_b),
        .i_ab  (i_ab),
        .i_rdy (i_rdy),

        .o_vld (o_vld),
        .o_c   (o_c),
        .o_rdy (o_rdy)
    );

endmodule

