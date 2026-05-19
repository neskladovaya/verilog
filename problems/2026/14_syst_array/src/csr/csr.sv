module csr #(
    parameter int ADDR_W = 32,
    parameter int DATA_W = 32
)(
    input  logic clk,
    input  logic rst_n,

    input  logic [ADDR_W-1:0]   s_axil_awaddr,
    input  logic [2:0]          s_axil_awprot,
    input  logic                s_axil_awvalid,
    output logic                s_axil_awready,

    input  logic [DATA_W-1:0]   s_axil_wdata,
    input  logic [DATA_W/8-1:0] s_axil_wstrb,
    input  logic                s_axil_wvalid,
    output logic                s_axil_wready,

    output logic [1:0]          s_axil_bresp,
    output logic                s_axil_bvalid,
    input  logic                s_axil_bready,

    output logic                o_start,
    output logic                o_is_b,
    output logic [ADDR_W-1:0]   o_addr_ab,
    output logic [ADDR_W-1:0]   o_addr_c
);

    // Address map.
    localparam logic [ADDR_W-1:0] REG_START = 32'h4000_0000;
    localparam logic [ADDR_W-1:0] REG_IS_B  = 32'h4000_0004;
    localparam logic [ADDR_W-1:0] REG_AB    = 32'h4000_0008;
    localparam logic [ADDR_W-1:0] REG_C     = 32'h4000_000C;

    logic start_q, start_d;
    logic is_b_q;
    logic [ADDR_W-1:0] addr_ab_q, addr_c_q;

    logic [ADDR_W-1:0] wr_addr;
    logic [DATA_W-1:0] wr_data;
    logic              wr_en;
    logic              wr_ok;

    axil2reg_wr #(
        .ADDR_WIDTH(ADDR_W),
        .DATA_WIDTH(DATA_W)
    ) u_axil (
        .clk(clk),
        .rst_n(rst_n),

        .s_axil_awaddr (s_axil_awaddr),
        .s_axil_awprot (s_axil_awprot),
        .s_axil_awvalid(s_axil_awvalid),
        .s_axil_awready(s_axil_awready),

        .s_axil_wdata  (s_axil_wdata),
        .s_axil_wstrb  (s_axil_wstrb),
        .s_axil_wvalid (s_axil_wvalid),
        .s_axil_wready (s_axil_wready),

        .s_axil_bresp  (s_axil_bresp),
        .s_axil_bvalid (s_axil_bvalid),
        .s_axil_bready (s_axil_bready),

        .reg_wr_addr (wr_addr),
        .reg_wr_data (wr_data),
        .reg_wr_strb (),
        .reg_wr_en   (wr_en),
        .reg_wr_okay (wr_ok)
    );

    always_comb begin
        start_d   = 1'b0;
        wr_ok = 1'b0;

        if (wr_en) begin
            unique case (wr_addr)
                REG_START: begin
                    start_d = wr_data[0];
                    wr_ok   = 1'b1;
                end

                REG_IS_B: begin
                    wr_ok = 1'b1;
                end

                REG_AB: begin
                    wr_ok = 1'b1;
                end

                REG_C: begin
                    wr_ok = 1'b1;
                end

                default: begin
                    wr_ok = 1'b0;
                end
            endcase
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_q   <= 1'b0;
            is_b_q    <= 1'b0;
            addr_ab_q <= '0;
            addr_c_q  <= '0;
        end
        else begin
            start_q <= start_d;

            if (wr_en) begin
                unique case (wr_addr)
                    REG_IS_B: is_b_q    <= wr_data[0];
                    REG_AB:   addr_ab_q <= wr_data;
                    REG_C:    addr_c_q  <= wr_data;
                    default: ;
                endcase
            end
        end
    end

    assign o_start   = start_q;
    assign o_is_b    = is_b_q;
    assign o_addr_ab = addr_ab_q;
    assign o_addr_c  = addr_c_q;

endmodule

