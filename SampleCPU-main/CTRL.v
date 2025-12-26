`include "lib/defines.vh"

// 流水线控制器
// 功能: 处理流水线暂停请求
module CTRL(
    input wire rst,
    input wire stallreq_from_ex,
    input wire stallreq_from_id,

    output reg [`StallBus-1:0] stall
);  

    // 暂停控制逻辑
    // stall[0]: 保留
    // stall[1]: IF级
    // stall[2]: ID级
    // stall[3]: EX级
    // stall[4]: MEM级
    // stall[5]: WB级
    
    always @ (*) begin
        if (rst)
            stall <= `StallBus'b0;
        else if (stallreq_from_ex == 1'b1)
            stall <= 6'b001111;  // 暂停IF, ID, EX
        else if (stallreq_from_id == 1'b1)
            stall <= 6'b000111;  // 暂停IF, ID
        else
            stall <= 6'b000000;
    end
    
endmodule