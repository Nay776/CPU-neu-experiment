`include "lib/defines.vh"

module IF(
    input wire clk,
    input wire rst,
    input wire [`StallBus-1:0] stall,
    input wire [`BR_WD-1:0] br_bus,

    output wire [`IF_TO_ID_WD-1:0] if_to_id_bus,
    output wire inst_sram_en,
    output wire [3:0] inst_sram_wen,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata
);

    // Program Counter register
    reg [31:0] pc_reg;
    // Chip enable register
    reg ce_reg;
    
    // Next PC value
    wire [31:0] next_pc;
    // Branch enable signal
    wire br_e;
    // Branch target address
    wire [31:0] br_addr;

    // Unpack branch bus
    assign {br_e, br_addr} = br_bus;

    // PC register update
    always @ (posedge clk) begin
        if (rst) begin
            pc_reg <= 32'hbfbf_fffc;  // Reset PC to initial address
        end
        else if (stall[0] == `NoStop) begin
            pc_reg <= next_pc;
        end
    end

    // Chip enable register update
    always @ (posedge clk) begin
        if (rst) begin
            ce_reg <= 1'b0;
        end
        else if (stall[0] == `NoStop) begin
            ce_reg <= 1'b1;
        end
    end

    // Calculate next PC (branch or sequential)
    assign next_pc = br_e ? br_addr : (pc_reg + 32'h4);

    // Instruction SRAM interface
    assign inst_sram_en    = ce_reg;
    assign inst_sram_wen   = 4'b0;           // Read only
    assign inst_sram_addr  = pc_reg;
    assign inst_sram_wdata = 32'b0;
    
    // Output to ID stage
    assign if_to_id_bus = {ce_reg, pc_reg};

endmodule