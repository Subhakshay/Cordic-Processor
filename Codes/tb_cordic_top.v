`timescale 1ns / 1ps

// tb_cordic_top.v - corrected Q1.15 angle encoding
`timescale 1ns / 1ps

module tb_cordic_top;

    parameter WIDTH      = 18;
    parameter STAGES     = 16;
    parameter CLK_PERIOD = 10;

    reg                     clk, rst_n, valid_in;
    reg  signed [WIDTH-1:0] angle_in;
    wire signed [WIDTH-1:0] cos_out, sin_out;
    wire                    valid_out;

    cordic_top #(.WIDTH(WIDTH), .STAGES(STAGES)) dut (
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in),
        .angle_in(angle_in), .cos_out(cos_out),
        .sin_out(sin_out), .valid_out(valid_out)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    reg signed [WIDTH-1:0] test_angles [0:7];
    reg signed [WIDTH-1:0] exp_cos     [0:7];
    reg signed [WIDTH-1:0] exp_sin     [0:7];

    integer i, recv_idx, pass_count, fail_count;
    integer cos_err, sin_err;

    // Tolerance: 200 LSB = ~0.006 absolute error (acceptable for 16-stage)
    integer TOLERANCE;
    initial TOLERANCE = 200;

    task check_output;
        input signed [WIDTH-1:0] got_cos, got_sin;
        input signed [WIDTH-1:0] want_cos, want_sin;
        input integer            idx;
        begin
            cos_err = got_cos - want_cos;
            sin_err = got_sin - want_sin;
            if (cos_err < 0) cos_err = -cos_err;
            if (sin_err < 0) sin_err = -sin_err;

            $display("--------------------------------------");
            $display("Test[%0d]", idx);
            $display("  cos: got=%0d  exp=%0d  err=%0d", got_cos, want_cos, cos_err);
            $display("  sin: got=%0d  exp=%0d  err=%0d", got_sin, want_sin, sin_err);

            if (cos_err <= TOLERANCE && sin_err <= TOLERANCE) begin
                $display("  >>> PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("  >>> FAIL (tol=%0d)", TOLERANCE);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        // =====================================================
        // ANGLE ENCODING - Q1.15 scale where pi = 32768
        // angle_in = round(angle_radians * 32768 / pi)
        //          = round(angle_degrees * 32768 / 180)
        //
        //  0   deg ->      0
        //  22.5 deg ->   4096   (pi/8)
        //  30  deg ->   5461   (pi/6)
        //  45  deg ->   8192   (pi/4)
        //  60  deg ->  10923   (pi/3)
        //  90  deg ->  16384   (pi/2)
        // -45  deg ->  -8192
        // -90  deg -> -16384
        // =====================================================
        test_angles[0] =  18'sd0;
        test_angles[1] =  18'sd4096;    //  pi/8  = 22.5 deg
        test_angles[2] =  18'sd5461;    //  pi/6  = 30   deg
        test_angles[3] =  18'sd8192;    //  pi/4  = 45   deg
        test_angles[4] =  18'sd10923;   //  pi/3  = 60   deg
        test_angles[5] =  18'sd16384;   //  pi/2  = 90   deg
        test_angles[6] = -18'sd8192;    // -pi/4  = -45  deg
        test_angles[7] = -18'sd16384;   // -pi/2  = -90  deg

        // =====================================================
        // EXPECTED VALUES - Q2.15 output scale (* 32768)
        // cos(0)    = 1.0000 -> 32768
        // cos(pi/8) = 0.9239 -> 30274
        // cos(pi/6) = 0.8660 -> 28378
        // cos(pi/4) = 0.7071 -> 23170
        // cos(pi/3) = 0.5000 -> 16384
        // cos(pi/2) = 0.0000 ->     0
        // cos(-pi/4)= 0.7071 -> 23170
        // cos(-pi/2)= 0.0000 ->     0
        // =====================================================
        exp_cos[0] =  18'sd32768;
        exp_cos[1] =  18'sd30274;
        exp_cos[2] =  18'sd28378;
        exp_cos[3] =  18'sd23170;
        exp_cos[4] =  18'sd16384;
        exp_cos[5] =  18'sd0;
        exp_cos[6] =  18'sd23170;
        exp_cos[7] =  18'sd0;

        // sin(0)    = 0.0000 ->     0
        // sin(pi/8) = 0.3827 -> 12540
        // sin(pi/6) = 0.5000 -> 16384
        // sin(pi/4) = 0.7071 -> 23170
        // sin(pi/3) = 0.8660 -> 28378
        // sin(pi/2) = 1.0000 -> 32767
        // sin(-pi/4)=-0.7071 ->-23170
        // sin(-pi/2)=-1.0000 ->-32768
        exp_sin[0] =  18'sd0;
        exp_sin[1] =  18'sd12540;
        exp_sin[2] =  18'sd16384;
        exp_sin[3] =  18'sd23170;
        exp_sin[4] =  18'sd28378;
        exp_sin[5] =  18'sd32767;
        exp_sin[6] = -18'sd23170;
        exp_sin[7] = -18'sd32768;

        pass_count = 0;
        fail_count = 0;
        recv_idx   = 0;

        // Reset sequence
        rst_n = 0; valid_in = 0; angle_in = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        // Send all 8 angles back-to-back
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            angle_in = test_angles[i];
            valid_in = 1;
        end
        @(posedge clk);
        valid_in = 0;
        angle_in = 0;

        // Wait for pipeline to drain
        repeat(STAGES + 10) @(posedge clk);

        $display("==========================================");
        $display("  CORDIC SIMULATION SUMMARY");
        $display("  PASS : %0d / 8", pass_count);
        $display("  FAIL : %0d / 8", fail_count);
        $display("  Latency    : %0d cycles (%0d ns)",
                  STAGES+1, (STAGES+1)*CLK_PERIOD);
        $display("  Throughput : 1 result / cycle @ 100 MHz");
        $display("==========================================");
        $finish;
    end

    always @(posedge clk) begin
        if (valid_out && recv_idx < 8) begin
            check_output(cos_out, sin_out,
                         exp_cos[recv_idx], exp_sin[recv_idx],
                         recv_idx);
            recv_idx = recv_idx + 1;
        end
    end

    initial begin
        $dumpfile("cordic_wave.vcd");
        $dumpvars(0, tb_cordic_top);
    end

endmodule