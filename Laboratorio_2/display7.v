// =====================================================================
// MÓDULO: display7  (manejador del display de 7 segmentos)
// ---------------------------------------------------------------------
// Muestra un solo dígito (0 ó 1) en el dígito DIG1 del display según Co.
//   DIG = 4'b1110 -> habilita solo el primer dígito (activo en bajo).
//   SEG = 8'b11000000 -> dibuja "0"   (segmentos activos en bajo)
//   SEG = 8'b11111001 -> dibuja "1"
// Orden de SEG: {dp,g,f,e,d,c,b,a}
// =====================================================================
module display7(
    input  Co,
    output reg [7:0] SEG,
    output reg [3:0] DIG
);

    always @(*) begin

        // Activar DIG1
        DIG = 4'b1110;

        if (Co == 1'b0)
            // Mostrar 0
            SEG = 8'b11000000;
        else
            // Mostrar 1
            SEG = 8'b11111001;

    end

endmodule