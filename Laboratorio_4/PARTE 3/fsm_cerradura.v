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
    output wire        buzzer,       // Alarma auditiva de error
    output reg  [3:0]  pos_servo
);

    localparam IDLE   = 3'd0;
    localparam INPUT  = 3'd1;
    localparam VERIFY = 3'd2;
    localparam OPEN   = 3'd3;
    localparam ERROR  = 3'd4;

    reg [2:0] estado, siguiente;

    // Temporizadores de estado (5 segundos abierto, 2 segundos en error)
    localparam TICKS_ABIERTO = 5 * CLK_FREQ;
    localparam TICKS_ERROR   = 2 * CLK_FREQ;

    reg [28:0] count_t;
    reg rst_t;

    always @(posedge clk) begin
        if (rst || rst_t) count_t <= 29'd0;
        else count_t <= count_t + 1'b1;
    end

    // Generador de tono de 1 kHz para el Buzzer de la FPGA
    localparam HALF_PERIOD_1KHZ = CLK_FREQ / 2000;
    reg [15:0] tone_cnt = 0;
    reg        tone_reg = 0;

    always @(posedge clk) begin
        if (tone_cnt >= HALF_PERIOD_1KHZ - 1) begin
            tone_cnt <= 0;
            tone_reg <= ~tone_reg;
        end else begin
            tone_cnt <= tone_cnt + 1'b1;
        end
    end

    // Activa el buzzer solo durante el estado ERROR
    assign buzzer = (estado == ERROR) ? tone_reg : 1'b0;

    // 1. Registro de estado
    always @(posedge clk) begin
        if (rst) estado <= IDLE;
        else     estado <= siguiente;
    end

    // 2 y 3. Lógica de transiciones y salidas
    always @(*) begin
        siguiente = estado;
        rst_t     = 1'b0;
        borrar    = 1'b0;
        pos_servo = 4'd0; // Servomotor en 0 grados (CERRADO) por defecto

        case (estado)
            IDLE: begin
                rst_t = 1'b1;
                if (key_valid && key_code < 4'd10) begin
                    siguiente = INPUT;
                end
            end
            
            INPUT: begin
                rst_t = 1'b1;
                if (key_valid && key_code == 4'd14) begin // Tecla '*' para borrar
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
                pos_servo = 4'd15; // Servomotor gira a 180 grados (ABIERTO)
                borrar    = 1'b1;
                
                // Cierra despues de 5s o si se presiona la tecla '*'
                if (count_t >= TICKS_ABIERTO - 1 || (key_valid && key_code == 4'd14)) begin
                    siguiente = IDLE;
                end
            end
            
            ERROR: begin
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