`ifndef LOOPBACK
`define LOOPBACK
`include "../rtl/master.v"
`include "../rtl/slave.v"

module loopback(
input wire clk_m,
input wire clk_s,
input wire rst_n,
input wire [DATA_WIDTH - 1:0] data_in_master,
input wire [DATA_WIDTH - 1:0] data_in_slave,
input wire start,
output wire finish, // signal to master
output wire [DATA_WIDTH - 1:0] data_out_master, // data from slave, could give to master
output wire [DATA_WIDTH - 1:0] data_out_slave // data from master, could give to slave
);

parameter DATA_WIDTH = 8;

wire sclk;
wire miso;
wire mosi;
wire ss;

master_spi m0(
    .clk_m(clk_m),
    .rst_n(rst_n),
    .data_in_master(data_in_master),
    .start(start),
    .miso(miso),
    .sclk_m(sclk),
    .mosi(mosi),
    .finish(finish),
    .ss(ss),
    .data_out_master(data_out_master)
);

slave_spi s0(
    .clk_s(clk_s),
    .sclk_s(sclk),
    .ss(ss),
    .rst_n(rst_n),
    .mosi(mosi),
    .data_in_slave(data_in_slave),
    .miso(miso),
    .data_out_slave(data_out_slave)
);

endmodule

`endif