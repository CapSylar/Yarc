module tmds_encoder(
	input clk,
	input rstn_i,
	input [7:0] vd_i,  // video data (red, green or blue)
	input [1:0] cd_i,  // control data
	input vde_i,  // video data enable, to choose between cd_i (when vde_i=0) and vd_i (when vde_i=1)
	output logic [9:0] tmds_o
);
	wire [3:0] Nb1s = 4'(vd_i[0]) + 4'(vd_i[1]) + 4'(vd_i[2]) + 4'(vd_i[3]) + 4'(vd_i[4]) + 4'(vd_i[5]) + 4'(vd_i[6]) + 4'(vd_i[7]);
	wire XNOR = (Nb1s>4'd4) || (Nb1s==4'd4 && vd_i[0]==1'b0);

	/*verilator lint_off UNOPTFLAT*/
	wire [8:0] q_m = {~XNOR, q_m[6:0] ^ vd_i[7:1] ^ {7{XNOR}}, vd_i[0]};
    /*verilator lint_on UNOPTFLAT*/

	logic [3:0] balance_acc = 0;
	wire [3:0] balance = 4'(q_m[0]) + 4'(q_m[1]) + 4'(q_m[2]) + 4'(q_m[3]) + 4'(q_m[4]) + 4'(q_m[5]) + 4'(q_m[6]) + 4'(q_m[7]) - 4'd4;
	wire balance_sign_eq = (balance[3] == balance_acc[3]);
	wire invert_q_m = (balance==0 || balance_acc==0) ? ~q_m[8] : balance_sign_eq;
	/*verilator lint_off WIDTHEXPAND*/
	wire [3:0] balance_acc_inc = balance - ({q_m[8] ^ ~balance_sign_eq} & ~(balance==0 || balance_acc==0));
	/*verilator lint_on WIDTHEXPAND*/
	wire [3:0] balance_acc_new = invert_q_m ? balance_acc-balance_acc_inc : balance_acc+balance_acc_inc;
	wire [9:0] tmds_data = {invert_q_m, q_m[8], q_m[7:0] ^ {8{invert_q_m}}};
	wire [9:0] tmds_code = cd_i[1] ? (cd_i[0] ? 10'b1010101011 : 10'b0101010100) : (cd_i[0] ? 10'b0010101011 : 10'b1101010100);

	always_ff @(posedge clk, negedge rstn_i)
	begin
		if (!rstn_i)
			tmds_o <= '0;
		else
			tmds_o <= vde_i ? tmds_data : tmds_code;
	end

	always_ff @(posedge clk, negedge rstn_i)
	begin
		if (!rstn_i)
			balance_acc <= '0;
		else
			balance_acc <= vde_i ? balance_acc_new : 4'h0;
	end

endmodule: tmds_encoder
