// AXI4 address generator block.
module gen_addr
    import axi_pkg::*;
#(
    parameter WIDTH = 16,
    parameter SIZE = 4
)(
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic                    i_en,
    input  logic                    i_we,
    input  logic [AXI_ADDR_W - 1:0] base_addr_a,
    input  logic [AXI_ADDR_W - 1:0] base_addr_b,
    input  logic [AXI_ADDR_W - 1:0] base_addr_c,

    // Ar
    output logic [AXI_ADDR_W - 1:0] araddr,
    output logic [AXI_LEN_W  - 1:0] arlen,
    output logic [AXI_SIZE_W - 1:0] arsize,
    output logic [AXI_BRST_W - 1:0] arburst,
    output logic                    arvalid,
    input  logic                    arready,

    // AW
    output logic [AXI_ADDR_W - 1:0] awaddr,
    output logic [AXI_LEN_W  - 1:0] awlen,
    output logic [AXI_SIZE_W - 1:0] awsize,
    output logic [AXI_BRST_W - 1:0] awburst,
    output logic                    awvalid,
    input  logic                    awready
);

assign arvalid = (state == READ) && i_en;
assign araddr  = i_we ? base_addr_b : base_addr_a;
assign arlen   = SIZE-1;
assign arsize  = $clog2(AXI_DATA_W/8)[$size(arsize)-1:0];
assign arburst = 2'b01;

assign awvalid = i_en & (state == READ) & !i_we;
assign awaddr  = base_addr_c;
assign awlen   = SIZE-1;
assign awsize  = $clog2(AXI_DATA_W/8)[$size(awsize)-1:0];
assign awburst = 2'b01;

typedef enum logic [2:0] {
        READ,
        WRITE
} state_t;

state_t state;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= READ;
    end else begin
        unique case (state)
            READ: begin
                if (arvalid && arready) begin
                    state <= WRITE;
                end
            end
            WRITE: begin
                state <= READ;
            end
        endcase
    end
end

endmodule

