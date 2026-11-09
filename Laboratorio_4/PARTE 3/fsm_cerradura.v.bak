module fsm_cerradura #(
    parameter CLK_FREQ = 50_000_000,
    parameter [15:0] PASSWORD = 16'h1234
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        key_valid,
    input  wire  [3:0] key_code,
    input  wire        completo,
    input  wire [15:0] pass_in,
    output reg         borrar,
    output reg         led_abierta,
    output reg         led_error,
    output reg  [3:0]  pos_servo
);

    localparam IDLE   = 3'd0;
    localparam INPUT  = 3'd1;
    localparam VERIFY = 3'd2;
    localparam OPEN   = 3'd3;
    localparam ERROR  = 3'd4;

    reg [2:0] estado, siguiente;

    // Temporizadores basados en la frecuencia del reloj
    localparam TICKS_ABIERTO = 5 * CLK_FREQ;
    localparam TICKS_ERROR   = 2 * CLK_FREQ;

    reg [28:0] count_t; // 29 bits son suficientes para contar hasta 250,000,000
    reg rst_t;

    always @(posedge clk) begin
        if (rst || rst_t) count_t <= 29'd0;
        else count_t <= count_t + 1'b1;
    end

    // 1. Registro de estado
    always @(posedge clk) begin
        if (rst) estado <= IDLE;
        else     estado <= siguiente;
    end

    // 2 y 3. Logica de siguiente estado y de salida
    always @(*) begin
        siguiente = estado;
        rst_t = 1'b0;
        borrar = 1'b0;
        led_abierta = 1'b0;
        led_error = 1'b0;
        pos_servo = 4'd0; // Posicion cerrado (0 -> 1ms) por defecto

        case (estado)
            IDLE: begin
                rst_t = 1'b1;
                if (key_valid && key_code < 4'd10) begin
                    siguiente = INPUT;
                end
            end
            
            INPUT: begin
                rst_t = 1'b1;
                if (key_valid && key_code == 4'd14) begin // Tecla '*' es el 14
                    borrar = 1'b1;
                    siguiente = IDLE;
                end else if (completo) begin
                    siguiente = VERIFY;
                end
            end
            
            VERIFY: begin
                rst_t = 1'b1;
                if (pass_in == PASSWORD) begin
                    siguiente = OPEN;
                end else begin
                    siguiente = ERROR;
                end
            end
            
            OPEN: begin
                led_abierta = 1'b1;
                pos_servo = 4'd15; // Posicion abierta (15 -> 2ms)
                borrar = 1'b1;     // Mantener el registro reseteado
                
                // Salir de OPEN por tiempo o por pulsar '*'
                if (count_t >= TICKS_ABIERTO - 1 || (key_valid && key_code == 4'd14)) begin
                    siguiente = IDLE;
                end
            end
            
            ERROR: begin
                led_error = 1'b1;
                borrar = 1'b1;
                
                if (count_t >= TICKS_ERROR - 1) begin
                    siguiente = IDLE;
                end
            end
            
            default: begin
                siguiente = IDLE;
            end
        endcase
    end
endmodule
