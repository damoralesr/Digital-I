// =====================================================================
// MÓDULO: control_caldera
// ---------------------------------------------------------------------
// Compara la temperatura T con el nivel/valor objetivo L (4 bits cada
// uno) restándolos (T - L) con el sumador_restador, e indica el estado
// con tres LEDs (activos en bajo: el LED se enciende con 0):
//   PROCESS_LED : se enciende si T <  L  (proceso en curso, falta calentar)
//   PERFECT_LED : se enciende si T == L  (punto perfecto)
//   BURN_LED    : se enciende si T >  L  (sobrecalentamiento)L.
// Lógica interna:
//   Co = 1 -> T >= L ;  So_cero = 1 -> resultado de la resta es 0
//   PROCESS_LED = Co
//   PERFECT_LED = ~(Co & So_cero)      -> T == L
//   BURN_LED    = ~(Co & ~So_cero)     -> T >  L
// =====================================================================
module control_caldera(
    input  [3:0] T,
    input  [3:0] L,
    input        Sel,
    output       PERFECT_LED,
    output       PROCESS_LED,
    output       BURN_LED
);
    wire [3:0] So;
    wire       Co;

    
    sumador_restador U_RESTA (
        .A(~T),
        .B(~L),
        .Sel(~Sel),
        .So(So),
        .Co(Co)
    );

    
    wire So_cero = ~(So[0] | So[1] | So[2] | So[3]);

	 assign PROCESS_LED = Co;            
	 assign PERFECT_LED = ~(Co & So_cero);
	 assign BURN_LED    = ~(Co & ~So_cero);
endmodule
