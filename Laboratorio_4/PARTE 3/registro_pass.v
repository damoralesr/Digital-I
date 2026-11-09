module registro_pass (
    input  wire        clk,
    input  wire        rst,
    input  wire        borrar,     
    input  wire        key_valid,  
    input  wire  [3:0] key_code,   
    output reg  [15:0] pass_in,    
    output wire        completo    
);
    reg [2:0] count;
    assign completo = (count == 3'd4);

    always @(posedge clk) begin
        if (rst || borrar) begin
            pass_in <= 16'd0;
            count   <= 3'd0;
        end else if (key_valid && !completo) begin
            if (key_code < 4'd10) begin // Solo procesar del 0 al 9
                pass_in <= {pass_in[11:0], key_code};
                count   <= count + 1'b1;
            end
        end
    end
endmodule
