`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/11/2024 03:21:25 PM
// Design Name: 
// Module Name: lecture7
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fsm(
    input clk,
    input reset,
    input pd1,
    input pd2,
    output reg [1:0] state,
    output reg [7:0] occupancy
    );
    
    parameter IDLE = 0;
    parameter ENTER = 1;
    parameter EXIT = 2;
    
    reg [1:0] next_state;
    reg [7:0] next_occupancy;
    
    always @(posedge clk or posedge reset)
      if (reset) begin
        state <= IDLE;
        occupancy <= 0;
     end else begin
        state <= next_state;
        occupancy <= next_occupancy;
     end
    
    always @(*)
    begin
       next_state = state;  // default to current state
       next_occupancy = occupancy;  // default to current occupancy
       case (state)
         IDLE: 
            begin
               if (pd1) 
                 next_state = ENTER;
               else if (pd2)
                 next_state = EXIT;
            end
         ENTER:
            begin
              if (pd2) begin
                  next_state = IDLE;
                  next_occupancy = occupancy + 1;
                end
            end
         EXIT:
           begin
             if (pd1) begin
                 next_state = IDLE;
                 if (occupancy > 0)
                    next_occupancy = occupancy - 1;
                end
           end
         default: begin
         end
       endcase
     end  
       
    
endmodule


module button_pulse(
		    input clk,
		    input raw_button,
		    output button_pulse
		    );
    
    localparam N = 3;
    
    reg [N - 1:0] Q_reg;
    
    always @(posedge clk)
    begin
        Q_reg <= {Q_reg[N - 2:0], raw_button};
    end
    
    assign button_pulse = (&Q_reg[N - 2:0]) & ~Q_reg[N-1];
endmodule
  

module lecture7(
      input clk,
      input reset,
      input pd1_button,
      input pd2_button,
      output [1:0] fsm_state,
      output [6:0] inv_leds,
      output [7:0] enb_leds  
    );
    
    wire pd1, pd2;
    wire [7:0] occupancy;
    wire [11:0] occ_bcd;
    
    button_pulse u_pd1 (clk, pd1_button, pd1);
    button_pulse u_pd2 (clk, pd2_button, pd2);
 
    fsm u1_fsm (clk, reset, pd1, pd2, fsm_state, occupancy);
        
   doubdab u5 (occupancy, occ_bcd);
   sseg u6 (clk, occ_bcd, 1'b0, inv_leds, enb_leds);

endmodule


module sseg(
    input clk,
    input [11:0] b_in,
    input sign,
    output [6:0] inv_leds,
    output [7:0] enb_leds 
    );
    
    wire [6:0] leds;
    wire [3:0] b_sel;
    wire [1:0] cnt;

    cnt_4digs u3 (.clk(clk), .cnt(cnt));
    decode_enb u4 (.cnt(cnt), .enb_leds(enb_leds));
    mux_dig u5 (.cnt(cnt), .sign(sign), .b_in(b_in), .b_sel(b_sel));

    bin_to_leds u1 (.b_in(b_sel), .leds(leds));
    invert7 u2 (.a(leds), .x(inv_leds));
endmodule

module cnt_4digs(
    input clk,
    output [1:0] cnt
    );
    
    reg [15:0] cntbig;
    
    always @(posedge clk)
    begin
        cntbig <= cntbig + 1;
    end
    
    assign cnt = cntbig[15:14];
endmodule    

module mux_dig(
    input [1:0] cnt,
    input [11:0] b_in,
    input sign,
    output reg [3:0] b_sel
    );
    
    always @(cnt)
        case(cnt)
            0: b_sel = b_in[3:0];
            1: b_sel = b_in[7:4];
            2: b_sel = b_in[11:8];
            3: if(sign) b_sel = 4'b1111; 
               else b_sel = 4'b1110;
        endcase
endmodule    

module decode_enb(
    input [1:0] cnt,
    output reg [7:0] enb_leds
    );

    always @(cnt)
        case(cnt)
            0: enb_leds = 8'b11111110;
            1: enb_leds = 8'b11111101;
            2: enb_leds = 8'b11111011;
            3: enb_leds = 8'b11110111;
        endcase    
endmodule

module invert7(
    input [6:0] a,
    output [6:0] x  
    );
    assign x = ~a;
endmodule

module bin_to_leds(
    input [3:0] b_in,
    output reg [6:0] leds  
    );
    
    always @(b_in)
        case(b_in)
            0: leds = 7'b0111111;
            1: leds = 7'b0000110;
            2: leds = 7'b1011011;
            3: leds = 7'b1001111;
            4: leds = 7'b1100110;
            5: leds = 7'b1101101;
            6: leds = 7'b1111101;
            7: leds = 7'b0000111;
            8: leds = 7'b1111111;
            9: leds = 7'b1101111;
            14: leds = 7'b0000000;  // off
            15: leds = 7'b1000000;  // minus sign
            default: leds = 7'bxxxxxxx;
        endcase
endmodule


module dd_add3(
    input [3:0] i,
    output reg [3:0] o
    );

    always @(*)
        case(i)
            0: o = 0;
            1: o = 1;
            2: o = 2;
            3: o = 3;
            4: o = 4;
            5: o = 8;
            6: o = 9;
            7: o = 10;
            8: o = 11;
            9: o = 12;
            default: o = 0;
         endcase

endmodule

module doubdab(
    input [7:0] b_in,
    output [11:0] b_out
    );
    
    wire [11:0] a0, a1, a2, a3, a4, a5;
    
    assign a0 = {4'b0,b_in};
    
    dd_add3 u1 (a0[8:5],a1[8:5]);
    assign a1[11:9] = a0[11:9];    
    assign a1[4:0] = a0[4:0];
    
    dd_add3 u2 (a1[7:4],a2[7:4]);
    assign a2[11:8] = a1[11:8];    
    assign a2[3:0] = a1[3:0];

    dd_add3 u3 (a2[6:3],a3[6:3]);
    assign a3[11:7] = a2[11:7];    
    assign a3[2:0] = a2[2:0];
    
    dd_add3 u4 (a3[5:2],a4[5:2]);
    dd_add3 u6 (a3[9:6],a4[9:6]);
    assign a4[11:10] = a3[11:10];    
    assign a4[1:0] = a3[1:0]; 
    
    dd_add3 u5 (a4[4:1],a5[4:1]);
    dd_add3 u7 (a4[8:5],a5[8:5]);
    assign a5[11:9] = a4[11:9];    
    assign a5[0] = a4[0]; 
     
    assign b_out = a5;
    
endmodule

