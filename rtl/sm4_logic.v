//=====================================================================
//
// Designer   : zhou zaixin
//
// Description:
//   The SM4 top module 
//
// ====================================================================
`include "sm4_define.v"

module sm4_logic(

  input clk,
  input rst_n,
  input action,
  input start,
  input [127:0] text_in,
  input [127:0] key,
  output reg [127:0] text_out,
  output reg done
  );

  wire [31:0] rk;
  wire [31:0] rx;
  wire [31:0] cki;
  
  reg [4:0] round;
  
  reg [31:0] xi0;
  reg [31:0] xi1;
  reg [31:0] xi2;
  reg [31:0] xi3;
  
  reg [31:0] ki0;
  reg [31:0] ki1;
  reg [31:0] ki2;
  reg [31:0] ki3;
  
  reg [2:0] state;
  
  parameter IDLE  = 'd0;
  parameter LOOP0 = 'd1;
  parameter LOOP1 = 'd2;
  parameter LOOP2 = 'd3;
  parameter LOOP3 = 'd4; 
  parameter FINI  = 'd5;
  
  
  wire [31:0] mk0;
  wire [31:0] mk1;
  wire [31:0] mk2;
  wire [31:0] mk3;
  
  wire [31:0] k0;
  wire [31:0] k1;
  wire [31:0] k2;
  wire [31:0] k3;
  
  wire [31:0] t0;
  wire [31:0] t1;
  wire [31:0] t2;
  wire [31:0] t3;
 
  wire  [31:0] rk_reg;
 
  wire flag;
  
  assign {t0,t1,t2,t3} = text_in;
  assign {mk0,mk1,mk2,mk3} = key;
  
  assign k0 = mk0 ^ 32'hA3B1BAC6;
  assign k1 = mk1 ^ 32'h56AA3350;
  assign k2 = mk2 ^ 32'h677D9197;
  assign k3 = mk3 ^ 32'hB27022DC;
  
  assign rk_reg = (!action)? rk : ((flag ) ? ki0 : 32'h0);
  assign flag = (!action) ? 1'b0 : (state==LOOP3) ? 1'b1 : 1'b0; 
  
  always @ (posedge clk or negedge rst_n)
  begin
    if(!rst_n)
      begin
         round <= #2 5'd0;
         xi0 <= #2 32'h0;
         xi1 <= #2 32'h0;
         xi2 <= #2 32'h0;
         xi3 <= #2 32'h0;
         ki0 <= #2 32'h0;
         ki1 <= #2 32'h0;
         ki2 <= #2 32'h0;
         ki3 <= #2 32'h0;
         done <= #2 1'b0;
         
         text_out <= #2 128'h0;
         state <= #2 IDLE;
      end
    else
      begin
        case(state)
		      IDLE:
		          begin
					      if(start)
					        begin
						        if(action)
						          begin
						            {xi0,xi1,xi2,xi3} <= #2 {t0,t1,t2,t3};
							          {ki0,ki1,ki2,ki3} <= #2 {k0,k1,k2,k3};
							          round <= #2 5'd0;
							          state <= #2 LOOP1;
							          done <= #2 1'b0;
							         
						          end
						        else
						          begin
							          {xi0,xi1,xi2,xi3} <= #2 {t0,t1,t2,t3};
							          {ki0,ki1,ki2,ki3} <= #2 {k0,k1,k2,k3};
							          round <= #2 5'd0;
							          state <= #2 LOOP0;
							          done <= #2 1'b0;
						          end
					        end
					      else
					        begin
						        round <= #2 5'd0;
						        state <= #2 IDLE;
						        done <= #2 1'b0;
					        end
		          end
		      LOOP0:
		          begin
		            round <= #2 round + 1'b1;
		            if(round==5'd31)
		              begin
		                state <= #2 FINI;
		              end
		            else
		              begin
		                state <= #2 LOOP0;
		              end
		            {xi0,xi1,xi2,xi3} <= #2 {xi1,xi2,xi3,rx};
							  {ki0,ki1,ki2,ki3} <= #2 {ki1,ki2,ki3,rk};
							  done <= #2 1'b0;
		          end
		          
		      LOOP1:
		          begin
		            round <= #2 round + 1'b1;
		            if(round==5'd31)
		              begin
		                round <= #2 5'd31; 
		                state <= #2 LOOP2;
		              end
		            else
		              begin
		                state <= #2 LOOP1;
		              end
							  {ki0,ki1,ki2,ki3} <= #2 {ki1,ki2,ki3,rk};
							  done <= #2 1'b0;
		          end
		      
		      LOOP2:
		          begin
		            
		            {ki0,ki1,ki2,ki3} <= #2 {ki3,ki0,ki1,ki2};
							  state <= #2 LOOP3;
		          end    
		    
		      LOOP3:
		          begin
		            round <= #2 round - 1'b1;
		            if(round==0)
		              begin
		                state <= #2 FINI;
		              end
		            else
		              begin
		                state <= #2 LOOP3;
		              end
		            {xi0,xi1,xi2,xi3} <= #2 {xi1,xi2,xi3,rx};
							  {ki0,ki1,ki2,ki3} <= #2 {ki3,rk,ki1,ki2};
						    done <= #2 1'b0;
							 
		          end
		    
		      FINI:
		          begin
		            text_out <= #2 {xi3,xi2,xi1,xi0};
                state <= #2 IDLE;
                done <= #2 1'b1;
		          end
			    default:
			        begin
                state <= #2 IDLE;
                done <= #2 1'b1;
			        end
			  endcase
      end
    
  end
  
  SM4_Key_Expansion SM4_Key_Expansion_ware(.key({ki0,ki1,ki2,ki3}), .rk(rk), .cki(cki) );
  SM4_RoundCki SM4_RoundCki_ware(.round(round), .cki(cki) ); 
  SM4_F_Function SM4_F_Function_ware(.text_in({xi0,xi1,xi2,xi3}), .rk(rk_reg), .rx(rx) );
  
endmodule


module SM4_F_Function(text_in,rk,rx);
  input [127:0] text_in;
  input [31:0] rk;
  output[31:0] rx;
  
  wire [31:0] x0;
  wire [31:0] x1;
  wire [31:0] x2;
  wire [31:0] x3;
  
  wire [31:0] x_tmp;
  wire [31:0] y_tmp;
  
  assign {x0,x1,x2,x3} = text_in;
  assign x_tmp = x1 ^ x2 ^ x3 ^ rk;
  assign rx = x0 ^ y_tmp;
  
  SM4_T_Transform SM4_T_Transform_ware(.x(x_tmp),.y(y_tmp));
  
endmodule

module SM4_Key_Expansion(key,cki,rk);
  input [127:0] key;
  input [31:0] cki;
  output  [31:0] rk;
  
  wire [31:0] ki_0;
  wire [31:0] ki_1;
  wire [31:0] ki_2;
  wire [31:0] ki_3;
  
  assign {ki_0,ki_1,ki_2,ki_3} = key;
  
  wire [31:0] Ti_in;
  wire [31:0] Ti_out;
  
  SM4_Ti_Transform SM4_Ti_Transform_ware(.x(Ti_in),.y(Ti_out));
  assign Ti_in  = ki_1 ^ ki_2 ^ ki_3 ^ cki;
  
  assign rk = Ti_out ^ ki_0;
  
  
endmodule

module SM4_L_Transform(B,C);
  input  [31:0] B;
  output [31:0] C;
  
  wire [31:0] B_shift_left_02;
  wire [31:0] B_shift_left_10;
  wire [31:0] B_shift_left_18;
  wire [31:0] B_shift_left_24;
  
  assign B_shift_left_02 = {B[29:0],B[31:30]};
  assign B_shift_left_10 = {B[21:0],B[31:22]};
  assign B_shift_left_18 = {B[13:0],B[31:14]};
  assign B_shift_left_24 = {B[07:0],B[31:08]};
  
  assign C = B ^ B_shift_left_02 ^ B_shift_left_10 ^ B_shift_left_18 ^ B_shift_left_24;
  
endmodule


module SM4_Li_Transform(B,C);
  input  [31:0] B;
  output [31:0] C;
  
  wire [31:0] B_shift_left_13;
  wire [31:0] B_shift_left_23;
  
  assign B_shift_left_13 = {B[18:0],B[31:19]};
  assign B_shift_left_23 = {B[08:0],B[31:09]};
  
  assign C = B ^ B_shift_left_13 ^ B_shift_left_23;
  
endmodule


module SM4_RoundCki(round,cki);
   input [4:0] round;
   output reg [31:0] cki;
  
   always @ (round)
   begin
     case(round)
       5'h00 : cki = 32'h00070e15;
		   5'h01 : cki = 32'h1c232a31;
		   5'h02 : cki = 32'h383f464d;
		   5'h03 : cki = 32'h545b6269;
		   5'h04 : cki = 32'h70777e85;
		   5'h05 : cki = 32'h8c939aa1;
		   5'h06 : cki = 32'ha8afb6bd;
		   5'h07 : cki = 32'hc4cbd2d9;
		   5'h08 : cki = 32'he0e7eef5;
		   5'h09 : cki = 32'hfc030a11;
		   5'h0A : cki = 32'h181f262d;
		   5'h0B : cki = 32'h343b4249;
		   5'h0C : cki = 32'h50575e65;
		   5'h0D : cki = 32'h6c737a81;
		   5'h0E : cki = 32'h888f969d;
		   5'h0F : cki = 32'ha4abb2b9;
		   5'h10 : cki = 32'hc0c7ced5;
		   5'h11 : cki = 32'hdce3eaf1;
		   5'h12 : cki = 32'hf8ff060d;
		   5'h13 : cki = 32'h141b2229;
		   5'h14 : cki = 32'h30373e45;
		   5'h15 : cki = 32'h4c535a61;
		   5'h16 : cki = 32'h686f767d;
		   5'h17 : cki = 32'h848b9299;
		   5'h18 : cki = 32'ha0a7aeb5;
		   5'h19 : cki = 32'hbcc3cad1;
		   5'h1A : cki = 32'hd8dfe6ed;
		   5'h1B : cki = 32'hf4fb0209;
		   5'h1C : cki = 32'h10171e25;
		   5'h1D : cki = 32'h2c333a41;
		   5'h1E : cki = 32'h484f565d;
		   5'h1F : cki = 32'h646b7279;
		   default:cki = 32'h00000000;
		  endcase
   end
endmodule


module SM4_Sbox(x,y);
  
  input  [7:0] x;
  output [7:0] y;
  //--------------------
  reg [7:0] y;
  //--------------------
  
  always @(x) 
    begin
				case (x)
								8'h00 : y = 8'hD6;
								8'h01 : y = 8'h90;
								8'h02 : y = 8'hE9;
								8'h03 : y = 8'hFE;
								8'h04 : y = 8'hCC;
								8'h05 : y = 8'hE1;
								8'h06 : y = 8'h3D;
								8'h07 : y = 8'hB7;
								8'h08 : y = 8'h16;
								8'h09 : y = 8'hB6;
								8'h0A : y = 8'h14;
								8'h0B : y = 8'hC2;
								8'h0C : y = 8'h28;
								8'h0D : y = 8'hFB;
								8'h0E : y = 8'h2C;
								8'h0F : y = 8'h05;
								8'h10 : y = 8'h2B;
								8'h11 : y = 8'h67;
								8'h12 : y = 8'h9A;
								8'h13 : y = 8'h76;
								8'h14 : y = 8'h2A;
								8'h15 : y = 8'hBE;
								8'h16 : y = 8'h04;
								8'h17 : y = 8'hC3;
								8'h18 : y = 8'hAA;
								8'h19 : y = 8'h44;
								8'h1A : y = 8'h13;
								8'h1B : y = 8'h26;
								8'h1C : y = 8'h49;
								8'h1D : y = 8'h86;
								8'h1E : y = 8'h06;
								8'h1F : y = 8'h99;
								8'h20 : y = 8'h9C;
								8'h21 : y = 8'h42;
								8'h22 : y = 8'h50;
								8'h23 : y = 8'hF4;
								8'h24 : y = 8'h91;
								8'h25 : y = 8'hEF;
								8'h26 : y = 8'h98;
								8'h27 : y = 8'h7A;
								8'h28 : y = 8'h33;
								8'h29 : y = 8'h54;
								8'h2A : y = 8'h0B;
								8'h2B : y = 8'h43;
								8'h2C : y = 8'hED;
								8'h2D : y = 8'hCF;
								8'h2E : y = 8'hAC;
								8'h2F : y = 8'h62;
								8'h30 : y = 8'hE4;
								8'h31 : y = 8'hB3;
								8'h32 : y = 8'h1C;
								8'h33 : y = 8'hA9;
								8'h34 : y = 8'hC9;
								8'h35 : y = 8'h08;
								8'h36 : y = 8'hE8;
								8'h37 : y = 8'h95;
								8'h38 : y = 8'h80;
								8'h39 : y = 8'hDF;
								8'h3A : y = 8'h94;
								8'h3B : y = 8'hFA;
								8'h3C : y = 8'h75;
								8'h3D : y = 8'h8F;
								8'h3E : y = 8'h3F;
								8'h3F : y = 8'hA6;
								8'h40 : y = 8'h47;
								8'h41 : y = 8'h07;
								8'h42 : y = 8'hA7;
								8'h43 : y = 8'hFC;
								8'h44 : y = 8'hF3;
								8'h45 : y = 8'h73;
								8'h46 : y = 8'h17;
								8'h47 : y = 8'hBA;
								8'h48 : y = 8'h83;
								8'h49 : y = 8'h59;
								8'h4A : y = 8'h3C;
								8'h4B : y = 8'h19;
								8'h4C : y = 8'hE6;
								8'h4D : y = 8'h85;
								8'h4E : y = 8'h4F;
								8'h4F : y = 8'hA8;
								8'h50 : y = 8'h68;
								8'h51 : y = 8'h6B;
								8'h52 : y = 8'h81;
								8'h53 : y = 8'hB2;
								8'h54 : y = 8'h71;
								8'h55 : y = 8'h64;
								8'h56 : y = 8'hDA;
								8'h57 : y = 8'h8B;
								8'h58 : y = 8'hF8;
								8'h59 : y = 8'hEB;
								8'h5A : y = 8'h0F;
								8'h5B : y = 8'h4B;
								8'h5C : y = 8'h70;
								8'h5D : y = 8'h56;
								8'h5E : y = 8'h9D;
								8'h5F : y = 8'h35;
								8'h60 : y = 8'h1E;
								8'h61 : y = 8'h24;
								8'h62 : y = 8'h0E;
								8'h63 : y = 8'h5E;
								8'h64 : y = 8'h63;
								8'h65 : y = 8'h58;
								8'h66 : y = 8'hD1;
								8'h67 : y = 8'hA2;
								8'h68 : y = 8'h25;
								8'h69 : y = 8'h22;
								8'h6A : y = 8'h7C;
								8'h6B : y = 8'h3B;
								8'h6C : y = 8'h01;
								8'h6D : y = 8'h21;
								8'h6E : y = 8'h78;
								8'h6F : y = 8'h87;
								8'h70 : y = 8'hD4;
								8'h71 : y = 8'h00;
								8'h72 : y = 8'h46;
								8'h73 : y = 8'h57;
								8'h74 : y = 8'h9F;
								8'h75 : y = 8'hD3;
								8'h76 : y = 8'h27;
								8'h77 : y = 8'h52;
								8'h78 : y = 8'h4C;
								8'h79 : y = 8'h36;
								8'h7A : y = 8'h02;
								8'h7B : y = 8'hE7;
								8'h7C : y = 8'hA0;
								8'h7D : y = 8'hC4;
								8'h7E : y = 8'hC8;
								8'h7F : y = 8'h9E;
								8'h80 : y = 8'hEA;
								8'h81 : y = 8'hBF;
								8'h82 : y = 8'h8A;
								8'h83 : y = 8'hD2;
								8'h84 : y = 8'h40;
								8'h85 : y = 8'hC7;
								8'h86 : y = 8'h38;
								8'h87 : y = 8'hB5;
								8'h88 : y = 8'hA3;
								8'h89 : y = 8'hF7;
								8'h8A : y = 8'hF2;
								8'h8B : y = 8'hCE;
								8'h8C : y = 8'hF9;
								8'h8D : y = 8'h61;
								8'h8E : y = 8'h15;
								8'h8F : y = 8'hA1;
								8'h90 : y = 8'hE0;
								8'h91 : y = 8'hAE;
								8'h92 : y = 8'h5D;
								8'h93 : y = 8'hA4;
								8'h94 : y = 8'h9B;
								8'h95 : y = 8'h34;
								8'h96 : y = 8'h1A;
								8'h97 : y = 8'h55;
								8'h98 : y = 8'hAD;
								8'h99 : y = 8'h93;
								8'h9A : y = 8'h32;
								8'h9B : y = 8'h30;
								8'h9C : y = 8'hF5;
								8'h9D : y = 8'h8C;
								8'h9E : y = 8'hB1;
								8'h9F : y = 8'hE3;
								8'hA0 : y = 8'h1D;
								8'hA1 : y = 8'hF6;
								8'hA2 : y = 8'hE2;
								8'hA3 : y = 8'h2E;
								8'hA4 : y = 8'h82;
								8'hA5 : y = 8'h66;
								8'hA6 : y = 8'hCA;
								8'hA7 : y = 8'h60;
								8'hA8 : y = 8'hC0;
								8'hA9 : y = 8'h29;
								8'hAA : y = 8'h23;
								8'hAB : y = 8'hAB;
								8'hAC : y = 8'h0D;
								8'hAD : y = 8'h53;
								8'hAE : y = 8'h4E;
								8'hAF : y = 8'h6F;
								8'hB0 : y = 8'hD5;
								8'hB1 : y = 8'hDB;
								8'hB2 : y = 8'h37;
								8'hB3 : y = 8'h45;
								8'hB4 : y = 8'hDE;
								8'hB5 : y = 8'hFD;
								8'hB6 : y = 8'h8E;
								8'hB7 : y = 8'h2F;
								8'hB8 : y = 8'h03;
								8'hB9 : y = 8'hFF;
								8'hBA : y = 8'h6A;
								8'hBB : y = 8'h72;
								8'hBC : y = 8'h6D;
								8'hBD : y = 8'h6C;
								8'hBE : y = 8'h5B;
								8'hBF : y = 8'h51;
								8'hC0 : y = 8'h8D;
								8'hC1 : y = 8'h1B;
								8'hC2 : y = 8'hAF;
								8'hC3 : y = 8'h92;
								8'hC4 : y = 8'hBB;
								8'hC5 : y = 8'hDD;
								8'hC6 : y = 8'hBC;
								8'hC7 : y = 8'h7F;
								8'hC8 : y = 8'h11;
								8'hC9 : y = 8'hD9;
								8'hCA : y = 8'h5C;
								8'hCB : y = 8'h41;
								8'hCC : y = 8'h1F;
								8'hCD : y = 8'h10;
								8'hCE : y = 8'h5A;
								8'hCF : y = 8'hD8;
								8'hD0 : y = 8'h0A;
								8'hD1 : y = 8'hC1;
								8'hD2 : y = 8'h31;
								8'hD3 : y = 8'h88;
								8'hD4 : y = 8'hA5;
								8'hD5 : y = 8'hCD;
								8'hD6 : y = 8'h7B;
								8'hD7 : y = 8'hBD;
								8'hD8 : y = 8'h2D;
								8'hD9 : y = 8'h74;
								8'hDA : y = 8'hD0;
								8'hDB : y = 8'h12;
								8'hDC : y = 8'hB8;
								8'hDD : y = 8'hE5;
								8'hDE : y = 8'hB4;
								8'hDF : y = 8'hB0;
								8'hE0 : y = 8'h89;
								8'hE1 : y = 8'h69;
								8'hE2 : y = 8'h97;
								8'hE3 : y = 8'h4A;
								8'hE4 : y = 8'h0C;
								8'hE5 : y = 8'h96;
								8'hE6 : y = 8'h77;
								8'hE7 : y = 8'h7E;
								8'hE8 : y = 8'h65;
								8'hE9 : y = 8'hB9;
								8'hEA : y = 8'hF1;
								8'hEB : y = 8'h09;
								8'hEC : y = 8'hC5;
								8'hED : y = 8'h6E;
								8'hEE : y = 8'hC6;
								8'hEF : y = 8'h84;
								8'hF0 : y = 8'h18;
								8'hF1 : y = 8'hF0;
								8'hF2 : y = 8'h7D;
								8'hF3 : y = 8'hEC;
								8'hF4 : y = 8'h3A;
								8'hF5 : y = 8'hDC;
								8'hF6 : y = 8'h4D;
								8'hF7 : y = 8'h20;
								8'hF8 : y = 8'h79;
								8'hF9 : y = 8'hEE;
								8'hFA : y = 8'h5F;
								8'hFB : y = 8'h3E;
								8'hFC : y = 8'hD7;
								8'hFD : y = 8'hCB;
								8'hFE : y = 8'h39;
								8'hFF : y = 8'h48;
								default : y = 8'h00;
				endcase
    end

endmodule


module SM4_T_Transform(x,y);
  
  input [31:0] x;
  output[31:0] y;
  
  wire [31:0] B;
  
  SM4_Tau_Transform SM4_Tau_Transform_ware(.A(x),.B(B));
  SM4_L_Transform SM4_L_Transform_ware(.B(B),.C(y));
  
endmodule

module SM4_Tau_Transform(A,B);
  input  [31:0] A;
  output [31:0] B;
  
  wire [7:0] a0;
  wire [7:0] a1;
  wire [7:0] a2;
  wire [7:0] a3;
  
  wire [7:0] b0;
  wire [7:0] b1;
  wire [7:0] b2;
  wire [7:0] b3;
  
  assign {a0,a1,a2,a3} = A;
  
  SM4_Sbox SM4_Sbox_ware0(.x(a0),.y(b0));
  SM4_Sbox SM4_Sbox_ware1(.x(a1),.y(b1));
  SM4_Sbox SM4_Sbox_ware2(.x(a2),.y(b2));
  SM4_Sbox SM4_Sbox_ware3(.x(a3),.y(b3));
  
  assign B = {b0,b1,b2,b3};
  
  
endmodule


module SM4_Ti_Transform(x,y);
  
  input [31:0] x;
  output[31:0] y;
  
  wire [31:0] B;
  
  SM4_Tau_Transform SM4_Tau_Transform_ware(.A(x),.B(B));
  SM4_Li_Transform SM4_Li_Transform_ware(.B(B),.C(y));
  
endmodule
