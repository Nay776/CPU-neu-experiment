`include "lib/defines.vh"

// 取指级 (Instruction Fetch)
// 功能: 取指令、更新PC
module IF(
    input  wire                      clk,
    input  wire                      rst,
    input  wire [`StallBus-1:0]      stall,          // 流水线暂停信号
    input  wire [`BR_WD-1:0]         br_bus,         // 分支信息

    output wire [`IF_TO_ID_WD-1:0]   if_to_id_bus,   // 传给ID级
    output wire                      inst_sram_en,
    output wire [3:0]                inst_sram_wen,
    output wire [31:0]               inst_sram_addr,
    output wire [31:0]               inst_sram_wdata
);

    // 寄存器定义
    reg [31:0] pc_reg;
    reg ce_reg;
    
    // 分支信息解析
    wire br_e;                   // 分支使能
    wire [31:0] br_addr;         // 分支目标地址
    assign {br_e, br_addr} = br_bus;

    // PC更新逻辑
    wire [31:0] next_pc;
    assign next_pc = br_e ? br_addr : (pc_reg + 32'h4);

    always @(posedge clk) begin
        if (rst)
            pc_reg <= 32'hbfbf_fffc;
        else if (stall[0] == `NoStop)
            pc_reg <= next_pc;
    end

    // 使能信号
    always @(posedge clk) begin
        if (rst)
            ce_reg <= 1'b0;
        else if (stall[0] == `NoStop)
            ce_reg <= 1'b1;
    end

    // 指令存储器接口
    assign inst_sram_en    = ce_reg;
    assign inst_sram_wen   = 4'b0;
    assign inst_sram_addr  = pc_reg;
    assign inst_sram_wdata = 32'b0;
    
    assign if_to_id_bus = {ce_reg, pc_reg};

endmodule