`ifndef SPI_DEFINE
`define SPI_DEFINE

`define CPOL 0 
`define CPHA 1 
`define DATA_WIDTH 8 
`define DIV_FRE 10 // 10 * Tclk_m = Tsclk_m

`define IDLE 0
`define START 1
`define EXE 2
`define FINISH 3

`define DIV_DATA_WIDTH 5
`define CRC_DATA_WIDTH 4

`endif