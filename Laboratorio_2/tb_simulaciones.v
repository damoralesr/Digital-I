`timescale 1ns/1ps
// =====================================================================
// TESTBENCHES con tablas de verdad impresas en la terminal
// Cada módulo tb_* es independiente. Elige uno como top al simular:
//   iverilog -s tb_sumador -o sim_sumador *.v
//   vvp sim_sumador
// El parámetro MOSTRAR = 1 imprime la tabla completa; con 0 solo
// imprime errores y el resultado final (PASS / FALLO).
// =====================================================================


// ---------------------------------------------------------------------
// tb_s_1b : sumador completo de 1 bit (8 combinaciones)
// ---------------------------------------------------------------------
module tb_s_1b;
    parameter MOSTRAR = 1;

    reg  A, B, Ci;
    wire So, Co;
    reg  [1:0] esperado;
    integer i, errores;

    s_1b dut(.A(A), .B(B), .Ci(Ci), .So(So), .Co(Co));

    initial begin
        $dumpfile("tb_s_1b.vcd");
        $dumpvars(0, tb_s_1b);
        errores = 0;

        if (MOSTRAR) begin
            $display("");
            $display("=== TABLA DE VERDAD: SUMADOR COMPLETO DE 1 BIT ===");
            $display(" A | B | Ci || Co | So || Esp(Co So) | Estado");
            $display("---+---+----++----+----++------------+-------");
        end

        for (i = 0; i < 8; i = i + 1) begin
            {A, B, Ci} = i[2:0];
            #10;
            esperado = A + B + Ci;
            if ({Co, So} !== esperado) errores = errores + 1;
            if (MOSTRAR || ({Co, So} !== esperado))
                $display(" %b | %b |  %b ||  %b |  %b ||     %b%b     | %s",
                         A, B, Ci, Co, So, esperado[1], esperado[0],
                         ({Co, So} === esperado) ? "OK   " : "ERROR");
        end

        $display("");
        if (errores == 0) $display("tb_s_1b: PASS (8/8)");
        else              $display("tb_s_1b: FALLO, %0d errores", errores);
        $finish;
    end
endmodule


// ---------------------------------------------------------------------
// tb_sumador : sumador de 4 bits (512 combinaciones)
// ---------------------------------------------------------------------
module tb_sumador;
    parameter MOSTRAR = 1;

    reg  [3:0] A, B;
    reg        Ci;
    wire [3:0] So;
    wire       Co;
    reg  [4:0] esperado;
    integer i, j, k, errores;

    sumador dut(.A(A), .B(B), .Ci(Ci), .So(So), .Co(Co));

    initial begin
        $dumpfile("tb_sumador.vcd");
        $dumpvars(0, tb_sumador);
        errores = 0;

        if (MOSTRAR) begin
            $display("");
            $display("=== TABLA DE VERDAD: SUMADOR DE 4 BITS  (A + B + Ci) ===");
            $display("   A (dec bin)   |   B (dec bin)   | Ci || Co | So (bin) | Suma dec | Esp dec | Estado");
            $display("-----------------+-----------------+----++----+----------+----------+---------+-------");
        end

        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1)
                for (k = 0; k < 2; k = k + 1) begin
                    A = i; B = j; Ci = k;
                    #10;
                    esperado = A + B + Ci;
                    if ({Co, So} !== esperado) errores = errores + 1;
                    if (MOSTRAR || ({Co, So} !== esperado))
                        $display("  %2d  (%b)   |  %2d  (%b)   |  %b ||  %b |   %b   |    %2d    |   %2d    | %s",
                                 A, A, B, B, Ci, Co, So, {Co, So}, esperado,
                                 ({Co, So} === esperado) ? "OK   " : "ERROR");
                end

        $display("");
        if (errores == 0) $display("tb_sumador: PASS (512/512)");
        else              $display("tb_sumador: FALLO, %0d errores", errores);
        $finish;
    end
endmodule


// ---------------------------------------------------------------------
// tb_display7 : display de 7 segmentos
// ---------------------------------------------------------------------
module tb_display7;
    parameter MOSTRAR = 1;

    reg        Co;
    wire [7:0] SEG;
    wire [3:0] DIG;
    reg  [7:0] seg_esp;
    integer i, errores;

    display7 dut(.Co(Co), .SEG(SEG), .DIG(DIG));

    initial begin
        $dumpfile("tb_display7.vcd");
        $dumpvars(0, tb_display7);
        errores = 0;

        if (MOSTRAR) begin
            $display("");
            $display("=== TABLA DE VERDAD: DISPLAY DE 7 SEGMENTOS ===");
            $display(" Co || SEG {dp,g,f,e,d,c,b,a} | DIG  | Muestra | Estado");
            $display("----++-------------------------+------+---------+-------");
        end

        for (i = 0; i < 2; i = i + 1) begin
            Co = i;
            #10;
            seg_esp = Co ? 8'b11111001 : 8'b11000000;
            if (SEG !== seg_esp || DIG !== 4'b1110) errores = errores + 1;
            if (MOSTRAR || SEG !== seg_esp || DIG !== 4'b1110)
                $display("  %b ||        %b         | %b |    %s    | %s",
                         Co, SEG, DIG, (SEG === 8'b11000000) ? "0" : (SEG === 8'b11111001) ? "1" : "?",
                         (SEG === seg_esp && DIG === 4'b1110) ? "OK   " : "ERROR");
        end

        $display("");
        if (errores == 0) $display("tb_display7: PASS");
        else              $display("tb_display7: FALLO, %0d errores", errores);
        $finish;
    end
endmodule


// ---------------------------------------------------------------------
// tb_fpga_sumador : top-level del sumador con lógica negativa
// Se muestran los valores en los PINES (invertidos) y los valores
// REALES (lo que el usuario quiere sumar).
// ---------------------------------------------------------------------
module tb_fpga_sumador;
    parameter MOSTRAR = 1;

    reg  [3:0] A, B;
    reg        Ci;
    wire [3:0] LED;
    wire [7:0] SEG;
    wire [3:0] DIG;
    reg  [3:0] a, b;
    reg        ci;
    reg  [4:0] esperado;
    reg  [7:0] seg_esp;
    reg        ok;
    integer i, j, k, errores;

    fpga_sumador dut(.A(A), .B(B), .Ci(Ci), .LED(LED), .SEG(SEG), .DIG(DIG));

    initial begin
        $dumpfile("tb_fpga_sumador.vcd");
        $dumpvars(0, tb_fpga_sumador);
        errores = 0;

        if (MOSTRAR) begin
            $display("");
            $display("=== TABLA DE VERDAD: FPGA SUMADOR (lógica negativa) ===");
            $display("   PINES (A B Ci)    |  REALES a + b + ci  | LED (pin) | Carry display | Esp dec | Estado");
            $display("---------------------+---------------------+-----------+---------------+---------+-------");
        end

        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1)
                for (k = 0; k < 2; k = k + 1) begin
                    a = i; b = j; ci = k;           // valores reales
                    A = ~a; B = ~b; Ci = ~ci;       // pines (lógica negativa)
                    #10;
                    esperado = a + b + ci;
                    seg_esp  = esperado[4] ? 8'b11111001 : 8'b11000000;
                    ok = (LED === ~esperado[3:0]) && (SEG === seg_esp) && (DIG === 4'b1110);
                    if (!ok) errores = errores + 1;
                    if (MOSTRAR || !ok)
                        $display("  %b %b %b  |  %2d + %2d + %b = %2d  |   %b    |       %s       |   %2d    | %s",
                                 A, B, Ci, a, b, ci, esperado, LED,
                                 (SEG === 8'b11000000) ? "0" : (SEG === 8'b11111001) ? "1" : "?",
                                 esperado,
                                 ok ? "OK   " : "ERROR");
                end

        $display("");
        if (errores == 0) $display("tb_fpga_sumador: PASS (512/512)");
        else              $display("tb_fpga_sumador: FALLO, %0d errores", errores);
        $finish;
    end
endmodule


// ---------------------------------------------------------------------
// tb_sumador_restador : Sel=0 -> A+B ; Sel=1 -> A-B
// ---------------------------------------------------------------------
module tb_sumador_restador;
    reg  [3:0] A, B;
    reg        Sel;
    wire [3:0] So;
    wire       Co;
    reg  [4:0] esperado;
    reg        ok;
    integer i, j, k, errores;

    sumador_restador dut(.A(A), .B(B), .Sel(Sel), .So(So), .Co(Co));

    // Calcula el resultado esperado y verifica
    task verificar;
        begin
            if (Sel) esperado = {1'b0, A} + {1'b0, ~B} + 5'd1;   // A - B
            else     esperado = {1'b0, A} + {1'b0, B};           // A + B
            ok = ({Co, So} === esperado);
            if (Sel && (Co !== (A >= B))) ok = 0;
            if (!ok) errores = errores + 1;
        end
    endtask

    // Caso para la tabla corta: aplica, verifica e imprime
    task caso(input [3:0] a, input [3:0] b, input s);
        begin
            A = a; B = b; Sel = s;
            #10;
            verificar;
            $display("  %b  | %s |  %2d (%b) |  %2d (%b) ||  %b |  %2d (%b)  | %s | %s",
                     Sel, Sel ? "A-B" : "A+B", A, A, B, B, Co, So, So,
                     Sel ? (Co ? "sin prestamo" : "con prestamo")
                         : (Co ? "con acarreo " : "sin acarreo "),
                     ok ? "OK   " : "ERROR");
        end
    endtask

    initial begin
        $dumpfile("tb_sumador_restador.vcd");
        $dumpvars(0, tb_sumador_restador);
        errores = 0;

        $display("");
        $display("=== TABLA DE VERDAD CORTA: SUMADOR / RESTADOR DE 4 BITS ===");
        $display(" Sel | Op  |   A (dec bin)  |   B (dec bin)  || Co |  So (dec bin) | Nota         | Estado");
        $display("-----+-----+----------------+----------------++----+---------------+--------------+-------");

        // ----- SUMA (Sel = 0) -----
        //     A   B  Sel
        caso( 3,  2, 0);   // suma simple
        caso( 7,  1, 0);   // acarreo interno
        caso( 8,  8, 0);   // acarreo final (Co = 1)
        caso(15,  1, 0);   // desbordamiento
        caso(15, 15, 0);   // máximo
        $display("-----+-----+----------------+----------------++----+---------------+--------------+-------");

        // ----- RESTA (Sel = 1) -----
        caso( 9,  4, 1);   // A > B
        caso( 5,  5, 1);   // A = B  (resultado 0)
        caso( 7,  1, 1);   // A > B
        caso( 3,  7, 1);   // A < B  (préstamo, resultado en complemento a 2)
        caso( 0,  1, 1);   // A < B  (0 - 1 = 15)

        // ----- Verificación exhaustiva silenciosa (solo imprime errores) -----
        for (k = 0; k < 2; k = k + 1)
            for (i = 0; i < 16; i = i + 1)
                for (j = 0; j < 16; j = j + 1) begin
                    A = i; B = j; Sel = k;
                    #10;
                    verificar;
                    if (!ok)
                        $display("ERROR exhaustivo: Sel=%b A=%0d B=%0d -> Co=%b So=%0d (esperado Co=%b So=%0d)",
                                 Sel, A, B, Co, So, esperado[4], esperado[3:0]);
                end

        $display("");
        if (errores == 0) $display("tb_sumador_restador: PASS (10 casos mostrados + 512 verificados)");
        else              $display("tb_sumador_restador: FALLO, %0d errores", errores);
        $finish;
    end
endmodule


// ---------------------------------------------------------------------
// tb_fpga_restador : tabla corta (suma y resta) con lógica negativa +
// verificación exhaustiva silenciosa de las 512 combinaciones.
// Los casos se dan en valores REALES (a, b, s); el testbench los
// invierte para aplicarlos a los pines.
//   s = 0 -> a + b      s = 1 -> a - b
// LED (pin) = ~resultado ; el display muestra el acarreo real.
// ---------------------------------------------------------------------
module tb_fpga_restador;
    reg  [3:0] A, B;
    reg        Sel;
    wire [3:0] LED;
    wire [7:0] SEG;
    wire [3:0] DIG;
    reg  [3:0] a, b;
    reg        s;
    reg  [4:0] esperado;
    reg  [7:0] seg_esp;
    reg        ok;
    integer i, j, k, errores;

    fpga_restador dut(.A(A), .B(B), .Sel(Sel), .LED(LED), .SEG(SEG), .DIG(DIG));

    // Aplica valores reales en los pines, calcula lo esperado y verifica
    task aplicar_y_verificar;
        begin
            A = ~a; B = ~b; Sel = ~s;       // pines (lógica negativa)
            #10;
            if (s) esperado = {1'b0, a} + {1'b0, ~b} + 5'd1;   // a - b
            else   esperado = {1'b0, a} + {1'b0, b};           // a + b
            seg_esp = esperado[4] ? 8'b11111001 : 8'b11000000;
            ok = (LED === ~esperado[3:0]) && (SEG === seg_esp) && (DIG === 4'b1110);
            if (!ok) errores = errores + 1;
        end
    endtask

    // Caso para la tabla corta
    task caso(input [3:0] av, input [3:0] bv, input sv);
        begin
            a = av; b = bv; s = sv;
            aplicar_y_verificar;
            $display(" %b %b %b | %s | %2d  %2d |   %2d (%b)    |   %b   |    %s    | %s",
                     A, B, Sel, s ? "a-b" : "a+b", a, b,
                     esperado[3:0], esperado[3:0], LED,
                     (SEG === 8'b11000000) ? "0" : (SEG === 8'b11111001) ? "1" : "?",
                     ok ? "OK   " : "ERROR");
        end
    endtask

    initial begin
        $dumpfile("tb_fpga_restador.vcd");
        $dumpvars(0, tb_fpga_restador);
        errores = 0;

        $display("");
        $display("=== TABLA DE VERDAD CORTA: FPGA SUMADOR/RESTADOR (logica negativa) ===");
        $display("(Los pines A B Sel estan invertidos; LED es activo en bajo)");
        $display(" PINES A B Sel | Op  |  a   b | Resultado real | LED (pin) | Display | Estado");
        $display("--------------+-----+--------+----------------+-----------+---------+-------");

        // ----- SUMA (s = 0) -----
        //     a   b   s
        caso( 3,  2, 0);   // suma simple
        caso( 7,  1, 0);   // acarreo interno
        caso( 8,  8, 0);   // acarreo final (display = 1)
        caso(15,  1, 0);   // desbordamiento
        caso(15, 15, 0);   // máximo
        $display("--------------+-----+--------+----------------+-----------+---------+-------");

        // ----- RESTA (s = 1) -----
        caso( 9,  4, 1);   // a > b  (display = 1: sin préstamo)
        caso( 5,  5, 1);   // a = b  (resultado 0)
        caso( 7,  1, 1);   // a > b
        caso( 3,  7, 1);   // a < b  (display = 0: con préstamo)
        caso( 0,  1, 1);   // a < b  (0 - 1 = 15)

        // ----- Verificación exhaustiva silenciosa (solo imprime errores) -----
        for (k = 0; k < 2; k = k + 1)
            for (i = 0; i < 16; i = i + 1)
                for (j = 0; j < 16; j = j + 1) begin
                    a = i; b = j; s = k;
                    aplicar_y_verificar;
                    if (!ok)
                        $display("ERROR exhaustivo: a=%0d b=%0d s=%b -> LED=%b SEG=%b (esperado LED=%b SEG=%b)",
                                 a, b, s, LED, SEG, ~esperado[3:0], seg_esp);
                end

        $display("");
        if (errores == 0) $display("tb_fpga_restador: PASS (10 casos mostrados + 512 verificados)");
        else              $display("tb_fpga_restador: FALLO, %0d errores", errores);
        $finish;
    end
endmodule


// ---------------------------------------------------------------------
// tb_control_caldera : comparador T - L con LEDs activos en bajo
// Parte 1: casos dirigidos con tabla.
// Parte 2: barrido exhaustivo. La tabla se imprime para el modo resta
// (Sel pin = 0); el modo suma se verifica sin imprimir filas.
// LED encendido = 0.
// ---------------------------------------------------------------------
module tb_control_caldera;
    parameter MOSTRAR = 1;

    reg  [3:0] T, L;
    reg        Sel;
    wire       PERFECT_LED, PROCESS_LED, BURN_LED;
    reg  [3:0] t, l;
    reg        s;
    reg  [4:0] res;
    reg        co_esp, cero_esp, ok;
    integer i, j, k, errores;

    control_caldera dut(.T(T), .L(L), .Sel(Sel),
                        .PERFECT_LED(PERFECT_LED),
                        .PROCESS_LED(PROCESS_LED),
                        .BURN_LED(BURN_LED));

    // Texto del estado según el LED encendido (activo en bajo)
    function [55:0] estado_txt;   // 7 caracteres
        input proc, perf, burn;
        begin
            if      (proc === 1'b0 && perf === 1'b1 && burn === 1'b1) estado_txt = "PROCESS";
            else if (proc === 1'b1 && perf === 1'b0 && burn === 1'b1) estado_txt = "PERFECT";
            else if (proc === 1'b1 && perf === 1'b1 && burn === 1'b0) estado_txt = "BURN   ";
            else                                                      estado_txt = "???    ";
        end
    endfunction

    // Caso dirigido: valores reales tv, lv en pines (lógica negativa)
    task prueba_dirigida(input [3:0] tv, input [3:0] lv,
                         input exp_process, input exp_perfect, input exp_burn);
        reg ok_t;
        begin
            T = ~tv; L = ~lv; Sel = 1'b0;   // Sel pin = 0 -> resta T - L
            #10;
            ok_t = (PROCESS_LED === ~exp_process) &&
                   (PERFECT_LED === ~exp_perfect) &&
                   (BURN_LED    === ~exp_burn);
            if (!ok_t) errores = errores + 1;
            $display("  %2d |  %2d |    %b     |    %b     |   %b    | %s | %s",
                     tv, lv, PROCESS_LED, PERFECT_LED, BURN_LED,
                     estado_txt(PROCESS_LED, PERFECT_LED, BURN_LED),
                     ok_t ? "OK   " : "ERROR");
        end
    endtask

    initial begin
        $dumpfile("tb_control_caldera.vcd");
        $dumpvars(0, tb_control_caldera);
        errores = 0;

        // ---------- Parte 1: casos dirigidos ----------
        $display("");
        $display("=== CASOS DIRIGIDOS: CONTROL DE CALDERA (T - L, LED activo en 0) ===");
        $display("   T |   L | PROCESS_LED | PERFECT_LED | BURN_LED | Estado  | Resultado");
        $display("-----+-----+-------------+-------------+----------+---------+----------");
        //                  T   L   process perfect burn
        prueba_dirigida( 3,  10,   1,      0,      0);   // T < L
        prueba_dirigida( 0,  15,   1,      0,      0);   // T < L (extremo)
        prueba_dirigida( 7,   7,   0,      1,      0);   // T == L
        prueba_dirigida( 0,   0,   0,      1,      0);   // T == L (cero)
        prueba_dirigida(15,  15,   0,      1,      0);   // T == L (máximo)
        prueba_dirigida(12,   5,   0,      0,      1);   // T > L
        prueba_dirigida(15,   0,   0,      0,      1);   // T > L (extremo)

        // ---------- Parte 2: barrido exhaustivo ----------
        if (MOSTRAR) begin
            $display("");
            $display("=== TABLA COMPLETA: CONTROL DE CALDERA (modo resta, Sel pin = 0) ===");
            $display("   T |   L | T-L (4 bits) | PROCESS_LED | PERFECT_LED | BURN_LED | Estado  | Resultado");
            $display("-----+-----+--------------+-------------+-------------+----------+---------+----------");
        end

        for (k = 0; k < 2; k = k + 1)
            for (i = 0; i < 16; i = i + 1)
                for (j = 0; j < 16; j = j + 1) begin
                    // k=0 -> Sel pin=0 -> s=1 (resta); k=1 -> Sel pin=1 -> s=0 (suma)
                    t = i; l = j; s = ~k[0];
                    T = ~t; L = ~l; Sel = ~s;
                    #10;
                    if (s) res = {1'b0, t} + {1'b0, ~l} + 5'd1;   // t - l
                    else   res = {1'b0, t} + {1'b0, l};           // t + l
                    co_esp   = res[4];
                    cero_esp = (res[3:0] == 4'b0000);
                    ok = (PROCESS_LED === co_esp) &&
                         (PERFECT_LED === ~(co_esp &  cero_esp)) &&
                         (BURN_LED    === ~(co_esp & ~cero_esp));
                    // En resta verificar además la comparación real
                    if (s) begin
                        if (t <  l && !(PROCESS_LED === 1'b0 && PERFECT_LED === 1'b1 && BURN_LED === 1'b1)) ok = 0;
                        if (t == l && !(PROCESS_LED === 1'b1 && PERFECT_LED === 1'b0 && BURN_LED === 1'b1)) ok = 0;
                        if (t >  l && !(PROCESS_LED === 1'b1 && PERFECT_LED === 1'b1 && BURN_LED === 1'b0)) ok = 0;
                    end
                    if (!ok) errores = errores + 1;
                    if ((MOSTRAR && s) || !ok)
                        $display("  %2d |  %2d |   %2d (%b)   |      %b      |      %b      |    %b     | %s | %s",
                                 t, l, res[3:0], res[3:0], PROCESS_LED, PERFECT_LED, BURN_LED,
                                 estado_txt(PROCESS_LED, PERFECT_LED, BURN_LED),
                                 ok ? "OK   " : "ERROR");
                end

        $display("");
        if (errores == 0) $display("tb_control_caldera: PASS");
        else              $display("tb_control_caldera: FALLO, %0d errores", errores);
        $finish;
    end
endmodule