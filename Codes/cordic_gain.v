`timescale 1ns / 1ps



module cordic_gain #(
    parameter WIDTH = 18
)(
    input  wire signed [WIDTH-1:0] x_in,
    input  wire signed [WIDTH-1:0] y_in,
    output wire signed [WIDTH-1:0] x_out,
    output wire signed [WIDTH-1:0] y_out
);
    localparam signed [WIDTH-1:0] K_INV = 18'sd19898; 

    wire signed [35:0] x_full = x_in * K_INV;
    wire signed [35:0] y_full = y_in * K_INV;

    assign x_out = x_full[WIDTH+14:15];
    assign y_out = y_full[WIDTH+14:15];

endmodule