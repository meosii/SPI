`ifndef SLAVE_SPI
`define SLAVE_SPI

`include "../rtl/define.v"

module slave_spi (
input wire clk_s,
input wire sclk_s,
input wire ss, // low is active
input wire rst_n,
input wire mosi,
input wire [`DATA_WIDTH - 1:0] data_in_slave, // from slave
output wire miso,
output reg [`DATA_WIDTH - 1:0] data_out_slave, // to slave
output reg data_valid
);

reg [`DATA_WIDTH - 1:0] data_in_slave_r;
reg sclk_s_r0;
wire sclk_s_pos;
wire sclk_s_neg;
wire shift_en;
wire sampl_en;
reg ss_r0;
wire ss_neg;
reg [`DATA_WIDTH - 1:0] data_out_slave_r;
reg [$clog2(`DATA_WIDTH):0] cnt;

always @(posedge clk_s or negedge rst_n) begin
    if (!rst_n) begin
        sclk_s_r0 <= 0;
    end else begin
        sclk_s_r0 <= sclk_s;
    end
end

assign sclk_s_pos = (sclk_s && !sclk_s_r0)? 1:0;
assign sclk_s_neg = (!sclk_s && sclk_s_r0)? 1:0;


assign sampl_en = (`CPOL ^ `CPHA)? sclk_s_neg:sclk_s_pos;
assign shift_en = (`CPOL ^ `CPHA)? sclk_s_pos:sclk_s_neg;

//ss边沿检测

always @(posedge clk_s or negedge rst_n) begin
    if (!rst_n) begin
        ss_r0 <= 0;
    end else begin
        ss_r0 <= ss;
    end
end
assign ss_neg = (!ss && ss_r0)? 1:0;

always @(posedge clk_s or negedge rst_n) begin
    if (!rst_n) begin
        data_in_slave_r <= 0;
    end else if(ss_neg) begin
        data_in_slave_r <= data_in_slave;
    end else if (shift_en) begin
        data_in_slave_r <= {data_in_slave_r[`DATA_WIDTH - 2:0],1'b0};
    end else begin
        data_in_slave_r <= data_in_slave_r;
    end
end

assign miso = data_in_slave_r[`DATA_WIDTH - 1];

always @(posedge clk_s or negedge rst_n) begin
    if (!rst_n) begin
        data_out_slave_r <= 0;
    end else if (sampl_en) begin
        data_out_slave_r <= {data_out_slave_r[`DATA_WIDTH - 2:0],mosi};
    end else begin
        data_out_slave_r <= data_out_slave_r;
    end
end

always @(posedge clk_s or negedge rst_n) begin
    if (!rst_n) begin
        cnt <= 0;
    end else if (sampl_en && (cnt < `DATA_WIDTH)) begin // 1 -> `DATA_WIDTH
        cnt <= cnt + 1;
    end else if (ss_neg) begin
        cnt <= 0;
    end else begin
        cnt <= cnt;
    end
end

always @(posedge clk_s or negedge rst_n) begin
    if (!rst_n) begin
        data_out_slave <= 0;
        data_valid <= 0;
    end else if (cnt == `DATA_WIDTH) begin
        data_out_slave <= data_out_slave_r;
        data_valid <= 1;
    end else begin
        data_out_slave <= 0;
        data_valid <= 0;
    end
end

endmodule

`endif