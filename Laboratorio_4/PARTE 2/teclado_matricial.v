// ============================================================================
// teclado_matricial.v
// Lector de teclado matricial 4x4 para FPGA Cyclone IV (EP4CE6E22C8N)
//
//  - Sincronizador de 2 flip-flops en las columnas
//  - Barrido de filas activo en bajo, filas inactivas en alta impedancia
//  - Cambio de fila cada 1 ms
//  - Antirrebote de 10 ms (el barrido se pausa al detectar una tecla)
//  - key_valid = pulso de exactamente 1 ciclo de reloj (detector de flanco)
//  - Espera a que la tecla se suelte (con 10 ms de estabilidad) antes de
//    aceptar otra pulsacion
//
// Mapeo: 0-9 -> 0-9, A-D -> 10-13, * -> 14, # -> 15
// (comentarios sin tildes a proposito: evita problemas de codificacion)
// ============================================================================
module teclado_matricial #(
    parameter CLK_FREQ = 50_000_000      // Frecuencia del reloj principal de la FPGA
) (
    input  wire       clk,               //Reloj del sistema 
    input  wire       rst,               //Boton de reinicio del sistema             // Reset activo en alto, sincrono
    input  wire [3:0] cols,              // Entradas de las 4 columnas (pull-up, activas en bajo)
    output wire [3:0] rows,              // Salidas a las 4 filas Filas: 0 = activa, Z = inactiva
    output reg  [3:0] key_code,          // Registro de salida con el valor numerico de la tecla
    output wire       key_valid          // Pulso de 1 ciclo que confirma la lectura de la tecla
);

    // ------------------------------------------------------------------------
    // CALCULO DE ANCHO DE BITS
    // ------------------------------------------------------------------------

    //T_scan = 1 ms -> Ciclos = 50,000,000 hz * 0.001 = 50.000 ciclos
    localparam integer CICLOS_SCAN  = CLK_FREQ / 1000;  //  1 ms
    
    //T_debounce = 10 ms -> 50.0000 Hz * 0.010 s = 500.000 ciclos
    localparam integer CICLOS_ANTIR = CLK_FREQ / 100;   // 10 ms

    // clog2 propia (constante) para no depender de $clog2
    
    //Se realiza esta función para calcular el logaritmo base 2 utíl 
    //para determinar dinamicamente cuantos bits se requieren en los contadores
    function integer clog2;
        input integer valor;
        integer i;
        begin
            clog2 = 0;
            for (i = valor - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    //Se crea ANCHO_CNT para calcular automaticamente los bits requeridos en los contadores
    localparam integer ANCHO_CNT = clog2(CICLOS_ANTIR);

    // ------------------------------------------------------------------------
    // 1) Sincronizador de dos flip-flops para las columnas
    // ------------------------------------------------------------------------
    //las columnas son señales externas y asincronas que pasan por 2 Flip-flops
    //Se alinea a su vez con clk para alinearlas con el reloj interno de la FPGA.
    reg [3:0] cols_s1, cols_s2;

    always @(posedge clk) begin
        if (rst) begin
            cols_s1 <= 4'b1111;    //Al reiniciar se asume reposo por ende Pull ups = 1111      // Sin tecla (pull-up = 1)
            cols_s2 <= 4'b1111;
        end else begin
            cols_s1 <= cols;       //Captura el estado fisico externo
            cols_s2 <= cols_s1;    //Estabiliza la señal internamente
        end
    end

    // ------------------------------------------------------------------------
    // 2) Función Decodificadora {fila, columnas} -> {valido, codigo}
    //    Columna activa = el unico bit en 0 de "c"
    // ------------------------------------------------------------------------
    function [4:0] decodifica;
        input [1:0] fila;  //Indice de la fila activa (0 a 3)
        input [3:0] c;     // Estados de las 4 columnas, como lo sería 4'b1110
        reg   [1:0] col;   //Numero de columna identificada de 0 a 3
        reg         ok;    //Flag: 1 equivale a tecla unica valida y 0= invalida o multiples pulsadas
        reg   [3:0] cod;   //Codigo numerico final
        begin
            ok = 1'b1;     //Por defecto se asume una lectura correcta

            //Convierte el bit activo en bajo 0  de las columnas a su indice entero
            case (c)
                4'b1110: col = 2'd0;  //Columan 0 pulsada
                4'b1101: col = 2'd1;  //Columan 1 pulsada
                4'b1011: col = 2'd2;  //Columan 2 pulsada
                4'b0111: col = 2'd3;  //Columan 3 pulsada
                default: begin col = 2'd0; ok = 1'b0; end  // ninguna o varias teclas presionadas
            endcase


            //Matriz de mapeo: aquí se une la fila y la columna para poder entregar el valor solicitado
            case ({fila, col})
                // Fila 0:  1  2  3  A
                4'b00_00: cod = 4'd1;    // Tecla 1
                4'b00_01: cod = 4'd2;    // Tecla 2
                4'b00_10: cod = 4'd3;    // Tecla 3
                4'b00_11: cod = 4'd10;   // Tecla A=10
                // Fila 1:  4  5  6  B
                4'b01_00: cod = 4'd4;    // Tecla 4
                4'b01_01: cod = 4'd5;    // Tecla 5
                4'b01_10: cod = 4'd6;    // Tecla 6
                4'b01_11: cod = 4'd11;   // Tecla B=11
                // Fila 2:  7  8  9  C
                4'b10_00: cod = 4'd7;    // Tecla 7
                4'b10_01: cod = 4'd8;    // Tecla 8
                4'b10_10: cod = 4'd9;    // Tecla 9
                4'b10_11: cod = 4'd12;   // Tecla C=12
                // Fila 3:  *  0  #  D
                4'b11_00: cod = 4'd14;   // Tecla *=14
                4'b11_01: cod = 4'd0;    // Tecla 0=0 
                4'b11_10: cod = 4'd15;   // Tecla #=15
                4'b11_11: cod = 4'd13;   // tecla D 13
                default:  cod = 4'd0;
            endcase

            //Retorna un bus de 5 bits
            decodifica = {ok, cod};
        end
    endfunction

    // ------------------------------------------------------------------------
    // 3) Maquina de estados: barrido, antirrebote y espera de liberacion
    // ------------------------------------------------------------------------
    localparam [1:0] S_SCAN          = 2'd0,  // Estado 0: barriendo filas cada 1ms
                     S_DEBOUNCE      = 2'd1,  // Estado 1: pausar y esperar 10ms de estabilidad
                     S_ESPERA_SOLTAR = 2'd2;  // EStado 2: espera a que la tecla sea validada y soltada

    reg [1:0]           estado;               //Registro del estado en el que se encuentra
    reg [1:0]           fila_idx;             // Indice de la fila activa actualmente (0..3)
    reg [ANCHO_CNT-1:0] cnt_scan;             // contador de tiempo para el barrido 1 ms
    reg [ANCHO_CNT-1:0] cnt_deb;              // contador de tiempo para el antirebote 10 ms
    reg [3:0]           cols_lock;            // Muestra congelada del patron de columnas leído
    reg                 key_pressed;          // tecla validada y aun presionada
    reg                 key_pressed_ant;      // valor anterior para detectar el flanco de subida

    //Llamada continua combinacional a la función decodificadora
    wire [4:0] dec = decodifica(fila_idx, cols_lock);

    always @(posedge clk) begin
        if (rst) begin
            //Reinicio de todas las variables internas de la FSM
            estado      <= S_SCAN;
            fila_idx    <= 2'd0;
            cnt_scan    <= {ANCHO_CNT{1'b0}};
            cnt_deb     <= {ANCHO_CNT{1'b0}};
            cols_lock   <= 4'b1111;
            key_pressed <= 1'b0;
            key_code    <= 4'd0;
        end else begin
            case (estado)

                // Estado 0: Barrido: se decide una vez por milisegundo ----
                S_SCAN: begin
                    cnt_deb <= {ANCHO_CNT{1'b0}};  //Ayuda a mantener limpio el timer de antirrebote
                    if (cnt_scan == CICLOS_SCAN - 1) begin
                        cnt_scan <= {ANCHO_CNT{1'b0}};  //Reinicia el contador de 1ms
                        if (cols_s2 != 4'b1111) begin
                            // Hay algo presionado en la fila activa:se pausa el barrido
                            cols_lock <= cols_s2;  //Se congela la columna leída
                            estado    <= S_DEBOUNCE;   //Salta al estado para validar el antirebote
                        end else begin
                            //Aún no se ha presionado nada por lo que sigue avanzando de fila
                            fila_idx  <= fila_idx + 1'b1;   // 3 -> 0 por desborde
                        end
                    end else begin
                        cnt_scan <= cnt_scan + 1'b1;    //Se incrementa el temporizador de 1ms
                    end
                end

                // Estado 1: Antirrebote: columnas estables 10 ms 
                S_DEBOUNCE: begin
                    if (cols_s2 != cols_lock) begin
                        // Rebote o cambio: abortar y volver a barrer
                        cnt_deb <= {ANCHO_CNT{1'b0}};
                        estado  <= S_SCAN;          //cancela y vuelve a barrer
                    end else if (cnt_deb == CICLOS_ANTIR - 1) begin
                        cnt_deb <= {ANCHO_CNT{1'b0}};   //Esta parte ocurre cuando se completaron los 10ms estables continuos
                        if (dec[4]) begin
                            key_code    <= dec[3:0];  //Guarda el codigo decodificado
                            key_pressed <= 1'b1;      //Tecla presionada
                            estado      <= S_ESPERA_SOLTAR;   //Espera la liberación
                        end else begin
                            // Varias teclas a la vez: se ignora y se sigue
                            fila_idx <= fila_idx + 1'b1;
                            estado   <= S_SCAN;
                        end
                    end else begin
                        cnt_deb <= cnt_deb + 1'b1;   //Se incrementa el temporizador de 10ms
                    end
                end

                // Estado 2: Esperar a que se suelte (1111 estable 10 ms) ----
                S_ESPERA_SOLTAR: begin
                    if (cols_s2 != 4'b1111) begin
                        //Si el boton sigue oprimido se reinica el contador de liberación
                        cnt_deb <= {ANCHO_CNT{1'b0}};
                    end else if (cnt_deb == CICLOS_ANTIR - 1) begin
                        
                        //cuando la tecla se libera durante 10ms estables 
                        cnt_deb     <= {ANCHO_CNT{1'b0}};
                        key_pressed <= 1'b0;   //Se borra la bandera de presionado
                        estado      <= S_SCAN;  //Se regresa al escaneo normal
                    end else begin
                        cnt_deb <= cnt_deb + 1'b1;
                    end
                end

                default: estado <= S_SCAN;
            endcase
        end
    end

    // ------------------------------------------------------------------------
    // 4) Salida de filas: activa en bajo, inactivas en alta impedancia
    // Genera 4 asignaciones independientes para las filas.
    // Solo la fila apuntada por 'fila_idx' pone un '0' en el pin fisico.
    // Las otras 3 filas se configuran en '1'bz' (desconectadas / alta impedancia)
    // para no causar un cortocircuito si el usuario presiona dos botones a la vez.
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin : gen_rows
            assign rows[g] = (fila_idx == g) ? 1'b0 : 1'bz;
        end
    endgenerate

    // ------------------------------------------------------------------------
    // 5) Detector de flanco: key_valid dura exactamente 1 ciclo de reloj
    // ------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) key_pressed_ant <= 1'b0;
        else     key_pressed_ant <= key_pressed;
    end

    assign key_valid = key_pressed & ~key_pressed_ant;

endmodule