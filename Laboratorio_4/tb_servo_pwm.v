`timescale 1ns/1ps

module tb_servo_pwm;

    reg        clk = 0;
    reg        rst = 1;
    reg  [3:0] pos = 0;
    wire       pwm;

    servo_pwm_gen #(.CLK_FREQ(1_000_000)) dut (
        .clk(clk), .rst(rst), .pos(pos), .servo_pwm(pwm)
    );

    // Reloj de 1 MHz (periodo 1000 ns)
    always #500 clk = ~clk;

    real t_rise1, t_fall, t_rise2;

    task medir(input [3:0] p);
        begin
            pos = p;
            @(posedge pwm);            // descarta el periodo de transición
            @(posedge pwm); t_rise1 = $realtime;
            @(negedge pwm); t_fall  = $realtime;
            @(posedge pwm); t_rise2 = $realtime;
            $display("pos=%2d | periodo = %0.3f ms | t_on = %0.4f ms",
                     p, (t_rise2 - t_rise1)/1.0e6, (t_fall - t_rise1)/1.0e6);
        end
    endtask

    initial begin
        $dumpfile("servo_pwm.vcd");
        $dumpvars(0, tb_servo_pwm);

        #5000 rst = 0;

        medir(4'd0);     // mínimo
        medir(4'd7);     // intermedio
        medir(4'd15);    // máximo

        #1000 $finish;
    end

endmodule