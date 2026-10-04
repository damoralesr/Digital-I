
module fpga_sumador(
    input  [3:0] A,
    input  [3:0] B,
    input        Ci,

    output [3:0] LED,

    output [7:0] SEG,
    output [3:0] DIG
);

    
	 wire [3:0] So;
    wire Co;

    // ==========================================
    // SUMADOR DE 4 BITS
    // ==========================================

    
	 sumador U1 (
        .A(A),
        .B(B),
        .Ci(Ci),
        .So(So),
        .Co(Co)
    );
	 

    // ==========================================
    // RESULTADO EN LOS 4 LEDs
    // ==========================================

    assign LED = So;
	 
	 

    // ==========================================
    // ACARREO EN DISPLAY DE 7 SEGMENTOS
    // ==========================================

    
	 display7 U2 (
        .Co(~Co),
        .SEG(SEG),
        .DIG(DIG)
    );
endmodule



