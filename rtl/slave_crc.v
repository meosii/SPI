`ifndef SLAVE_CRC_SPI
`define SLAVE_CRC_SPI

`include "../rtl/define.v"
module slave_crc_spi (
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
reg [$clog2(`DATA_WIDTH):0] cnt;
reg [`DATA_WIDTH + `CRC_DATA_WIDTH - 1:0] mosi_data;

reg [`CRC_DATA_WIDTH - 1 :0] crc_from_master;


always @(posedge clk_s or negedge rst_n) begin
    if (!rst_n) begin
        sclk_s_r0 <= 0;
    end else begin
        sclk_s_r0 <= sclk_s;
    end
end

assign sclk_s_pos = (sclk_s && !sclk_s_r0)? 1:0;
assign sclk_s_neg = (!sclk_s && sclk_s_r0)? 1:0;


assign sampl_en = (ss == 1)? 0:
                  (`CPOL ^ `CPHA)? sclk_s_neg:sclk_s_pos;
assign shift_en = (ss == 1)? 0:
                  (`CPOL ^ `CPHA)? sclk_s_pos:sclk_s_neg;

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
    if (!rst_n ) begin
        mosi_data <= 0;
    end else if (ss_neg) begin
        if (`CPHA) begin
            mosi_data <= mosi;
        end else begin
            mosi_data <= 0;
        end
    end else if (sampl_en) begin
        mosi_data <= {mosi_data[`DATA_WIDTH + `CRC_DATA_WIDTH - 2:0],mosi};
    end else begin
        mosi_data <= mosi_data;
    end
end

always @(posedge clk_s or negedge rst_n) begin
    if (!rst_n) begin
        cnt <= 0;
    end else if (ss_neg) begin
        if (`CPHA) begin
            cnt <= 1;
        end else begin
            cnt <= 0;
        end
    end else if (sampl_en) begin
        cnt <= cnt + 1;
    end else begin
        cnt <= cnt;
    end
end

always @(posedge clk_s or negedge rst_n) begin
    if (!rst_n || ss_neg) begin
        data_out_slave <= 0;
    end else if (cnt == (`DATA_WIDTH - 1)) begin
        data_out_slave <= {mosi_data[`DATA_WIDTH - 2:0],mosi};
    end else begin
        data_out_slave <= data_out_slave;
    end
end

// CRC
reg [$clog2(`DATA_WIDTH) + 1: 0] cnt_crc; // 0 -> 8 + 4 -> ···
reg [`DIV_DATA_WIDTH - 1:0] LFSR;
reg [`CRC_DATA_WIDTH - 1:0] crc_code;

always @(posedge clk_s or negedge rst_n) begin
    if (!rst_n) begin
        LFSR <= 0;
    end else if (cnt == (`DATA_WIDTH + `CRC_DATA_WIDTH - 1)) begin
        LFSR <= mosi_data[(`DATA_WIDTH + `CRC_DATA_WIDTH - 2) : (`DATA_WIDTH + `CRC_DATA_WIDTH - 6)];
    end else if ((cnt == (`DATA_WIDTH + `CRC_DATA_WIDTH)) && (cnt_crc < `DATA_WIDTH + `CRC_DATA_WIDTH)) begin
        if (LFSR[4] == 1) begin
            LFSR[4] <= LFSR[3];
            LFSR[3] <= LFSR[2];
            LFSR[2] <= ~LFSR[1];
            LFSR[1] <= ~LFSR[0];
            LFSR[0] <= mosi_data[`DATA_WIDTH + `CRC_DATA_WIDTH - 1 - cnt_crc];
        end else begin
            LFSR <= {LFSR[3:0],mosi_data[`DATA_WIDTH + `CRC_DATA_WIDTH - 1 - cnt_crc]};
        end
    end
end

always @(posedge clk_s or negedge rst_n) begin
    if (!rst_n || ss_neg) begin
        cnt_crc <= 0;
    end else if (cnt == (`DATA_WIDTH + `CRC_DATA_WIDTH - 1)) begin
        cnt_crc <= `DIV_DATA_WIDTH;
    end else if (cnt == (`DATA_WIDTH + `CRC_DATA_WIDTH)) begin
        cnt_crc <= cnt_crc + 1;
    end else begin
        cnt_crc <= 0;
    end
end


always @(posedge clk_s or negedge rst_n) begin
    if (!rst_n || ss_neg) begin
        crc_code <= 4'b1111;
    end else if (cnt_crc == (`DATA_WIDTH + `CRC_DATA_WIDTH)) begin
        crc_code <= {LFSR[3],LFSR[2],~LFSR[1],~LFSR[0]};
    end else begin
        crc_code <= crc_code;
    end
end

always @(posedge clk_s or negedge rst_n) begin
    if (!rst_n) begin
        data_valid <= 0;
    end else if (crc_code == 0) begin
        data_valid <= 1;
    end else begin
        data_valid <= 0;
    end
end

endmodule

`endif