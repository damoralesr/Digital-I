module top_teclado (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] cols,
    output wire [3:0] rows,
    output wire [3:0] leds,
    output wire       key_valid
);

    teclado_matricial #(
        .CLK_FREQ(50_000_000)
    ) controlador_teclado (
        .clk      (clk),
        .rst      (rst),
        .cols     (cols),
        .rows     (rows),
        .key_code (leds),
        .key_valid(key_valid)
    );

endmodule
