// MÓDULO: fpga_restador  (top-level suma/resta para la tarjeta FPGA)
// ---------------------------------------------------------------------
//   - A, B, Sel : interruptores (lógica negativa)
//   - LED[3:0]  : resultado de la operación
//   - SEG/DIG   : acarreo/no-préstamo en el display (0 ó 1)
// =====================================================================
module fpga_restador(
    input  [3:0] A,
    input  [3:0] B,
    input        Sel,

    output [3:0] LED,

    output [7:0] SEG,
    output [3:0] DIG
);

    wire [3:0] So;
    wire Co;

    sumador_restador U1 (
        .A(A),
        .B(~B),
        .Sel(Sel),
        .So(So),
        .Co(Co)
    );

    // Resultado en los 4 LEDs
    assign LED = So;

    // Acarreo en el display de 7 segmentos
    
	 display7 U2 (
        .Co(~Co),
        .SEG(SEG),
        .DIG(DIG)
    );
	 
endmodule
