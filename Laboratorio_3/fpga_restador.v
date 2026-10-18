// =====================================================================
// ARCHIVO ÚNICO: fpga_restador.v
// Contiene los módulos nuevos y el top-level.
// Requiere (en archivos aparte, sin modificar):
//   s_1b, sumador, sumador_restador
// =====================================================================
 
 
// ---------------------------------------------------------------------
// detector_signo  (README 4.2)
// signo = 1 solo en resta con acarreo 0 (A < B). La suma nunca es negativa.
// ---------------------------------------------------------------------
module detector_signo(
    input  Sel,
    input  Co,
    output signo
);
    assign signo = Sel & ~Co;
endmodule
 
 
// ---------------------------------------------------------------------
// calc_magnitud  (README 4.3)
//   suma  : R = {Co, So}   (0..30)
//   resta : R = {~Co, So}  (complemento a 2 de 5 bits, -15..15)
//   mag   = signo ? (~R + 1) : R
// ---------------------------------------------------------------------
module calc_magnitud(
    input  [3:0] So,
    input        Co,
    input        Sel,
    input        signo,
    output [4:0] mag
);
    wire [4:0] R;
    assign R   = {(Sel ? ~Co : Co), So};
    assign mag = signo ? (~R + 5'd1) : R;
endmodule
 
 
// ---------------------------------------------------------------------
// bin_a_bcd  (README 4.4)
// mag[4:0] (0..30) -> decenas (0..3) y unidades (0..9)
// ---------------------------------------------------------------------
module bin_a_bcd(
    input      [4:0] mag,
    output reg [3:0] decenas,
    output reg [3:0] unidades
);
    always @(*) begin
        if (mag >= 5'd30) begin
            decenas  = 4'd3;
            unidades = mag - 5'd30;
        end else if (mag >= 5'd20) begin
            decenas  = 4'd2;
            unidades = mag - 5'd20;
        end else if (mag >= 5'd10) begin
            decenas  = 4'd1;
            unidades = mag - 5'd10;
        end else begin
            decenas  = 4'd0;
            unidades = mag[3:0];
        end
    end
endmodule
 
 
// ---------------------------------------------------------------------
// bcd_7seg  (README 4.5)
// Display ÁNODO COMÚN (activo en bajo). SEG = {dp,g,f,e,d,c,b,a}
// Códigos 10..15 (inválidos): todo apagado.
// ---------------------------------------------------------------------
module bcd_7seg(
    input      [3:0] digito,
    output reg [7:0] seg
);
    always @(*) begin
        case (digito)
            4'd0: seg = 8'b11000000;
            4'd1: seg = 8'b11111001;
            4'd2: seg = 8'b10100100;
            4'd3: seg = 8'b10110000;
            4'd4: seg = 8'b10011001;
            4'd5: seg = 8'b10010010;
            4'd6: seg = 8'b10000010;
            4'd7: seg = 8'b11111000;
            4'd8: seg = 8'b10000000;
            4'd9: seg = 8'b10010000;
            default: seg = 8'b11111111;
        endcase
    end
endmodule
 
 
// ---------------------------------------------------------------------
// display_signo  (README 4.6)
// signo=1 -> "-" (solo segmento g) ; signo=0 -> apagado
// ---------------------------------------------------------------------
module display_signo(
    input  signo,
    output [7:0] seg
);
    assign seg = signo ? 8'b10111111 : 8'b11111111;
endmodule
 
 
// ---------------------------------------------------------------------
// mux_display
// DIG1 = unidades | DIG2 = decenas | DIG3 = signo | DIG4 = apagado
// DIG activo en bajo. Con clk de 50 MHz y cnt[16:15]: ~380 Hz por dígito.
// ---------------------------------------------------------------------
module mux_display(
    input        clk,
    input  [7:0] seg_uni,
    input  [7:0] seg_dec,
    input  [7:0] seg_sig,
    output reg [7:0] SEG,
    output reg [3:0] DIG
);
    reg [16:0] cnt = 17'd0;
 
    always @(posedge clk)
        cnt <= cnt + 1'b1;
 
    always @(*) begin
        case (cnt[16:15])
            2'b00: begin DIG = 4'b1110; SEG = seg_uni; end
            2'b01: begin DIG = 4'b1101; SEG = seg_dec; end
            2'b10: begin DIG = 4'b1011; SEG = seg_sig; end
            default: begin DIG = 4'b1111; SEG = 8'b11111111; end
        endcase
    end
endmodule
 
 
// =====================================================================
// fpga_restador  (top-level)
//   clk       : reloj de la tarjeta (50 MHz)
//   A, B, Op : interruptores (se conserva el ~B del código original)
//   SEG/DIG   : DIG1 = unidades, DIG2 = decenas, DIG3 = signo
// =====================================================================
module fpga_restador(
    input        clk,
    input  [3:0] A,
    input  [3:0] B,
    input        Op,
 
    output [7:0] SEG,
    output [3:0] DIG
);
 
    wire [3:0] So;
    wire       Co;
    wire       signo;
    wire [4:0] mag;
    wire [3:0] decenas, unidades;
    wire [7:0] seg_uni, seg_dec, seg_sig;
 
    // 1) Sumador / Restador (módulo existente)
    // Polaridad de entradas: 1 = el interruptor es de lógica negativa
    // (se invierte), 0 = lógica positiva. B y Op DEBEN tener la misma
    // polaridad; si no, la resta suma un "+1" de más.
    localparam INV_A   = 1'b1;
    localparam INV_B   = 1'b1;
    localparam INV_SEL = 1'b0;
 
    wire [3:0] A_in   = A   ^ {4{INV_A}};
    wire [3:0] B_in   = B   ^ {4{INV_B}};
    wire       Op_in = ~Op ^ INV_SEL;
 
    sumador_restador U1 (
        .A(A_in),
        .B(B_in),
        .Sel(Op_in),
        .So(So),
        .Co(Co)
    );
 
    // 2) Detector de signo
    detector_signo U2 (.Sel(Op_in), .Co(Co), .signo(signo));
 
    // 3) Magnitud
    calc_magnitud U3 (.So(So), .Co(Co), .Sel(Op_in), .signo(signo), .mag(mag));
 
    // 4) Binario -> BCD
    bin_a_bcd U4 (.mag(mag), .decenas(decenas), .unidades(unidades));
 
    // 5) BCD -> 7 segmentos y signo
    bcd_7seg      U5_uni (.digito(unidades), .seg(seg_uni));
    bcd_7seg      U5_dec (.digito(decenas),  .seg(seg_dec));
    display_signo U6     (.signo(signo),      .seg(seg_sig));
 
    // 6) Multiplexado de los dígitos
    mux_display U7 (
        .clk(clk),
        .seg_uni(seg_uni),
        .seg_dec(seg_dec),
        .seg_sig(seg_sig),
        .SEG(SEG),
        .DIG(DIG)
    );
 
endmodule
