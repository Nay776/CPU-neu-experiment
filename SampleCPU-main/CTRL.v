`include "lib/defines.vh"

module CTRL(
    input wire rst,
    input wire stallreq_from_ex,
    input wire stallreq_from_id,

    output reg [`StallBus-1:0] stall
);  

    // Pipeline stall control:
    // stall[0]: Reserved (not used)
    // stall[1]: IF stage stall when set to 1
    // stall[2]: ID stage stall when set to 1
    // stall[3]: EX stage stall when set to 1
    // stall[4]: MEM stage stall when set to 1
    // stall[5]: WB stage stall when set to 1
    
    always @ (*) begin
        if (rst) begin
            stall <= `StallBus'b0;
        end
        else if (stallreq_from_ex == 1'b1) begin
            // Stall IF, ID, EX stages
            stall <= 6'b001111;
        end
        else if (stallreq_from_id == 1'b1) begin
            // Stall IF, ID stages
            stall <= 6'b000111;
        end 
        else begin 
            stall <= 6'b000000;
        end
    end
    
endmodule