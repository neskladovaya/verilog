module rf_1r1w#(
    parameter ADDRW = 4,
    parameter DATAW = 8
)
(
    input  logic               clk,

    input  logic [ADDRW - 1:0] i_rd_addr,
    output logic [DATAW - 1:0] o_rd_data,

    input  logic [ADDRW - 1:0] i_wr_addr,
    input  logic [DATAW - 1:0] i_wr_data,
    input  logic               i_wr_en
);

logic [DATAW - 1:0] r[2 ** ADDRW - 1:0]; // Unpacked array

assign o_rd_data = r[i_rd_addr];

always_ff @(posedge clk) begin
    if ( i_wr_en ) begin
        r[i_wr_addr] <= i_wr_data;
    end
end

endmodule