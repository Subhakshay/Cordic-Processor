`timescale 1ns / 1ps

module cordic_stage #(
    parameter WIDTH = 18,
    parameter STAGE = 0
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    en,
    input  wire signed [WIDTH-1:0] x_in,
    input  wire signed [WIDTH-1:0] y_in,
    input  wire signed [WIDTH-1:0] z_in,
    output reg  signed [WIDTH-1:0] x_out,
    output reg  signed [WIDTH-1:0] y_out,
    output reg  signed [WIDTH-1:0] z_out
);
    function [17:0] atan_val;
        input integer s;
        begin
            case (s)
                0:  atan_val = 18'd8192;
                1:  atan_val = 18'd4836;
                2:  atan_val = 18'd2555;
                3:  atan_val = 18'd1297;
                4:  atan_val = 18'd651;
                5:  atan_val = 18'd326;
                6:  atan_val = 18'd163;
                7:  atan_val = 18'd81;
                8:  atan_val = 18'd41;
                9:  atan_val = 18'd20;
                10: atan_val = 18'd10;
                11: atan_val = 18'd5;
                12: atan_val = 18'd3;
                13: atan_val = 18'd1;
                14: atan_val = 18'd1;
                15: atan_val = 18'd0;
                default: atan_val = 18'd0;
            endcase
        end
    endfunction

    localparam [WIDTH-1:0] ATAN = atan_val(STAGE);

    wire di = ~z_in[WIDTH-1];  

    wire signed [WIDTH-1:0] x_shift = x_in >>> STAGE;
    wire signed [WIDTH-1:0] y_shift = y_in >>> STAGE;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_out <= 0; y_out <= 0; z_out <= 0;
        end else if (en) begin
            if (di) begin
                x_out <= x_in - y_shift;
                y_out <= y_in + x_shift;
                z_out <= z_in - $signed(ATAN);
            end else begin
                x_out <= x_in + y_shift;
                y_out <= y_in - x_shift;
                z_out <= z_in + $signed(ATAN);
            end
        end
    end

endmodule
