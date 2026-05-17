module axil2reg #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter STRB_WIDTH = DATA_WIDTH/8
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // AR
    input  wire [ADDR_WIDTH-1:0]    s_axil_araddr,
    input  wire [2:0]               s_axil_arprot,
    input  wire                     s_axil_arvalid,
    output wire                     s_axil_arready,

    // R
    output wire [DATA_WIDTH-1:0]    s_axil_rdata,
    output wire [1:0]               s_axil_rresp,
    output wire                     s_axil_rvalid,
    input  wire                     s_axil_rready,

    // AW
    input  wire [ADDR_WIDTH-1:0]    s_axil_awaddr,
    input  wire [2:0]               s_axil_awprot,
    input  wire                     s_axil_awvalid,
    output wire                     s_axil_awready,

    // W
    input  wire [DATA_WIDTH-1:0]    s_axil_wdata,
    input  wire [STRB_WIDTH-1:0]    s_axil_wstrb,
    input  wire                     s_axil_wvalid,
    output wire                     s_axil_wready,

    // B
    output wire [1:0]               s_axil_bresp,
    output wire                     s_axil_bvalid,
    input  wire                     s_axil_bready,

    output wire [ADDR_WIDTH-1:0]    reg_rd_addr,
    output wire                     reg_rd_en,
    input  wire [DATA_WIDTH-1:0]    reg_rd_data,
    input  wire                     reg_rd_okay,

    output wire [ADDR_WIDTH-1:0]    reg_wr_addr,
    output wire [DATA_WIDTH-1:0]    reg_wr_data,
    output wire [STRB_WIDTH-1:0]    reg_wr_strb,
    output wire                     reg_wr_en,
    input  wire                     reg_wr_okay
);

// READ
reg rd_idle;
reg rd_en;
reg [DATA_WIDTH-1:0] rd_data;
reg rd_okay;

assign s_axil_arready = rd_idle;
assign s_axil_rvalid  = ~rd_idle;
assign s_axil_rdata   = rd_data;
assign s_axil_rresp   = rd_okay ? 2'b00 : 2'b10;

assign reg_rd_addr = s_axil_araddr;
assign reg_rd_en   = rd_idle && s_axil_arvalid;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_idle <= 1'b1;
        rd_en   <= 1'b0;
    end else begin
        rd_en <= reg_rd_en;

        if (rd_idle)
            rd_idle <= ~s_axil_arvalid;
        else
            rd_idle <= s_axil_rready;
    end
end

always @(posedge clk) begin
    if (rd_en) begin
        rd_data <= reg_rd_data;
        rd_okay <= reg_rd_okay;
    end
end

// WRITE
reg wr_idle;
reg wr_en;
reg wr_okay;

assign s_axil_awready = wr_idle && s_axil_wvalid;
assign s_axil_wready  = wr_idle && s_axil_awvalid;

assign s_axil_bvalid = ~wr_idle;
assign s_axil_bresp  = wr_okay ? 2'b00 : 2'b10;

assign reg_wr_addr = s_axil_awaddr;
assign reg_wr_data = s_axil_wdata;
assign reg_wr_strb = s_axil_wstrb;
assign reg_wr_en   = wr_idle && s_axil_awvalid && s_axil_wvalid;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_idle <= 1'b1;
        wr_en   <= 1'b0;
    end else begin
        wr_en <= reg_wr_en;

        if (wr_idle)
            wr_idle <= ~(s_axil_awvalid && s_axil_wvalid);
        else
            wr_idle <= s_axil_bready;
    end
end

always @(posedge clk) begin
    if (wr_en) begin
        wr_okay <= reg_wr_okay;
    end
end

endmodule

