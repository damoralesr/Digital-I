`timescale 1ns/1ps

module tb_cerradura;

    reg        clk;
    reg        rst;
    reg        modo;
    reg  [3:0] sw;
    wire [3:0] cols;
    wire [3:0] rows;
    wire [3:0] leds;
    wire       led_abierta;
    wire       led_error;
    wire       servo_pwm;

    // --- MODELO FÍSICO DEL TECLADO ---
    reg [1:0] sim_row;
    reg [1:0] sim_col;
    reg       sim_tecla_on;
    reg [3:0] cols_reg;
    
    assign cols = cols_reg;

    always @(*) begin
        cols_reg = 4'b1111; // Resistencias pull-up por defecto
        // Si se presiona la tecla y la fila activa está en BAJO (0)
        if (sim_tecla_on && rows[sim_row] === 1'b0) begin
            cols_reg[sim_col] = 1'b0; // Cortocircuito físico
        end
    end

    // --- INSTANCIA DEL TOP LEVEL ---
    cerradura_top #(
        .CLK_FREQ(1_000_000), // 1 MHz para simulación rápida
        .PASSWORD(16'h1234)
    ) dut (
        .clk(clk),
        .rst(rst),
        .modo(modo),
        .sw(sw),
        .cols(cols),
        .rows(rows),
        .leds(leds),
        .led_abierta(led_abierta),
        .led_error(led_error),
        .servo_pwm(servo_pwm)
    );

    always #500 clk = ~clk;

    // --- TAREA PARA SIMULAR PULSACIONES REALES ---
    task presionar_tecla;
        input [3:0] cod;
        begin
            case(cod)
                4'd1: begin sim_row = 0; sim_col = 0; end
                4'd2: begin sim_row = 0; sim_col = 1; end
                4'd3: begin sim_row = 0; sim_col = 2; end
                4'd4: begin sim_row = 1; sim_col = 0; end
                4'd5: begin sim_row = 1; sim_col = 1; end
                4'd6: begin sim_row = 1; sim_col = 2; end
                4'd7: begin sim_row = 2; sim_col = 0; end
                4'd8: begin sim_row = 2; sim_col = 1; end
                4'd14:begin sim_row = 3; sim_col = 0; end // Tecla *
                default: begin sim_row = 0; sim_col = 0; end
            endcase
            
            sim_tecla_on = 1'b1;
            #15_000_000; // 15 ms para vencer el antirrebote físico (10ms)
            sim_tecla_on = 1'b0;
            #15_000_000; // 15 ms para asegurar la liberación del botón
        end
    endtask

    // --- SECUENCIA DE PRUEBAS ---
    initial begin
        $dumpfile("cerradura.vcd");
        $dumpvars(0, tb_cerradura);

        clk  = 0;
        rst  = 1;
        modo = 1;
        sw   = 4'd0;
        sim_tecla_on = 0;

        #2000;
        rst = 0;
        #5000;

        $display("--- Prueba 1: Clave Correcta (1-2-3-4) ---");
        presionar_tecla(4'd1);
        presionar_tecla(4'd2);
        presionar_tecla(4'd3);
        presionar_tecla(4'd4);
        
        #10000; 
        if(led_abierta) $display("Exito: Puerta abierta con clave correcta.");
        else $display("FALLO: La puerta no abrio.");

        $display("--- Prueba 2: Uso del boton * (cerrar anticipadamente) ---");
        presionar_tecla(4'd14); 
        #10000;
        if(!led_abierta) $display("Exito: Puerta cerrada por teclado.");
        else $display("FALLO: La puerta sigue abierta.");

        $display("--- Prueba 3: Clave Incorrecta (5-6-7-8) ---");
        presionar_tecla(4'd5);
        presionar_tecla(4'd6);
        presionar_tecla(4'd7);
        presionar_tecla(4'd8);
        
        #10000;
        if(led_error) $display("Exito: Error detectado con clave incorrecta.");
        else $display("FALLO: No detecto el error.");

        // Esperar a que pase el tiempo del estado ERROR (2 segundos)
        #2_500_000_000; 

        $display("--- Prueba 4: Borrar entrada (1-2-*) ---");
        presionar_tecla(4'd1);
        presionar_tecla(4'd2);
        presionar_tecla(4'd14); 
        
        #10000;
        if(dut.inst_registro.count == 0) $display("Exito: Entrada borrada correctamente.");
        else $display("FALLO: La entrada no se borro.");

        $display("--- Prueba 5: Modo Manual ---");
        modo = 0;
        sw = 4'd7;
        #1_000_000;
        $display("Posicion del servo fijada a 7. Revisa la forma de onda.");

        #10_000_000;
        $finish;
    end
endmodule