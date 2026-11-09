module top_teclado (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] cols,
    output wire [3:0] rows,
    output wire [3:0] leds,
    output wire       key_valid
);

    // 1. AQUÍ DECLARAMOS EL CABLE (esto faltaba)
    wire [3:0] w_key_code; 

    teclado_matricial #(
        .CLK_FREQ(50_000_000)
    ) controlador_teclado (
        .clk      (clk),
        .rst      (~rst),
        .cols     (cols),
        .rows     (rows),
        .key_code (w_key_code), // 2. CONECTAMOS EL CABLE AQUÍ EN VEZ DE 'leds'
        .key_valid(key_valid)
    );
    
    // 3. SE INVIERTE LA SEÑAL PARA LOS LEDS
    assign leds = ~w_key_code;
	
	endmodule