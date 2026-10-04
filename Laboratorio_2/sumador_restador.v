// =====================================================================
// MÓDULO: sumador_restador  (suma o resta de 4 bits)
// ---------------------------------------------------------------------
// Sel = 0 -> So = A + B
// Sel = 1 -> So = A - B   (complemento a 2: A + ~B + 1)
// Cada bit de B se pasa por una XOR con Sel: con Sel=1 se invierte B
// (complemento a 1) y Sel entra además como acarreo inicial (+1),
// con lo que se obtiene el complemento a 2.
// Co: acarreo de salida. En resta, Co=1 significa A >= B (no hay
// préstamo); Co=0 significa A < B.
// =====================================================================
module sumador_restador(
    input  [3:0] A,
    input  [3:0] B,
    input        Sel,
    output [3:0] So,
    output       Co
);
    wire [3:0] B_xor;

    // Paso 1: complemento a 1 de B cuando Sel = 1
    assign B_xor[0] = B[0] ^ Sel;
    assign B_xor[1] = B[1] ^ Sel;
    assign B_xor[2] = B[2] ^ Sel;
    assign B_xor[3] = B[3] ^ Sel;

    // Paso 2: Sel como acarreo inicial (+1) -> complemento a 2
    sumador U_SUM (
        .A(A),
        .B(B_xor),
        .Ci(Sel),
        .So(So),
        .Co(Co)
    );
endmodule