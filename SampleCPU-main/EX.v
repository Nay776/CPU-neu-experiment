`include "lib/defines.vh"

// 执行级 (Execute)
// 功能: ALU运算、乘除法、访存地址计算
module EX(
    input  wire                      clk,
    input  wire                      rst,
    input  wire [`StallBus-1:0]      stall,
    output wire                      stallreq_from_ex,
    
    input  wire [`ID_TO_EX_WD-1:0]   id_to_ex_bus,
    output wire [`EX_TO_MEM_WD-1:0]  ex_to_mem_bus,
    
    output wire [37:0]               ex_to_id,
    output wire [65:0]               hilo_ex_to_id,
    output wire                      ex_is_load,
    
    output wire                      data_sram_en,
    output wire [3:0]                data_sram_wen,
    output wire [31:0]               data_sram_addr,
    output wire [31:0]               data_sram_wdata
);

    // ID/EX流水线寄存器
    reg [`ID_TO_EX_WD-1:0] id_to_ex_bus_r;

    always @(posedge clk) begin
        if (rst)
            id_to_ex_bus_r <= `ID_TO_EX_WD'b0;
        else if (stall[2] == `Stop && stall[3] == `NoStop)
            id_to_ex_bus_r <= `ID_TO_EX_WD'b0;
        else if (stall[2] == `NoStop)
            id_to_ex_bus_r <= id_to_ex_bus;
    end
    
    // 信号解包
    wire [31:0] pc, instruction;
    wire [11:0] alu_op;
    wire [2:0]  alu_src1_sel;
    wire [3:0]  alu_src2_sel;
    wire        mem_write_en;
    wire [3:0]  mem_write_enable, mem_read_enable;
    wire        rf_write_en;
    wire [4:0]  rf_write_addr;
    wire        rf_result_sel;
    wire [31:0] rf_read_data1, rf_read_data2;
    wire        inst_mthi, inst_mtlo, inst_mult, inst_multu, inst_div, inst_divu;

    assign {
        mem_read_enable, inst_mthi, inst_mtlo, inst_multu, inst_mult, inst_divu, inst_div,
        pc, instruction, alu_op, alu_src1_sel, alu_src2_sel,
        mem_write_en, mem_write_enable, rf_write_en, rf_write_addr, rf_result_sel,
        rf_read_data1, rf_read_data2
    } = id_to_ex_bus_r;

    // ALU操作数选择
    wire [31:0] imm_sign_extend = {{16{instruction[15]}}, instruction[15:0]};
    wire [31:0] imm_zero_extend = {16'b0, instruction[15:0]};
    wire [31:0] sa_zero_extend  = {27'b0, instruction[10:6]};

    wire [31:0] alu_operand1, alu_operand2, alu_result, ex_result;

    assign alu_operand1 = alu_src1_sel[1] ? pc :
                          alu_src1_sel[2] ? sa_zero_extend : rf_read_data1;

    assign alu_operand2 = alu_src2_sel[1] ? imm_sign_extend :
                          alu_src2_sel[2] ? 32'd8 :
                          alu_src2_sel[3] ? imm_zero_extend : rf_read_data2;
    
    alu u_alu(
        .alu_control (alu_op),
        .alu_src1    (alu_operand1),
        .alu_src2    (alu_operand2),
        .alu_result  (alu_result)
    );
    
    assign ex_result = alu_result;
    assign ex_is_load = (instruction[31:26] == 6'b100011);

    // 乘法器
    wire [63:0] mul_result;
    wire        mul_ready;
    reg         stallreq_for_mul;
    reg         mul_signed, mul_start;
    reg [31:0]  mul_operand1, mul_operand2;

    mymul my_mul(
        .rst          (rst),
        .clk          (clk),
        .signed_mul_i (mul_signed),
        .a_o          (mul_operand1),
        .b_o          (mul_operand2),
        .start_i      (mul_start),
        .result_o     (mul_result),
        .ready_o      (mul_ready)
    );

    always @(*) begin
        if (rst) begin
            {stallreq_for_mul, mul_operand1, mul_operand2, mul_start, mul_signed} = 
                {`NoStop, `ZeroWord, `ZeroWord, `MulStop, 1'b0};
        end
        else begin
            {stallreq_for_mul, mul_operand1, mul_operand2, mul_start, mul_signed} = 
                {`NoStop, `ZeroWord, `ZeroWord, `MulStop, 1'b0};
            
            case ({inst_mult, inst_multu})
                2'b10: begin  // MULT
                    if (mul_ready == `MulResultNotReady) begin
                        {mul_operand1, mul_operand2, mul_start, mul_signed, stallreq_for_mul} = 
                            {rf_read_data1, rf_read_data2, `MulStart, 1'b1, `Stop};
                    end
                    else begin
                        {mul_operand1, mul_operand2, mul_start, mul_signed, stallreq_for_mul} = 
                            {rf_read_data1, rf_read_data2, `MulStop, 1'b1, `NoStop};
                    end
                end
                2'b01: begin  // MULTU
                    if (mul_ready == `MulResultNotReady) begin
                        {mul_operand1, mul_operand2, mul_start, mul_signed, stallreq_for_mul} = 
                            {rf_read_data1, rf_read_data2, `MulStart, 1'b0, `Stop};
                    end
                    else begin
                        {mul_operand1, mul_operand2, mul_start, mul_signed, stallreq_for_mul} = 
                            {rf_read_data1, rf_read_data2, `MulStop, 1'b0, `NoStop};
                    end
                end
            endcase
        end
    end

    // 除法器
    wire [63:0] div_result;
    wire        div_ready;
    reg         stallreq_for_div;
    reg         div_signed, div_start;
    reg [31:0]  div_dividend, div_divisor;

    assign stallreq_from_ex = stallreq_for_div | stallreq_for_mul;

    div u_div(
        .rst          (rst),
        .clk          (clk),
        .signed_div_i (div_signed),
        .opdata1_i    (div_dividend),
        .opdata2_i    (div_divisor),
        .start_i      (div_start),
        .annul_i      (1'b0),
        .result_o     (div_result),
        .ready_o      (div_ready)
    );

    always @(*) begin
        if (rst) begin
            {stallreq_for_div, div_dividend, div_divisor, div_start, div_signed} = 
                {`NoStop, `ZeroWord, `ZeroWord, `DivStop, 1'b0};
        end
        else begin
            {stallreq_for_div, div_dividend, div_divisor, div_start, div_signed} = 
                {`NoStop, `ZeroWord, `ZeroWord, `DivStop, 1'b0};
            
            case ({inst_div, inst_divu})
                2'b10: begin  // DIV
                    if (div_ready == `DivResultNotReady) begin
                        {div_dividend, div_divisor, div_start, div_signed, stallreq_for_div} = 
                            {rf_read_data1, rf_read_data2, `DivStart, 1'b1, `Stop};
                    end
                    else begin
                        {div_dividend, div_divisor, div_start, div_signed, stallreq_for_div} = 
                            {rf_read_data1, rf_read_data2, `DivStop, 1'b1, `NoStop};
                    end
                end
                2'b01: begin  // DIVU
                    if (div_ready == `DivResultNotReady) begin
                        {div_dividend, div_divisor, div_start, div_signed, stallreq_for_div} = 
                            {rf_read_data1, rf_read_data2, `DivStart, 1'b0, `Stop};
                    end
                    else begin
                        {div_dividend, div_divisor, div_start, div_signed, stallreq_for_div} = 
                            {rf_read_data1, rf_read_data2, `DivStop, 1'b0, `NoStop};
                    end
                end
            endcase
        end
    end

    // HILO寄存器
    wire        hi_write_en, lo_write_en;
    wire [31:0] hi_write_data, lo_write_data;
    
    assign hi_write_en = inst_divu | inst_div | inst_mult | inst_multu | inst_mthi;
    assign lo_write_en = inst_divu | inst_div | inst_mult | inst_multu | inst_mtlo;

    assign hi_write_data = (inst_div | inst_divu)   ? div_result[63:32] :
                           (inst_mult | inst_multu) ? mul_result[63:32] :
                           (inst_mthi)              ? rf_read_data1 : 32'b0;

    assign lo_write_data = (inst_div | inst_divu)   ? div_result[31:0] :
                           (inst_mult | inst_multu) ? mul_result[31:0] :
                           (inst_mtlo)              ? rf_read_data1 : 32'b0;

    assign hilo_ex_to_id = {hi_write_en, lo_write_en, hi_write_data, lo_write_data};

    // 数据存储器接口
    assign data_sram_en = mem_write_en;

    assign data_sram_wen = (mem_read_enable == 4'b0101 && ex_result[1:0] == 2'b00) ? 4'b0001 :
                           (mem_read_enable == 4'b0101 && ex_result[1:0] == 2'b01) ? 4'b0010 :
                           (mem_read_enable == 4'b0101 && ex_result[1:0] == 2'b10) ? 4'b0100 :
                           (mem_read_enable == 4'b0101 && ex_result[1:0] == 2'b11) ? 4'b1000 :
                           (mem_read_enable == 4'b0111 && ex_result[1:0] == 2'b00) ? 4'b0011 :
                           (mem_read_enable == 4'b0111 && ex_result[1:0] == 2'b10) ? 4'b1100 :
                           mem_write_enable;
    
    assign data_sram_addr = ex_result;
    
    assign data_sram_wdata = (data_sram_wen == 4'b1111) ? rf_read_data2 :
                             (data_sram_wen == 4'b0001) ? {24'b0, rf_read_data2[7:0]} :
                             (data_sram_wen == 4'b0010) ? {16'b0, rf_read_data2[7:0], 8'b0} :
                             (data_sram_wen == 4'b0100) ? {8'b0, rf_read_data2[7:0], 16'b0} :
                             (data_sram_wen == 4'b1000) ? {rf_read_data2[7:0], 24'b0} :
                             (data_sram_wen == 4'b0011) ? {16'b0, rf_read_data2[15:0]} :
                             (data_sram_wen == 4'b1100) ? {rf_read_data2[15:0], 16'b0} : 32'b0;

    // 输出总线
    assign ex_to_mem_bus = {
        mem_read_enable, pc, mem_write_en, mem_write_enable,
        rf_result_sel, rf_write_en, rf_write_addr, ex_result
    };
    
    assign ex_to_id = {rf_write_en, rf_write_addr, ex_result};

endmodule

    // ========================================================================
    // 立即数扩展
    // ========================================================================
    wire [31:0] imm_sign_extend;       // 符号扩展立即数
    wire [31:0] imm_zero_extend;       // 零扩展立即数
    wire [31:0] sa_zero_extend;        // 移位量零扩展
    
    assign imm_sign_extend = {{16{instruction[15]}}, instruction[15:0]};
    assign imm_zero_extend = {16'b0, instruction[15:0]};
    assign sa_zero_extend  = {27'b0, instruction[10:6]};

    // ========================================================================
    // ALU 源操作数选择
    // ========================================================================
    wire [31:0] alu_operand1;          // ALU操作数1
    wire [31:0] alu_operand2;          // ALU操作数2
    wire [31:0] alu_result;            // ALU运算结果
    wire [31:0] ex_result;             // EX阶段最终结果

    assign alu_operand1 = alu_src1_sel[1] ? pc :
                          alu_src1_sel[2] ? sa_zero_extend : 
                          rf_read_data1;

    assign alu_operand2 = alu_src2_sel[1] ? imm_sign_extend :
                          alu_src2_sel[2] ? 32'd8 :
                          alu_src2_sel[3] ? imm_zero_extend : 
                          rf_read_data2;
    
    // ========================================================================
    // ALU 实例化
    // ========================================================================
    alu u_alu (
        .alu_control (alu_op       ),
        .alu_src1    (alu_operand1 ),
        .alu_src2    (alu_operand2 ),
        .alu_result  (alu_result   )
    );
    
    assign ex_result = alu_result;


    // 流水线总线输出
    
    assign ex_to_mem_bus = {
        mem_read_enable,   // 79:76
        pc,                // 75:44
        mem_write_en,      // 43
        mem_write_enable,  // 42:39
        rf_result_sel,     // 38
        rf_write_en,       // 37
        rf_write_addr,     // 36:32
        ex_result          // 31:0
    };
    
    // 前推到ID阶段的数据
    assign ex_to_id = {   
        rf_write_en,       // 37
        rf_write_addr,     // 36:32
        ex_result          // 31:0
    };
    
    // 数据存储器接口信号生成

    // 根据字节/半字访问生成实际的写使能信号
    assign data_sram_wen = (mem_read_enable == 4'b0101 && ex_result[1:0] == 2'b00) ? 4'b0001 :  // SB: 字节0
                           (mem_read_enable == 4'b0101 && ex_result[1:0] == 2'b01) ? 4'b0010 :  // SB: 字节1
                           (mem_read_enable == 4'b0101 && ex_result[1:0] == 2'b10) ? 4'b0100 :  // SB: 字节2
                           (mem_read_enable == 4'b0101 && ex_result[1:0] == 2'b11) ? 4'b1000 :  // SB: 字节3
                           (mem_read_enable == 4'b0111 && ex_result[1:0] == 2'b00) ? 4'b0011 :  // SH: 半字低
                           (mem_read_enable == 4'b0111 && ex_result[1:0] == 2'b10) ? 4'b1100 :  // SH: 半字高
                           mem_write_enable;  // SW: 全字写
    
    // 存储器访问地址
    assign data_sram_addr = ex_result;
    
    // 根据写使能信号对齐写数据
    assign data_sram_wdata = (data_sram_wen == 4'b1111) ? rf_read_data2 :                  // 字写
                             (data_sram_wen == 4'b0001) ? {24'b0, rf_read_data2[7:0]} :    // 字节0
                             (data_sram_wen == 4'b0010) ? {16'b0, rf_read_data2[7:0], 8'b0} : // 字节1
                             (data_sram_wen == 4'b0100) ? {8'b0, rf_read_data2[7:0], 16'b0} : // 字节2
                             (data_sram_wen == 4'b1000) ? {rf_read_data2[7:0], 24'b0} :    // 字节3
                             (data_sram_wen == 4'b0011) ? {16'b0, rf_read_data2[15:0]} :   // 半字低
                             (data_sram_wen == 4'b1100) ? {rf_read_data2[15:0], 16'b0} :   // 半字高
                             32'b0;
    
    wire        lo_write_en;           // LO寄存器写使能
    wire [31:0] hi_write_data;         // HI寄存器写数据
    wire [31:0] lo_write_data;         // LO寄存器写数据
    
    // 写使能信号：乘除法指令或MTHI/MTLO指令会写HILO寄存器
    assign hi_write_en = inst_divu | inst_div | inst_mult | inst_multu | inst_mthi;
    assign lo_write_en = inst_divu | inst_div | inst_mult | inst_multu | inst_mtlo;

    // HI寄存器写数据选择
    assign hi_write_data = (inst_div | inst_divu)   ? div_result[63:32] :  // 除法：高32位为余数
                           (inst_mult | inst_multu) ? mul_result[63:32] :  // 乘法：高32位
                           (inst_mthi)              ? rf_read_data1 :      // MTHI指令
                           32'b0;

    // LO寄存器写数据选择
    assign lo_write_data = (inst_div | inst_divu)   ? div_result[31:0] :   // 除法：低32位为商
                           (inst_mult | inst_multu) ? mul_result[31:0] :   // 乘法：低32位
                           (inst_mtlo)              ? rf_read_data1 :      // MTLO指令
                           32'b0;

    // 前推HILO数据到ID阶段
    assign hilo_ex_to_id = {
        hi_write_en,      // 65
        lo_write_en,      // 64
        hi_write_data,    // 63:32
        lo_write_data     // 31:0
    };


    // 乘法器模块 (32周期移位乘法器)
    wire [63:0] mul_result;            // 乘法结果 (64位)
    wire        mul_ready;             // 乘法完成标志
    
    reg         stallreq_for_mul;      // 乘法器暂停请求
    reg         mul_signed;            // 是否为有符号乘法
    reg [31:0]  mul_operand1;          // 乘法操作数1
    reg [31:0]  mul_operand2;          // 乘法操作数2
    reg         mul_start;             // 乘法启动信号
    
    // 乘法器实例化
    mymul my_mul (
        .rst          (rst           ),
        .clk          (clk           ),
        .signed_mul_i (mul_signed    ),
        .a_o          (mul_operand1  ),
        .b_o          (mul_operand2  ),
        .start_i      (mul_start     ),
        .result_o     (mul_result    ),
        .ready_o      (mul_ready     )
    );
    // 乘法器控制逻辑
    always @(*) begin
        if (rst) begin
            stallreq_for_mul = `NoStop;
            mul_operand1     = `ZeroWord;
            mul_operand2     = `ZeroWord;
            mul_start        = `MulStop;
            mul_signed       = 1'b0;
        end
        else begin
            // 默认值
            stallreq_for_mul = `NoStop;
            mul_operand1     = `ZeroWord;
            mul_operand2     = `ZeroWord;
            mul_start        = `MulStop;
            mul_signed       = 1'b0;
            
            case ({inst_mult, inst_multu})
                2'b10: begin  // MULT 有符号乘法
                    if (mul_ready == `MulResultNotReady) begin
                        mul_operand1     = rf_read_data1;
                        mul_operand2     = rf_read_data2;
                        mul_start        = `MulStart;
                        mul_signed       = 1'b1;
                        stallreq_for_mul = `Stop;
                    end
                    else if (mul_ready == `MulResultReady) begin
                        mul_operand1     = rf_read_data1;
                        mul_operand2     = rf_read_data2;
                        mul_start        = `MulStop;
                        mul_signed       = 1'b1;
                        stallreq_for_mul = `NoStop;
                    end
                end
                
                2'b01: begin  // MULTU 无符号乘法
                    if (mul_ready == `MulResultNotReady) begin
                        mul_operand1     = rf_read_data1;
                        mul_operand2     = rf_read_data2;
                        mul_start        = `MulStart;
                        mul_signed       = 1'b0;
                        stallreq_for_mul = `Stop;
                    end
                    else if (mul_ready == `MulResultReady) begin
                        mul_operand1     = rf_read_data1;
                        mul_operand2     = rf_read_data2;
                        mul_start        = `MulStop;
                        mul_signed       = 1'b0;
                        stallreq_for_mul = `NoStop;
                    end
                end
                
                default: begin
                    // 保持默认值
                end
            endcase
        end
    end


    // 除法器模块
    wire [63:0] div_result;            // 除法结果 (高32位:余数, 低32位:商)
    wire        div_ready;             // 除法完成标志
    
    reg         stallreq_for_div;      // 除法器暂停请求
    reg         div_signed;            // 是否为有符号除法
    reg [31:0]  div_dividend;          // 被除数
    reg [31:0]  div_divisor;           // 除数
    reg         div_start;             // 除法启动信号
    
    // 合并暂停请求
    assign stallreq_from_ex = stallreq_for_div | stallreq_for_mul;

    // 除法器实例化
    div u_div (
        .rst          (rst           ),
        .clk          (clk           ),
        .signed_div_i (div_signed    ),  // 是否为有符号除法
        .opdata1_i    (div_dividend  ),  // 被除数
        .opdata2_i    (div_divisor   ),  // 除数
        .start_i      (div_start     ),  // 启动信号
        .annul_i      (1'b0          ),  // 取消信号（未使用）
        .result_o     (div_result    ),  // 除法结果
        .ready_o      (div_ready     )   // 完成标志
    );

    // 除法器控制逻辑
    always @(*) begin
        if (rst) begin
            stallreq_for_div = `NoStop;
            div_dividend     = `ZeroWord;
            div_divisor      = `ZeroWord;
            div_start        = `DivStop;
            div_signed       = 1'b0;
        end
        else begin
            // 默认值
            stallreq_for_div = `NoStop;
            div_dividend     = `ZeroWord;
            div_divisor      = `ZeroWord;
            div_start        = `DivStop;
            div_signed       = 1'b0;
            
            case ({inst_div, inst_divu})
                2'b10: begin  // DIV 有符号除法
                    if (div_ready == `DivResultNotReady) begin
                        div_dividend     = rf_read_data1;
                        div_divisor      = rf_read_data2;
                        div_start        = `DivStart;
                        div_signed       = 1'b1;
                        stallreq_for_div = `Stop;
                    end
                    else if (div_ready == `DivResultReady) begin
                        div_dividend     = rf_read_data1;
                        div_divisor      = rf_read_data2;
                        div_start        = `DivStop;
                        div_signed       = 1'b1;
                        stallreq_for_div = `NoStop;
                    end
                end
                
                2'b01: begin  // DIVU 无符号除法
                    if (div_ready == `DivResultNotReady) begin
                        div_dividend     = rf_read_data1;
                        div_divisor      = rf_read_data2;
                        div_start        = `DivStart;
                        div_signed       = 1'b0;
                        stallreq_for_div = `Stop;
                    end
                    else if (div_ready == `DivResultReady) begin
                        div_dividend     = rf_read_data1;
                        div_divisor      = rf_read_data2;
                        div_start        = `DivStop;
                        div_signed       = 1'b0;
                        stallreq_for_div = `NoStop;
                    end
                end
                
                default: begin
                    // 保持默认值
                end
            endcase
        end
    end

endmodule