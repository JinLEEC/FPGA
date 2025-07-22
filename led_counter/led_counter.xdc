## Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clock }]; #IO_L12P_T1_MRCC_35 Sch=gclk[100]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clock }];

## Misc. ChipKit Ports
set_property -dict { PACKAGE_PIN C2    IOSTANDARD LVCMOS33 } [get_ports { n_reset }]; #IO_L16P_T2_35 Sch=ck_rst

## LEDs
set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33 } [get_ports { led[0] }]; #IO_L24N_T3_35 Sch=led[4]
set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33 } [get_ports { led[1] }]; #IO_25_35 Sch=led[5]
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { led[2] }]; #IO_L24P_T3_A01_D17_14 Sch=led[6]
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { led[3] }]; #IO_L24N_T3_A00_D16_14 Sch=led[7]

set_operating_conditions -ambient_temp 80.0

set_property CONFIG_MODE SPIx1 [current_design]

set_property CFGBVS VCCO [current_design]

set_property CONFIG_VOLTAGE 3.3 [current_design]

set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]

set_property BITSTREAM.CONFIG.PERSIST NO [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE NO [current_design]

set_property BITSTREAM.CONFIG.CONFIGRATE 22 [current_design]
