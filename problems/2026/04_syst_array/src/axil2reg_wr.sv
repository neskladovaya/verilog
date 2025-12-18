// AXIL to GEN_ADDR interface.
module axil2reg_wr #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter STRB_WIDTH = DATA_WIDTH/8
)(
    input  logic clk,
    input  logic rst_n,

    // AW
    input  logic [ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  logic            [2:0]  s_axil_awprot,
    input  logic                   s_axil_awvalid,
    output logic                   s_axil_awready,
    // W
    input  logic [DATA_WIDTH-1:0]  s_axil_wdata,
    input  logic                   s_axil_wvalid,
    output logic                   s_axil_wready,
    // B
    output logic            [1:0]  s_axil_bresp,
    output logic                   s_axil_bvalid,
    input  logic                   s_axil_bready,

    output logic                     o_addr_en,
    output logic                     o_we,
    output logic  [ADDR_WIDTH - 1:0] o_addr_a,
    output logic  [ADDR_WIDTH - 1:0] o_addr_b,
    output logic  [ADDR_WIDTH - 1:0] o_addr_c
);

localparam AXI_OKAY   = 2'b00;
localparam AXI_SLVERR = 2'b10;

logic idle;
logic [DATA_WIDTH-1:0] data;
logic en_d;

assign s_axil_awready = idle && s_axil_wvalid;
assign s_axil_wready  = idle && s_axil_awvalid;

assign s_axil_bresp = (en_d) ? AXI_OKAY : AXI_SLVERR;
assign s_axil_bvalid = !idle;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        idle <= 1'b1;
        en_d <= 1'b0;
    end else begin
        idle <= idle ? !(s_axil_awvalid && s_axil_wvalid) : s_axil_bready;
        en_d <= idle && s_axil_awvalid && s_axil_wvalid;
    end
end

///////////////////////////////////// Address load part start.

typedef enum logic [1:0] {
    LOAD_A_ADDR,
    LOAD_B_ADDR,
    LOAD_C_ADDR
} state_t;

state_t state;

logic  tr;
assign tr = s_axil_awvalid && s_axil_wvalid; // Valid transaction.

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= LOAD_B_ADDR;
    end else begin
        if (!tr) begin
            o_addr_en <= 0;
        end else begin
            if (idle && tr) begin
                // B -> A -> C(res)
                unique case (state)
                    LOAD_A_ADDR: begin
                        o_addr_en <= 1;
                        o_we      <= 0;
                        o_addr_a  <= s_axil_wdata;

                        state <= LOAD_C_ADDR;
                    end
                    LOAD_B_ADDR: begin
                        o_addr_en <= 1;
                        o_we      <= 1;
                        o_addr_b  <= s_axil_wdata;

                        state <= LOAD_A_ADDR;
                    end
                    LOAD_C_ADDR: begin
                        o_addr_en <= 1;
                        o_we      <= 0;
                        o_addr_c  <= s_axil_wdata;

                        state <= LOAD_B_ADDR;
                    end
                endcase
            end
        end
    end
end

endmodule

