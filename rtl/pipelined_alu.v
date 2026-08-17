`timescale 1ns/1ps

// Public portfolio implementation of a two-stage, 32-bit pipelined ALU.
// Stage 1 captures the request. Stage 2 registers the computed response.
module pipelined_alu (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire        valid_in,
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [2:0]  operation,
    output reg  [31:0] result,
    output reg         zero,
    output reg         overflow,
    output reg         valid_out
);

    localparam [2:0] OP_ADD = 3'b000;
    localparam [2:0] OP_SUB = 3'b001;
    localparam [2:0] OP_AND = 3'b010;
    localparam [2:0] OP_OR  = 3'b011;
    localparam [2:0] OP_XOR = 3'b100;
    localparam [2:0] OP_SLT = 3'b101;
    localparam [2:0] OP_SLL = 3'b110;
    localparam [2:0] OP_SRL = 3'b111;

    reg [31:0] operand_a_s1;
    reg [31:0] operand_b_s1;
    reg [2:0]  operation_s1;
    reg        valid_s1;

    reg [31:0] result_s1;
    reg        overflow_s1;

    always @* begin
        result_s1   = 32'b0;
        overflow_s1 = 1'b0;

        case (operation_s1)
            OP_ADD: begin
                result_s1 = operand_a_s1 + operand_b_s1;
                overflow_s1 = (operand_a_s1[31] == operand_b_s1[31]) &&
                              (result_s1[31] != operand_a_s1[31]);
            end
            OP_SUB: begin
                result_s1 = operand_a_s1 - operand_b_s1;
                overflow_s1 = (operand_a_s1[31] != operand_b_s1[31]) &&
                              (result_s1[31] != operand_a_s1[31]);
            end
            OP_AND: result_s1 = operand_a_s1 & operand_b_s1;
            OP_OR:  result_s1 = operand_a_s1 | operand_b_s1;
            OP_XOR: result_s1 = operand_a_s1 ^ operand_b_s1;
            OP_SLT: result_s1 = {31'b0, ($signed(operand_a_s1) < $signed(operand_b_s1))};
            OP_SLL: result_s1 = operand_a_s1 << operand_b_s1[4:0];
            OP_SRL: result_s1 = operand_a_s1 >> operand_b_s1[4:0];
            default: begin
                result_s1   = 32'b0;
                overflow_s1 = 1'b0;
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            operand_a_s1 <= 32'b0;
            operand_b_s1 <= 32'b0;
            operation_s1 <= OP_ADD;
            valid_s1     <= 1'b0;
            result        <= 32'b0;
            zero          <= 1'b1;
            overflow      <= 1'b0;
            valid_out     <= 1'b0;
        end else if (enable) begin
            operand_a_s1 <= operand_a;
            operand_b_s1 <= operand_b;
            operation_s1 <= operation;
            valid_s1     <= valid_in;

            result    <= result_s1;
            zero      <= (result_s1 == 32'b0);
            overflow  <= overflow_s1;
            valid_out <= valid_s1;
        end
    end

endmodule
