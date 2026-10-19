module servo_pwm_gen #(
    parameter CLK_FREQ = 50_000_000      // Frecuencia del reloj en Hz
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] pos,               // 0 -> 1 ms, 15 -> 2 ms
    output wire       servo_pwm
);

    // ---------- Constantes derivadas de CLK_FREQ ----------
    localparam PERIOD = CLK_FREQ / 50;       // 20 ms en ciclos
    localparam T_MIN  = CLK_FREQ / 1000;     // 1 ms en ciclos
    localparam W      = $clog2(PERIOD);      // bits del contador

    // ---------- Contador de periodo + comparador de reinicio ----------
    reg [W-1:0] cnt;
    wire fin_periodo = (cnt == PERIOD - 1);

    always @(posedge clk) begin
        if (rst || fin_periodo)
            cnt <= {W{1'b0}};
        else
            cnt <= cnt + 1'b1;
    end

    // ---------- Codificador: pos (4 bits) -> t_on en ciclos ----------
    wire [31:0] t_on = T_MIN + (pos * CLK_FREQ) / 15000;

    // ---------- Comparador PWM ----------
    assign servo_pwm = (cnt < t_on);

endmodule