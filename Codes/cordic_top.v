`timescale 1ns / 1ps


module cordic_top #(
    parameter WIDTH  = 18,
    parameter STAGES = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  valid_in,       
    input  wire signed [WIDTH-1:0] angle_in,    

    output reg  signed [WIDTH-1:0] cos_out,    
    output reg  signed [WIDTH-1:0] sin_out,    
    output reg                     valid_out    
);


    wire signed [WIDTH-1:0] x_pipe [0:STAGES];
    wire signed [WIDTH-1:0] y_pipe [0:STAGES];
    wire signed [WIDTH-1:0] z_pipe [0:STAGES];


    wire signed [WIDTH-1:0] x_init_w, y_init_w, z_init_w;
    wire                     negate_w;


    reg [STAGES:0] valid_pipe;


    cordic_prerotate #(.WIDTH(WIDTH)) u_prerotate (
        .clk       (clk),
        .rst_n     (rst_n),
        .en        (1'b1),
        .angle_in  (angle_in),
        .x_init    (x_init_w),
        .y_init    (y_init_w),
        .z_init    (z_init_w),
        .negate_out(negate_w)
    );

    assign x_pipe[0] = x_init_w;
    assign y_pipe[0] = y_init_w;
    assign z_pipe[0] = z_init_w;


    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : stage_gen
            cordic_stage #(
                .WIDTH(WIDTH),
                .STAGE(i)
            ) u_stage (
                .clk   (clk),
                .rst_n (rst_n),
                .en    (1'b1),
                .x_in  (x_pipe[i]),
                .y_in  (y_pipe[i]),
                .z_in  (z_pipe[i]),
                .x_out (x_pipe[i+1]),
                .y_out (y_pipe[i+1]),
                .z_out (z_pipe[i+1])
            );
        end
    endgenerate


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_pipe <= 0;
        else
            valid_pipe <= {valid_pipe[STAGES-1:0], valid_in};
    end


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cos_out   <= 0;
            sin_out   <= 0;
            valid_out <= 0;
        end else begin
            cos_out   <= x_pipe[STAGES];
            sin_out   <= y_pipe[STAGES];
            valid_out <= valid_pipe[STAGES];
        end
    end

endmodule