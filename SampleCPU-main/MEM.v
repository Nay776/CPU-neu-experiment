`include "lib/defines.vh"

// 访存级 (Memory Access)
// 功能: 处理访存数据、字节/半字对齐
module MEM(
    input wire clk,
    input wire rst,
    input wire [`StallBus-1:0] stall,

    input wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    input wire [31:0] data_sram_rdata,
    
    output wire [37:0] mem_to_id,
    output wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus
);

    // EX/MEM流水线寄存器
    reg [`EX_TO_MEM_WD-1:0] ex_to_mem_bus_r;

    always @ (posedge clk) begin
        if (rst)
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        else if (stall[3] == `Stop && stall[4] == `NoStop)
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        else if (stall[3] == `NoStop)
            ex_to_mem_bus_r <= ex_to_mem_bus;
    end

    // 信号解包
    wire [31:0] mem_pc;
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire [3:0] data_ram_readen;
    wire sel_rf_res;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] rf_wdata;
    wire [31:0] ex_result;

    assign {data_ram_readen, mem_pc, data_ram_en, data_ram_wen, 
            sel_rf_res, rf_we, rf_waddr, ex_result} = ex_to_mem_bus_r;

    // 访存数据处理（字节/半字加载）
    assign rf_wdata =     (data_ram_readen==4'b1111 && data_ram_en==1'b1) ? data_sram_rdata 
                        : (data_ram_readen==4'b0001 && data_ram_en==1'b1 && ex_result[1:0]==2'b00) ?({{24{data_sram_rdata[7]}},data_sram_rdata[7:0]})
                        : (data_ram_readen==4'b0001 && data_ram_en==1'b1 && ex_result[1:0]==2'b01) ?({{24{data_sram_rdata[15]}},data_sram_rdata[15:8]})
                        : (data_ram_readen==4'b0001 && data_ram_en==1'b1 && ex_result[1:0]==2'b10) ?({{24{data_sram_rdata[23]}},data_sram_rdata[23:16]})
                        : (data_ram_readen==4'b0001 && data_ram_en==1'b1 && ex_result[1:0]==2'b11) ?({{24{data_sram_rdata[31]}},data_sram_rdata[31:24]})
                        : (data_ram_readen==4'b0010 && data_ram_en==1'b1 && ex_result[1:0]==2'b00) ?({24'b0,data_sram_rdata[7:0]})
                        : (data_ram_readen==4'b0010 && data_ram_en==1'b1 && ex_result[1:0]==2'b01) ?({24'b0,data_sram_rdata[15:8]})
                        : (data_ram_readen==4'b0010 && data_ram_en==1'b1 && ex_result[1:0]==2'b10) ?({24'b0,data_sram_rdata[23:16]})
                        : (data_ram_readen==4'b0010 && data_ram_en==1'b1 && ex_result[1:0]==2'b11) ?({24'b0,data_sram_rdata[31:24]})
                        : (data_ram_readen==4'b0011 && data_ram_en==1'b1 && ex_result[1:0]==2'b00) ?({{16{data_sram_rdata[15]}},data_sram_rdata[15:0]})
                        : (data_ram_readen==4'b0011 && data_ram_en==1'b1 && ex_result[1:0]==2'b10) ?({{16{data_sram_rdata[31]}},data_sram_rdata[31:16]})
                        : (data_ram_readen==4'b0100 && data_ram_en==1'b1 && ex_result[1:0]==2'b00) ?({16'b0,data_sram_rdata[15:0]})
                        : (data_ram_readen==4'b0100 && data_ram_en==1'b1 && ex_result[1:0]==2'b10) ?({16'b0,data_sram_rdata[31:16]})
                        : ex_result;

    // 输出总线
    assign mem_to_wb_bus = {mem_pc, rf_we, rf_waddr, rf_wdata};
    assign mem_to_id = {rf_we, rf_waddr, rf_wdata};

endmodule