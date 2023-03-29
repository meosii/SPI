`ifndef MASTER_SPI
`define MASTER_SPI

`include "../rtl/define.v"
module master_spi(
    input wire clk_m,
    input wire rst_n,
    input wire [`DATA_WIDTH - 1:0] data_in_master, // from master
    input wire start,
    input wire miso,
    output reg sclk_m,
    output wire mosi,
    output reg finish,
    output reg ss, // active low
    output reg [`DATA_WIDTH - 1:0] data_out_master
);

reg [1:0] c_state;
reg [1:0] n_state;
reg [$clog2(`DATA_WIDTH):0] cnt_data_width;
reg [$clog2(`DIV_FRE) - 1:0] cnt_clock;
reg sclk_m_r0;
wire sclk_m_pos;
wire sclk_m_neg;
wire shift_en;
wire sampl_en;
reg [`DATA_WIDTH - 1:0] data_in_master_r;
reg [`DATA_WIDTH - 1:0] data_out_master_r;

always @(posedge clk_m or negedge rst_n) begin
    if (!rst_n) begin
        c_state <= `IDLE;
    end else begin
        c_state <= n_state;
    end
end

always @(*) begin
    case(c_state)
    `IDLE:    n_state <= (start)? `START : 
                                  `IDLE;
    `START:   n_state <= `EXE;
    `EXE:     n_state <= (cnt_data_width == `DATA_WIDTH)? `FINISH :
                                                          `EXE;
    `FINISH:  n_state <= `IDLE;
    default: n_state <= `IDLE;
    endcase
end

always @(posedge clk_m or negedge rst_n) begin
    if (!rst_n) begin
        cnt_clock <= 0;
        finish <= 0;
        ss <= 1;
        data_in_master_r <= 0;
        data_out_master <= 0;
    end else begin
        case(n_state) //为保证状态和操作同步，判断下一状态
        `IDLE: begin
            cnt_clock <= 0;
            cnt_data_width <= 0;
            finish <= 0;
            ss <= 1;
            data_out_master <= data_out_master;
        end
        `START: begin
            ss <= 0;
            data_in_master_r <= data_in_master;
            data_out_master <= 0;
	    end
        `EXE: begin
            if (cnt_clock < `DIV_FRE) begin // 1 - 10
                cnt_clock <= cnt_clock + 1;
            end else begin
                cnt_clock <= 1;
            end
            if (sclk_m_pos) begin
                cnt_data_width <= cnt_data_width + 1;
            end else begin
                cnt_data_width <= cnt_data_width;
            end
            if (shift_en) begin
                data_in_master_r <= {data_in_master_r[`DATA_WIDTH - 2:0],1'b0};
            end else begin
                data_in_master_r <= data_in_master_r;
            end
            data_out_master <= 0;
        end
        `FINISH: begin
            cnt_data_width <= 0;
            cnt_clock <= 0;
            finish <= 1;
            ss <= 1;
            data_out_master <= data_out_master_r;
        end
	endcase
    end
end

assign mosi = data_in_master_r[`DATA_WIDTH - 1];

//时钟分频
always @(posedge clk_m or negedge rst_n) begin
    if (!rst_n) begin
        sclk_m <= `CPOL;
    end else if (c_state == `EXE) begin
        if (cnt_clock == (`DIV_FRE/2) || cnt_clock == (`DIV_FRE)) begin
            sclk_m <= ~sclk_m;
        end else begin
            sclk_m <= sclk_m;
        end
    end else begin
        sclk_m <= `CPOL;
    end
end

/*
时钟沿检测：由于当 CPOL 和 CPAH 不确定时，为了写出由 CPOL 和 CPAH 直接确定的代码
不采用 posdge negedge sclk_m ，而是利用 CPOL 和 CPAH 判断使能，从而输出 mosi
缺点： 实际的 mosi 输出不在 sclk_m 的沿时刻，而会延迟边沿检测需要的一个时钟周期
*/
always @(posedge clk_m or negedge rst_n) begin
    if (!rst_n) begin
        sclk_m_r0 <= 0;
    end else begin
        sclk_m_r0 <= sclk_m;
    end
end

assign sclk_m_pos = (sclk_m && !sclk_m_r0)? 1:0;
assign sclk_m_neg = (!sclk_m && sclk_m_r0)? 1:0;

assign sampl_en = (`CPOL ^ `CPHA)? sclk_m_neg : 
                                   sclk_m_pos; // 00 上升沿采样 11上升沿采样
assign shift_en = (`CPOL ^ `CPHA)? sclk_m_pos : 
                                   sclk_m_neg; // 00 下降沿翻转 01下降沿翻转

always @(posedge clk_m or negedge rst_n) begin
    if (!rst_n) begin
        data_out_master_r <= 0;
    end else if (sampl_en) begin
        data_out_master_r <= {data_out_master_r[`DATA_WIDTH - 2:0],miso};
    end else begin
        data_out_master_r <= data_out_master_r;
    end
end

endmodule

`endif