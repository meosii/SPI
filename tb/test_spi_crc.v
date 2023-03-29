`timescale 1ps/1ps

`include "../rtl/spi_crc.v"

module test_spi_crc();
reg clk_m;
reg clk_s;
reg rst_n;
reg [DATA_WIDTH - 1:0] data_in_master;
reg [DATA_WIDTH - 1:0] data_in_slave;
reg start;
wire finish;
wire [DATA_WIDTH - 1:0] data_out_master;
wire [DATA_WIDTH - 1:0] data_out_slave;

parameter DATA_WIDTH = 8;

spi_crc l0(
    .clk_m(clk_m),
    .clk_s(clk_s),
    .rst_n(rst_n),
    .data_in_master(data_in_master),
    .data_in_slave(data_in_slave),
    .start(start),
    .finish(finish),
    .data_out_master(data_out_master),
    .data_out_slave(data_out_slave)
);

always #2 clk_m = ~clk_m;
always #2 clk_s = ~clk_s;

initial begin
    #0 begin
        clk_m = 1;
        clk_s = 1;
        rst_n = 0;
        data_in_master = 8'b0;
        data_in_slave = 8'b0;
        start = 0;
    end
    #10 begin
        rst_n = 1;
        data_in_master = 8'b0;
        data_in_slave = 8'b0;
        start = 0;
    end
    #5 begin
        data_in_master = 8'b11010111;
        start = 1;
    end
    #2 begin
        data_in_slave = 8'b11110101;
    end
    #2 begin
        start = 0;
        data_in_master = 8'b0;
    end
    #2 begin
        data_in_slave = 8'b0; // 要检测 ss_neg，相比 data_in_master 要迟一个周期才给 miso
    end
    #520 begin
        start = 1;
        data_in_master = data_out_master;
        data_in_slave = data_out_slave;
    end
    #10 begin
        start = 0;
        data_in_master = 0;
        data_in_slave = 0;
    end
    #550
    $finish;
end

initial begin
    $dumpfile("wave_spi_crc.vcd");
    $dumpvars(0,test_spi_crc);
end

endmodule