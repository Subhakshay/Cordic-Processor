`timescale 1ns / 1ps

module cordic_prerotate #(
    parameter WIDTH = 18
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    en,
    input  wire signed [WIDTH-1:0] angle_in,   
    output reg  signed [WIDTH-1:0] x_init,
    output reg  signed [WIDTH-1:0] y_init,
    output reg  signed [WIDTH-1:0] z_init,
    output reg                     negate_out
);


    localparam signed [WIDTH-1:0] K_INV    = 18'sd19898;

    localparam signed [WIDTH-1:0] PI_HALF  = 18'sd16384;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_init     <= K_INV;
            y_init     <= 0;
            z_init     <= 0;
            negate_out <= 0;
        end else if (en) begin
            if (angle_in > PI_HALF) begin
                x_init     <= 0;
                y_init     <= K_INV;
                z_init     <= angle_in - PI_HALF;
                negate_out <= 0;
            end else if (angle_in < -PI_HALF) begin
                x_init     <= 0;
                y_init     <= -K_INV;
                z_init     <= angle_in + PI_HALF;
                negate_out <= 0;
            end else begin
                x_init     <= K_INV;
                y_init     <= 0;
                z_init     <= angle_in;
                negate_out <= 0;
            end
        end
    end

endmodule
