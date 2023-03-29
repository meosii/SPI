`include"../rtl/slave.v"

module test_slave();
reg clk_s;
reg sclk_s;
reg ss;
reg rst_n;
reg mosi;
reg [DATA_WIDTH - 1:0] data_in_slave;
wire miso;
wire [DATA_WIDTH - 1:0] data_out_slave;

parameter DATA_WIDTH = 8;

slave_spi slave_spi_0(
    .clk_s(clk_s),
    .sclk_s(sclk_s),
    .ss(ss),
    .rst_n(rst_n),
    .mosi(mosi),
    .data_in_slave(data_in_slave),
    .miso(miso),
    .data_out_slave(data_out_slave)
);

always #5 clk_s = ~clk_s;
always #20 sclk_s = ~sclk_s;

initial begin
    #0 begin
        clk_s = 1;
        sclk_s = 1;
        ss = 1;
        rst_n = 0;
        mosi = 0;
        data_in_slave = 0;
    end
    #5 begin
        rst_n = 1;
    end
    #10 begin
        ss = 0;
    end
    #10 begin
        ss = 1;
        mosi = 1;
        data_in_slave = 8'b10110010;
    end
    #40 begin
        mosi = 0;
        data_in_slave = 0;
    end
    #40 begin
        mosi = 1;
    end
    #40 begin
        mosi = 0;
    end
    #40 begin
        mosi = 1;
    end
    #40 begin
        mosi = 0;
    end
    #40 begin
        mosi = 1;
    end
    #40 begin
        mosi = 0;
    end
    #40 begin
        mosi = 1;
    end
    #40 begin
        mosi = 0;
    end
    #40 begin
        mosi = 1;
    end
    #40 begin
        mosi = 0;
    end
    #40 begin
        mosi = 1;
    end
    #40 begin
        mosi = 0;
    end
    #40 begin
        mosi = 1;
    end
    $finish;
end

initial begin
    $dumpfile("slave.vcd");
    $dumpvars(0,test_slave);
end

endmodule