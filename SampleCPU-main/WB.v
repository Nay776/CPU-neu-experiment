`include "lib/defines.vh"

// 回写级 (Write Back)
// 功能: 写回寄存器堆
module WB(
    input wire clk,
    input wire rst,
    input wire [`StallBus-1:0] stall,
    input wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus,

    output wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus,
    output wire [37:0] wb_to_id,

    output wire [31:0] debug_wb_pc,
    output wire [3:0] debug_wb_rf_wen,
    output wire [4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata 
);

    // MEM/WB流水线寄存器
    reg [`MEM_TO_WB_WD-1:0] mem_to_wb_bus_r;

    always @ (posedge clk) begin
        if (rst)
            mem_to_wb_bus_r <= `MEM_TO_WB_WD'b0;
        else if (stall[4] == `Stop && stall[5] == `NoStop)
            mem_to_wb_bus_r <= `MEM_TO_WB_WD'b0;
        else if (stall[4] == `NoStop)
            mem_to_wb_bus_r <= mem_to_wb_bus;
    end

    // 信号解包
    wire [31:0] wb_pc;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] rf_wdata;

    assign {wb_pc, rf_we, rf_waddr, rf_wdata} = mem_to_wb_bus_r;

    // 输出总线
    assign wb_to_rf_bus = {rf_we, rf_waddr, rf_wdata};
    assign wb_to_id = {rf_we, rf_waddr, rf_wdata};

    // 调试接口
    assign debug_wb_pc       = wb_pc;
    assign debug_wb_rf_wen   = {4{rf_we}};
    assign debug_wb_rf_wnum  = rf_waddr;
    assign debug_wb_rf_wdata = rf_wdata;

endmodule