`timescale 1ns/1ps

module tb_cerradura;

    reg        clk;
    reg        rst;
    reg        modo;
    reg  [3:0] sw;
    wire [3:0] cols;
    wire [3:0] rows;
    wire [3:0] leds;
    wire       buzzer;
    wire       servo_pwm;

    reg [1:0] sim_row;
    reg [1:0] sim_col;
    reg       sim_tecla_on;
    reg [3:0] cols_reg;
    
    assign cols = cols_reg;

    always @(*) begin
        cols_reg = 4'b1111;
        if (sim_tecla_on && rows[sim_row] === 1'b0) begin
            cols_reg[sim_col] = 1'b0;
        end
    end

    cerradura_top #(
        .CLK_FREQ(1_000_000), 
        .PASSWORD(16'h1234)
    ) dut (
        .clk(clk),
        .rst(rst),
        .modo(modo),
        .sw(sw),
        .cols(cols),
        .rows(rows),
        .leds(leds),
        .buzzer(buzzer),
        .servo_pwm(servo_pwm)
    );

    always #500 clk = ~clk;

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
                4'd14:begin sim_row = 3; sim_col = 0; end
                default: begin sim_row = 0; sim_col = 0; end
            endcase
            
            sim_tecla_on = 1'b1;
            #15_000_000;
            sim_tecla_on = 1'b0;
            #15_000_000;
        end
    endtask

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
        if(dut.pos_fsm == 4'd15) $display("Exito: FSM ordena apertura (Servo a 180 deg).");
        else $display("FALLO: La FSM no abrio.");

        $display("--- Prueba 2: Cierre por boton * ---");
        presionar_tecla(4'd14); 
        #10000;
        if(dut.pos_fsm == 4'd0) $display("Exito: FSM retorno a estado cerrado.");

        $display("--- Prueba 3: Clave Incorrecta (5-6-7-8) ---");
        presionar_tecla(4'd5);
        presionar_tecla(4'd6);
        presionar_tecla(4'd7);
        presionar_tecla(4'd8);
        
        #10000;
        if(buzzer) $display("Exito: Tono de error emitido por el Buzzer.");
        else $display("FALLO: El buzzer no sono.");

        #2_500_000_000; 
        $display("Pruebas finalizadas con exito.");
        $finish;
    end
endmodule