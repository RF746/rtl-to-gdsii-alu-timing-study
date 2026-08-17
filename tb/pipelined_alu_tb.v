`timescale 1ns/1ps

module pipelined_alu_tb;
    reg         clk;
    reg         rst_n;
    reg         enable;
    reg         valid_in;
    reg  [31:0] operand_a;
    reg  [31:0] operand_b;
    reg  [2:0]  operation;
    wire [31:0] result;
    wire        zero;
    wire        overflow;
    wire        valid_out;

    reg         expected_valid;
    reg  [31:0] expected_result;
    reg         expected_zero;
    reg         expected_overflow;
    integer     checks;
    integer     failures;
    integer     i;
    reg  [31:0] random_a;
    reg  [31:0] random_b;
    reg  [2:0]  random_op;
    integer     random_seed;
    integer     initial_seed;
    reg  [31:0] stalled_result;
    reg         stalled_zero;
    reg         stalled_overflow;
    reg         stalled_valid;

    pipelined_alu dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .valid_in(valid_in),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .operation(operation),
        .result(result),
        .zero(zero),
        .overflow(overflow),
        .valid_out(valid_out)
    );

    always #5 clk = ~clk;

    function [31:0] reference_result;
        input [31:0] a;
        input [31:0] b;
        input [2:0]  op;
        begin
            case (op)
                3'b000: reference_result = a + b;
                3'b001: reference_result = a - b;
                3'b010: reference_result = a & b;
                3'b011: reference_result = a | b;
                3'b100: reference_result = a ^ b;
                3'b101: reference_result = {31'b0, ($signed(a) < $signed(b))};
                3'b110: reference_result = a << b[4:0];
                3'b111: reference_result = a >> b[4:0];
                default: reference_result = 32'b0;
            endcase
        end
    endfunction

    function reference_overflow;
        input [31:0] a;
        input [31:0] b;
        input [2:0]  op;
        reg   [31:0] value;
        begin
            value = reference_result(a, b, op);
            case (op)
                3'b000: reference_overflow = (a[31] == b[31]) && (value[31] != a[31]);
                3'b001: reference_overflow = (a[31] != b[31]) && (value[31] != a[31]);
                default: reference_overflow = 1'b0;
            endcase
        end
    endfunction

    task apply_vector;
        input [31:0] a;
        input [31:0] b;
        input [2:0]  op;
        input        is_valid;
        begin
            @(negedge clk);
            operand_a = a;
            operand_b = b;
            operation = op;
            valid_in  = is_valid;
        end
    endtask

    // One-entry scoreboard mirrors the stage-1 request register.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            expected_valid    = 1'b0;
            expected_result   = 32'b0;
            expected_zero     = 1'b1;
            expected_overflow = 1'b0;
        end else if (enable) begin
            #1;
            if (valid_out !== expected_valid) begin
                $display("ERROR valid_out: expected=%b actual=%b", expected_valid, valid_out);
                failures = failures + 1;
            end

            if (expected_valid) begin
                checks = checks + 1;
                if (result !== expected_result) begin
                    $display("ERROR result: expected=%h actual=%h", expected_result, result);
                    failures = failures + 1;
                end
                if (zero !== expected_zero) begin
                    $display("ERROR zero: expected=%b actual=%b", expected_zero, zero);
                    failures = failures + 1;
                end
                if (overflow !== expected_overflow) begin
                    $display("ERROR overflow: expected=%b actual=%b", expected_overflow, overflow);
                    failures = failures + 1;
                end
            end

            expected_result   = reference_result(operand_a, operand_b, operation);
            expected_zero     = (reference_result(operand_a, operand_b, operation) == 32'b0);
            expected_overflow = reference_overflow(operand_a, operand_b, operation);
            expected_valid    = valid_in;
        end else begin
            #1;
            if (result !== stalled_result || zero !== stalled_zero ||
                overflow !== stalled_overflow || valid_out !== stalled_valid) begin
                $display("ERROR stall changed outputs: result=%h zero=%b overflow=%b valid=%b",
                         result, zero, overflow, valid_out);
                failures = failures + 1;
            end
        end
    end

    initial begin
        clk         = 1'b0;
        rst_n       = 1'b0;
        enable      = 1'b1;
        valid_in    = 1'b0;
        operand_a   = 32'b0;
        operand_b   = 32'b0;
        operation   = 3'b000;
        checks      = 0;
        failures    = 0;
        initial_seed = 32'h5eed1234;
        random_seed  = initial_seed;

        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        // Directed arithmetic, logic, comparison, shift, zero, and overflow cases.
        apply_vector(32'd1,        32'd2,        3'b000, 1'b1);
        apply_vector(32'd9,        32'd4,        3'b001, 1'b1);
        apply_vector(32'hf0f0f0f0, 32'h0ff00ff0, 3'b010, 1'b1);
        apply_vector(32'hf0000000, 32'h0000000f, 3'b011, 1'b1);
        apply_vector(32'haaaaaaaa, 32'h55555555, 3'b100, 1'b1);
        apply_vector(32'hffffffff, 32'd1,        3'b101, 1'b1);
        apply_vector(32'd1,        32'd12,       3'b110, 1'b1);
        apply_vector(32'h80000000, 32'd31,       3'b111, 1'b1);
        apply_vector(32'd7,        32'd7,        3'b001, 1'b1);
        apply_vector(32'h7fffffff, 32'd1,        3'b000, 1'b1);
        apply_vector(32'h80000000, 32'd1,        3'b001, 1'b1);

        // Capture a valid request, stall both stages for two cycles, and then
        // verify that the held transaction retires in order after resumption.
        apply_vector(32'd10,       32'd20,       3'b000, 1'b1);
        @(negedge clk);
        stalled_result   = result;
        stalled_zero     = zero;
        stalled_overflow = overflow;
        stalled_valid    = valid_out;
        enable           = 1'b0;
        valid_in         = 1'b0;
        operand_a        = 32'hdeadbeef;
        operand_b        = 32'h01234567;
        operation        = 3'b100;
        repeat (2) @(negedge clk);
        enable = 1'b1;

        // Deterministic pseudo-random regression exercises back-to-back traffic.
        $display("INFO: deterministic random seed=%0d", initial_seed);
        for (i = 0; i < 500; i = i + 1) begin
            random_a  = $random(random_seed);
            random_b  = $random(random_seed);
            random_op = $random(random_seed);
            apply_vector(random_a, random_b, random_op, 1'b1);
        end

        // Two bubbles flush the final request and check valid propagation.
        apply_vector(32'b0, 32'b0, 3'b000, 1'b0);
        apply_vector(32'b0, 32'b0, 3'b000, 1'b0);
        @(negedge clk);

        if (failures == 0) begin
            $display("PASS: %0d ALU transactions checked", checks);
            $finish;
        end else begin
            $display("FAIL: %0d failures across %0d checks", failures, checks);
            $fatal(1);
        end
    end

endmodule
