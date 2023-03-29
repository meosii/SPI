`ifndef MASTER_CRC_SPI
`define MASTER_CRC_SPI
`include "../rtl/define.v"
/* 
crc Polynomial: x^4 + x + 1
dividend: data_in_master
Divisor: 10011
`DIV_DATA_WIDTH = 5
*/
module master_crc_spi(
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

// crc
reg [$clog2(`DATA_WIDTH) : 0] cnt_crc; // 0 -> 8
reg [`DATA_WIDTH + `CRC_DATA_WIDTH - 1:0] data_crc; // {data_in_master , 4'b0000}
reg [`DIV_DATA_WIDTH - 1:0] LFSR;
reg [`CRC_DATA_WIDTH - 1:0] crc_code;
reg [`CRC_DATA_WIDTH - 1:0] crc_code_r;

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
    `EXE:     n_state <= (cnt_data_width == `DATA_WIDTH + `DIV_DATA_WIDTH - 1)? `FINISH : 
                                                                                `EXE; // extended spi clock for crc
    `FINISH:  n_state <= `IDLE;
    default:  n_state <= `IDLE;
    endcase
end

always @(posedge clk_m or negedge rst_n) begin
    if (!rst_n) begin
        cnt_clock <= 0;
        finish <= 0;
        ss <= 1;
        data_in_master_r <= 0;
        data_out_master <= 0;
        data_out_master_r <= 0;
        data_crc <= 0;
        crc_code <= 0;
    end else begin
        case(n_state)
            `IDLE: begin
                cnt_clock <= 0;
                cnt_crc <= 0;
                cnt_data_width <= 0;
                finish <= 0;
                ss <= 1;
                data_out_master <= data_out_master;
                crc_code <= 0;
            end
            `START: begin
                ss <= 0;
                data_in_master_r <= data_in_master;
                data_out_master <= 0;
                data_out_master_r <= 0;
                if (`CPHA) begin
                    cnt_data_width <= 1;
                end else begin
                    cnt_data_width <= 0;
                end
            // crc
                data_crc <= {data_in_master,4'b0000};
                LFSR <= {~data_in_master[`DATA_WIDTH - 1],data_in_master[`DATA_WIDTH - 2],
                        data_in_master[`DATA_WIDTH - 3],~data_in_master[`DATA_WIDTH - 4],~data_in_master[`DATA_WIDTH - 5]};
                cnt_crc <= `DIV_DATA_WIDTH;
            end
            `EXE: begin
            // clock div
                if (cnt_clock < `DIV_FRE) begin // 1 - 10
                    cnt_clock <= cnt_clock + 1;
                end else begin
                    cnt_clock <= 1;
                end
            // cnt_data_width: sample number
                if (sampl_en) begin
                    cnt_data_width <= cnt_data_width + 1;
                end else begin
                    cnt_data_width <= cnt_data_width;
                end
            // data to slave: mosi
                if (shift_en) begin
                    data_in_master_r <= {data_in_master_r[`DATA_WIDTH - 2:0],1'b0};
                end else begin
                    data_in_master_r <= data_in_master_r;
                end
            // data from slave: miso
                if ((`CPHA && start_r1) || (sampl_en && (cnt_data_width < `DATA_WIDTH))) begin
                    data_out_master_r <= {data_out_master_r[`DATA_WIDTH - 2:0],miso};
                end else begin
                    data_out_master_r <= data_out_master_r;
                end
                if (cnt_data_width >= `DATA_WIDTH) begin
                    data_out_master <= data_out_master_r;
                end else begin
                    data_out_master <= 0;
                end
            //crc
                if (cnt_crc < `DATA_WIDTH + `CRC_DATA_WIDTH) begin
                    cnt_crc <= cnt_crc + 1;
                end else begin
                    cnt_crc <=  cnt_crc;
                end
                //"LFSR" saves the result of each XOR
                if (cnt_crc < `DATA_WIDTH + `CRC_DATA_WIDTH) begin
                    if (LFSR[`DIV_DATA_WIDTH - 1] == 1) begin // XOR then shift
                        LFSR <= {LFSR[3],LFSR[2],~LFSR[1],~LFSR[0],data_crc[`DATA_WIDTH + `CRC_DATA_WIDTH - 1 - cnt_crc]};
                    end else begin // just shift
                        LFSR <= {LFSR[3:0],data_crc[`DATA_WIDTH + `CRC_DATA_WIDTH - 1 - cnt_crc]};
                    end
                end else begin
                    LFSR <= LFSR;
                    crc_code <= {LFSR[`DIV_DATA_WIDTH - 2],LFSR[`DIV_DATA_WIDTH - 3],~LFSR[`DIV_DATA_WIDTH - 4],~LFSR[`DIV_DATA_WIDTH - 5]};
                    if (cnt_data_width <= `DATA_WIDTH) begin //cnt = 8, mosi will get first code, crc_code_r can't shift
                        crc_code_r <= crc_code;
                    end else if (shift_en) begin
                        crc_code_r <= {crc_code_r[`CRC_DATA_WIDTH - 2:`CRC_DATA_WIDTH - 4],1'b0};
                    end else begin
                        crc_code_r <= crc_code_r;
                    end
                end
            end
            `FINISH: begin
                cnt_data_width <= 0;
                cnt_clock <= 0;
                finish <= 1;
                ss <= 1;
                data_out_master <= data_out_master;
                cnt_crc <= 0;
                data_crc <= 0;
                LFSR <= 0;
            end
	    endcase
    end
end

assign mosi = (cnt_data_width < `DATA_WIDTH)? data_in_master_r[`DATA_WIDTH - 1] 
                                            : crc_code_r[`CRC_DATA_WIDTH - 1];

//Clock division
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

always @(posedge clk_m or negedge rst_n) begin
    if (!rst_n) begin
        sclk_m_r0 <= 0;
    end else begin
        sclk_m_r0 <= sclk_m;
    end
end

assign sclk_m_pos = (sclk_m && !sclk_m_r0)? 1:0;
assign sclk_m_neg = (!sclk_m && sclk_m_r0)? 1:0;

assign sampl_en = (n_state != `EXE)? 0 :
                    (`CPOL ^ `CPHA)? sclk_m_neg : 
                                    sclk_m_pos;
assign shift_en = (n_state != `EXE)? 0 :
                    (`CPOL ^ `CPHA)? sclk_m_pos : 
                                    sclk_m_neg;

reg start_r0;
reg start_r1;

always @(posedge clk_m or negedge rst_n) begin
    if (!rst_n) begin
        start_r0 <= 0;
        start_r1 <= 0;
    end else begin
        start_r0 <= start;
        start_r1 <= start_r0;
    end
end

endmodule

`endif