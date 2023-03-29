`include "../rtl/master.v"

module test_master();
reg clk_m;
reg rst_n;
reg [DATA_WIDTH - 1:0] data_in_master;
reg start;
reg miso;
wire sclk_m;
wire mosi;
wire finish;
wire ss;
wire [DATA_WIDTH - 1:0] data_out_master;

parameter DATA_WIDTH = 8;

master_spi master_spi_1(
    .clk_m(clk_m),
    .rst_n(rst_n),
    .data_in_master(data_in_master),
    .start(start),
    .miso(miso),
    .sclk_m(sclk_m),
    .mosi(mosi),
    .finish(finish),
    .ss(ss),
    .data_out_master(data_out_master)
);

always #10 clk_m = ~clk_m;

initial begin
    #0 begin
        clk_m = 0;
        rst_n = 0;
        data_in_master = 0;
        start = 0;
        miso = 0;
    end
    #4 begin
        rst_n = 1;
    end
    #3 begin
        data_in_master = 8'b10110101;
        start = 1;
    end
    #40 begin
        data_in_master = 0;
        start = 0;
        miso = 1;
    end
    #40
    #40 begin
        miso = 0;
    end
    #40 begin
        miso = 1;
    end
    #40 begin
        miso = 0;
    end
    #40 begin
        miso = 1;
    end
    #40 begin
        miso = 0;
    end
    #40 begin
        miso = 1;
    end
    #40 begin
        miso = 0;
    end
    #40 begin
        miso = 1;
    end
    #40 begin
        miso = 0;
    end
    #40 begin
        miso = 1;
    end
    #40 begin
        miso = 0;
    end
    #40 begin
        miso = 1;
    end
    #40 begin
        miso = 0;
    end
    #40 begin
        miso = 1;
    end
    #40 begin
        miso = 0;
    end
    #40 begin
        miso = 1;
    end
    #40 begin
        miso = 0;
    end
    #40 begin
        miso = 0;
    end
    #40 begin
        miso = 1;
    end
    #40 begin
        miso = 0;
    end
    $finish;
end

initial begin
    $dumpfile("master.vcd");
    $dumpvars(0,test_master);
end

endmodule