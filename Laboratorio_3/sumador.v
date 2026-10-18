// =====================================================================
// Módulo: sumador  (sumador de 4 bits, diseño estructural)
// Une 4 sumadores de 1 bit en cadena: el acarreo de salida de cada
// etapa es el acarreo de entrada de la siguiente (ripple-carry).
// Entradas : A[3:0], B[3:0], Ci (acarreo de entrada)
// Salidas  : So[3:0] (suma), Co (acarreo final)
// =====================================================================
module sumador(
    input  [3:0] A,
    input  [3:0] B,
    input        Ci,
    output [3:0] So,
    output       Co
);
    // Cables internos que llevan el acarreo de una etapa a la siguiente.
    // c0: sale del bit 0 y entra al bit 1, y así sucesivamente.
    wire c0, c1, c2;

    // Bit 0 (menos significativo): recibe el acarreo de entrada externo Ci.
    s_1b bit0(.A(A[0]), .B(B[0]), .Ci(Ci), .So(So[0]), .Co(c0));

    // Bit 1: su acarreo de entrada es el acarreo de salida del bit 0.
    s_1b bit1(.A(A[1]), .B(B[1]), .Ci(c0), .So(So[1]), .Co(c1));

    // Bit 2: su acarreo de entrada es el acarreo de salida del bit 1.
    s_1b bit2(.A(A[2]), .B(B[2]), .Ci(c1), .So(So[2]), .Co(c2));

    // Bit 3 (más significativo): su acarreo de salida es el acarreo final Co.
    s_1b bit3(.A(A[3]), .B(B[3]), .Ci(c2), .So(So[3]), .Co(Co));
endmodule