// =====================================================================
// MÓDULO: s_1b  (Sumador completo de 1 bit)
// ---------------------------------------------------------------------
// Suma tres bits: A, B y el acarreo de entrada Ci.
//   So (suma)    = A ^ B ^ Ci
//   Co (acarreo) = A·B + Ci·(A ^ B)
// =====================================================================
module s_1b(A, B, Ci, So, Co);
	
	input A, B, Ci;
	output reg So, Co;
	
	always @(A, B, Ci)
	begin
		So = A ^ B ^ Ci;
		Co = (A&B) | (Ci&(A^B));
	end
endmodule 
