// ================================================================================
// Pipeline Bus Width Definitions
// ================================================================================
`define IF_TO_ID_WD      33      // IF to ID stage bus width
`define ID_TO_EX_WD      169     // ID to EX stage bus width
`define EX_TO_MEM_WD     80      // EX to MEM stage bus width
`define MEM_TO_WB_WD     70      // MEM to WB stage bus width
`define BR_WD            33      // Branch bus width
`define DATA_SRAM_WD     69      // Data SRAM bus width
`define WB_TO_RF_WD      38      // WB to Register File bus width

// ================================================================================
// Pipeline Control Definitions
// ================================================================================
`define StallBus         6       // Stall bus width
`define NoStop           1'b0    // Pipeline stage no stall
`define Stop             1'b1    // Pipeline stage stall

// ================================================================================
// Common Definitions
// ================================================================================
`define ZeroWord         32'b0   // 32-bit zero constant

// ================================================================================
// Division Unit Definitions
// ================================================================================
`define DivFree          2'b00   // Division unit is free
`define DivByZero        2'b01   // Division by zero detected
`define DivOn            2'b10   // Division in progress
`define DivEnd           2'b11   // Division completed
`define DivResultReady   1'b1    // Division result ready
`define DivResultNotReady 1'b0   // Division result not ready
`define DivStart         1'b1    // Start division
`define DivStop          1'b0    // Stop division

// ================================================================================
// Multiplication Unit Definitions
// ================================================================================
`define MulFree          2'b00   // Multiplication unit is free
`define MulOn            2'b10   // Multiplication in progress
`define MulEnd           2'b11   // Multiplication completed
`define MulResultReady   1'b1    // Multiplication result ready
`define MulResultNotReady 1'b0   // Multiplication result not ready
`define MulStart         1'b1    // Start multiplication
`define MulStop          1'b0    // Stop multiplication