# Сreate project
create_project fpga ./fpga -part xc7z020clg400-2

# Set target language
set_property target_language Verilog [current_project]

# Add HDL sources
# Add HDL sources
add_files -fileset sources_1 -norecurse {
  ./src/gen_addr/gen_addr.sv
  ./src/csr/axil2reg_wr.sv
  ./src/csr/csr.sv
  ./src/credit/credit_cnt.sv
  ./src/credit/fifo.sv
  ./src/credit/rf_1r1w.sv
  ./src/sa/pe.sv
  ./src/sa/sr.sv
  ./src/sa/sa_core.sv
  ./src/sa/sa_top.sv
  ./src/sa_credited.sv
  ./src/sa_axi.v
}

# Update compile order
update_compile_order -fileset sources_1

create_bd_design "design_1" -dir fpga

create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

set_property -dict [list \
  CONFIG.PCW_EN_CLK0_PORT {1} \
  CONFIG.PCW_EN_RST0_PORT {1} \
  CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
  CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} \
  CONFIG.PCW_SD0_SD0_IO {MIO 40 .. 45} \
  CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} \
  CONFIG.PCW_UART1_UART1_IO {MIO 48 .. 49} \
  CONFIG.PCW_UIPARAM_DDR_BUS_WIDTH {16 Bit} \
  CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41J256M16 RE-125} \
  CONFIG.PCW_USE_M_AXI_GP0 {1} \
  CONFIG.PCW_IRQ_F2P_INTR {1} \
  CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
  CONFIG.PCW_USE_S_AXI_HP0 {1} \
] [get_bd_cells processing_system7_0]

apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]

create_bd_cell -type module -reference sa_axi sa_axi_0

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:2.1 axi_protocol_convert_0
set_property -dict [list \
  CONFIG.MI_PROTOCOL {AXI4LITE} \
  CONFIG.SI_PROTOCOL {AXI3} \
  CONFIG.TRANSLATION_MODE {2} \
] [get_bd_cells axi_protocol_convert_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0
set_property CONFIG.NUM_SI {1} [get_bd_cells smartconnect_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0

connect_bd_net [get_bd_pins smartconnect_0/aclk]                      [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins axi_protocol_convert_0/aclk]              [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins sa_axi_0/clk]                             [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0]           [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0]           [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0]           [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
connect_bd_net [get_bd_pins proc_sys_reset_0/ext_reset_in]            [get_bd_pins processing_system7_0/FCLK_RESET0_N]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn]      [get_bd_pins sa_axi_0/rst_n]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn]      [get_bd_pins smartconnect_0/aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn]      [get_bd_pins axi_protocol_convert_0/aresetn]
connect_bd_net [get_bd_pins sa_axi_0/o_irq]                           [get_bd_pins processing_system7_0/IRQ_F2P]
connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M00_AXI]         [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
connect_bd_intf_net [get_bd_intf_pins sa_axi_0/m_axi]                 [get_bd_intf_pins smartconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins axi_protocol_convert_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_protocol_convert_0/M_AXI]   [get_bd_intf_pins sa_axi_0/S_AXIL]

regenerate_bd_layout -routing

assign_bd_address

validate_bd_design

save_bd_design

make_wrapper -files [get_files fpga/design_1/design_1.bd] -top
add_files -norecurse fpga/design_1/hdl/design_1_wrapper.v

update_compile_order -fileset sources_1
set_property top design_1_wrapper [current_fileset]

