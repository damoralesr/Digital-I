 Sumador, restador y control de caldera en Verilog

Proyecto de diseño digital en Verilog para FPGA. Incluye un sumador de 4 bits
construido con sumadores completos de 1 bit, un sumador/restador, un control
de caldera y sus testbenches autoverificables.

## Contenido

| Archivo | Descripción |
|---|---|
| `src/s_1b.v` | Sumador completo de 1 bit |
| `src/sumador.v` | Sumador de 4 bits (ripple-carry) |
| `src/display7.v` | Manejador de display de 7 segmentos (muestra 0 o 1) |
| `src/fpga_sumador.v` | Top-level del sumador para la tarjeta FPGA |
| `src/sumador_restador.v` | Suma (Sel=0) o resta (Sel=1) de 4 bits |
| `src/fpga_restador.v` | Top-level del sumador/restador para la FPGA |
| `src/control_caldera.v` | Compara T con L y enciende LED PROCESS, PERFECT o BURN |
| `tb/tb_simulaciones.v` | Testbenches de todos los módulos |

## Descripción de los módulos

### Sumador completo de 1 bit
Suma A, B y el acarreo Ci: `So = A ^ B ^ Ci`, `Co = A·B + Ci·(A ^ B)`.

### Sumador de 4 bits
Encadena cuatro sumadores de 1 bit. `{Co, So} = A + B + Ci`.

### Sumador/restador
Con `Sel = 0` calcula `A + B`. Con `Sel = 1` calcula `A - B` en complemento a 2
(`A + ~B + 1`). En resta, `Co = 1` significa que A ≥ B.

### Control de caldera
Calcula T − L y enciende un LED (activo en bajo):
- **PROCESS**: T < L
- **PERFECT**: T = L
- **BURN**: T > L

## Cómo simular

Requiere [Icarus Verilog](https://bleyer.org/icarus/) y, opcionalmente, GTKWave.

```bash
# Ejemplo: sumador de 4 bits
iverilog -s tb_sumador -o sim_sumador src/s_1b.v src/sumador.v tb/tb_simulaciones.v
vvp sim_sumador

# Ejemplo: control de caldera
iverilog -s tb_control_caldera -o sim_caldera src/s_1b.v src/sumador.v src/sumador_restador.v src/control_caldera.v tb/tb_simulaciones.v
vvp sim_caldera

# Ver formas de onda
gtkwave tb_control_caldera.vcd
```

## Resultados de simulación

### Sumador de 1 bits
![Circuito en Digital](imagenes/sum1bit.png)

Tabla de verdad impresa en la terminal:

![Tabla de verdad de s_1b](imagenes/sim_s_1b.png)


### Sumador de 4 bits
![Circuito en Digital](imagenes/sum4bits.png)

Tabla de verdad impresa en la terminal:

![Tabla de verdad de sumador](imagenes/sim_sumador.png)

![Tabla de verdad de fpga_sumador](imagenes/sim_fpga_sumador.png)


### Sumador/restador
![Circuito en Digital](imagenes/Sum_res.png)

Tabla de verdad impresa en la terminal:


![Tabla de verdad del sumador/restador](imagenes/sim_sumador_restador.png)

![Tabla de verdad del sumador/restador](imagenes/sim_fpga_restador.png)

### Control de caldera

![Circuito en Digital](imagenes/caldera.png)

Tabla de verdad impresa en la terminal:


![Tabla de verdad del sumador/restador](imagenes/sim_control_caldera.png)


### Display7

Tabla de verdad impresa en la terminal:


![Tabla de verdad del sumador/restador](imagenes/sim_display7.png)


