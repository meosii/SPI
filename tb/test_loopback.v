`include "../rtl/loopback.v"
`timescale 1ps/1ps
module test_loopback();
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

loopback l0(
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
    #10 begin
        data_in_master = 8'b10110100;
        data_in_slave = 8'b01010101;
        start = 1;
    end
    #10 begin
        start = 0;
        data_in_master = 8'b0;
        data_in_slave = 8'b0;
    end
    #350 begin
        start = 1;
        data_in_master = data_out_master;
        data_in_slave = data_out_slave;
    end
    #10 begin
        start = 0;
        data_in_master = 0;
        data_in_slave = 0;
    end
    #400
    $finish;
end

initial begin
    $dumpfile("wave_loopback.vcd");
    $dumpvars(0,test_loopback);
end

endmodule