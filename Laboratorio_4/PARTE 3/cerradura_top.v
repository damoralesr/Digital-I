module cerradura_top #(
    parameter        CLK_FREQ = 50_000_000, 
    parameter [15:0] PASSWORD = 16'h1234    
)(
    input  wire        clk,
    input  wire        rst,          // Botón de la placa (0 al presionar, 1 al soltar)
    input  wire        modo,         // Switch de modo (0: manual SW, 1: cerradura)
    input  wire [3:0] sw,           // Switches para control manual
    input  wire [3:0] cols,         // Columnas del teclado
    output wire [3:0] rows,         // Filas del teclado
    output wire [3:0] leds,         // Muestra en los 4 LEDs integrados el último dígito
    output wire        buzzer,       // Buzzer integrado en la tarjeta
    output wire        servo_pwm     // Salida al servomotor SG90
);

    // Inversión de señal para adaptar la tecla Active-LOW de la tarjeta
    wire sys_rst = ~rst; // sys_rst estará activo (1) solo al pulsar el botón físico

    wire        key_valid;
    wire [3:0] key_code;
    wire        borrar;
    wire [15:0] pass_in;
    wire        completo;
    wire [3:0] pos_fsm;
    wire [3:0] pos_servo_final;

    // 1. Instancia del Teclado Matricial
    teclado_matricial #(
        .CLK_FREQ(CLK_FREQ)
    ) inst_teclado (
        .clk(clk),
        .rst(sys_rst),
        .cols(cols),
        .rows(rows),
        .key_code(key_code),
        .key_valid(key_valid)
    );

    // Muestra en binario la última tecla presionada en los 4 LEDs integrados
    assign leds = ~key_code; 

    // 2. Instancia del Registro de Clave
    registro_pass inst_registro (
        .clk(clk),
        .rst(sys_rst),
        .borrar(borrar),
        .key_valid(key_valid),
        .key_code(key_code),
        .pass_in(pass_in),
        .completo(completo)
    );

    // 3. Instancia de la FSM
    fsm_cerradura #(
        .CLK_FREQ(CLK_FREQ),
        .PASSWORD(PASSWORD)
    ) inst_fsm (
        .clk(clk),
        .rst(sys_rst),
        .key_valid(key_valid),
        .key_code(key_code),
        .completo(completo),
        .pass_in(pass_in),
        .borrar(borrar),
        .buzzer(buzzer),
        .pos_servo(pos_fsm)
    );

    // Selección del control del servo (MODO 1: FSM | MODO 0: Switches)
    assign pos_servo_final = (modo == 1'b1) ? pos_fsm : sw;

    // 4. Generador PWM para el SG90
    servo_pwm_gen #(
        .CLK_FREQ(CLK_FREQ)
    ) inst_servo (
        .clk(clk),
        .rst(sys_rst),
        .pos(pos_servo_final),
        .servo_pwm(servo_pwm)
    );

endmodule