module cerradura_top #(
    parameter        CLK_FREQ = 50_000_000, 
    parameter [15:0] PASSWORD = 16'h1234    
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       modo,         // 0: servo manual, 1: cerradura
    input  wire [3:0] sw,           // posicion manual del servo
    input  wire [3:0] cols,         // columnas del teclado
    output wire [3:0] rows,         // filas del teclado
    output wire [3:0] leds,         // codigo de la ultima tecla
    output wire       led_abierta,
    output wire       led_error,
    output wire       servo_pwm
);

    // Señales internas
    wire       key_valid;
    wire [3:0] key_code;
    wire       borrar;
    wire [15:0] pass_in;
    wire       completo;
    wire [3:0] pos_fsm;
    wire [3:0] pos_servo_final;

    // Instancia de la interfaz del teclado de la Parte 2
    teclado_matricial #(
        .CLK_FREQ(CLK_FREQ)
    ) inst_teclado (
        .clk(clk),
        .rst(rst),
        .cols(cols),
        .rows(rows),
        .key_code(key_code),
        .key_valid(key_valid)
    );

    assign leds = key_code; // Leds muestran la ultima tecla presionada

    // Instancia del registro de desplazamiento de 16 bits
    registro_pass inst_registro (
        .clk(clk),
        .rst(rst),
        .borrar(borrar),
        .key_valid(key_valid),
        .key_code(key_code),
        .pass_in(pass_in),
        .completo(completo)
    );

    // Instancia de la Maquina de Estados (FSM) de la cerradura
    fsm_cerradura #(
        .CLK_FREQ(CLK_FREQ),
        .PASSWORD(PASSWORD)
    ) inst_fsm (
        .clk(clk),
        .rst(rst),
        .key_valid(key_valid),
        .key_code(key_code),
        .completo(completo),
        .pass_in(pass_in),
        .borrar(borrar),
        .led_abierta(led_abierta),
        .led_error(led_error),
        .pos_servo(pos_fsm)
    );

    // Multiplexor para seleccionar el control del servo (Manual vs FSM)
    assign pos_servo_final = (modo == 1'b1) ? pos_fsm : sw;

    // Instancia del generador PWM de la Parte 1
    servo_pwm_gen #(
        .CLK_FREQ(CLK_FREQ)
    ) inst_servo (
        .clk(clk),
        .rst(rst),
        .pos(pos_servo_final),
        .servo_pwm(servo_pwm)
    );

endmodule
