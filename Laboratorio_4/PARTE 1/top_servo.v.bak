module top_servo (
    input  wire       clk,       // reloj de la tarjeta
    input  wire       rst,       // reset (pulsador o switch)
    input  wire [3:0] sw,        // posición del servo
    output wire       servo_pwm  // hacia la señal del servo
);

    servo_pwm_gen #(
        .CLK_FREQ(50_000_000)    // ajustar según la tarjeta
    ) u_servo (
        .clk       (clk),
        .rst       (rst),
        .pos       (sw),
        .servo_pwm (servo_pwm)
    );

endmodule