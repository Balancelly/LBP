// ================================================ //                      
//  Auther:      CHI-HSIANG,KU                      //                         
//  Filename:    LBP.v                               //                               
//  Date:        2024/06/01                         //     
// ================================================ //  

module LBP
(
	input 	 			clk,
	input 	 			rst,
	input 				enable,//gray ready
	output 	reg		[11:0] 	gray_addr,//12bit address
	output 	reg 			gray_OE,//1bit gray req
	input 	  		[7:0]  	gray_data,//8bit data
	
	output 	reg		[11:0]	lbp_addr,//12bit
    	output 	reg         		lbp_WEN,//1bit lbp valid
    	output 	reg [7:0] 		lbp_data,//8bit
	output	reg			finish//1bit
);

// put your design here

reg [4:0] entry_counter;
reg [1:0] lbp_counter_cal,lbp_counter_w;
reg [2:0] cs,ns;

reg [7:0] m;//8bit
reg [7:0] g_0,g_1,g_2,g_3,g_4,g_5,g_6,g_7;
reg [7:0] gc;

parameter idle=3'd0,read_s=3'd1,lbp_cal=3'd2,lbp_w=3'd3,z_w=3'd4,finish_st=3'd5;

always@(posedge clk or posedge rst)begin
	if(rst)begin
		cs<=idle;
	end
	else begin
		cs<=ns;
	end
end

//fsm 
always@(*)begin
	case(cs)
	idle://3'd0
	begin
		if(enable)begin
			ns=z_w;
		end
		else begin
			ns=idle;
		end
	end
	z_w:
	begin
		if(lbp_addr==12'd4095)begin
			ns=read_s;
		end
		else begin
			ns=z_w;
		end
	end	
	
	read_s://3'd1
	begin 
		if(entry_counter==5'd30)begin
		ns=lbp_cal;
		end
		else begin
		ns=read_s;
		end
	end
	lbp_cal:
	begin
		if(lbp_counter_cal==2'd2)begin
			ns=lbp_w;
		end
		else begin
			ns=lbp_cal;
		end
	end
	lbp_w:	
	begin 
		if(lbp_addr==12'd4033 &&lbp_counter_w==2'd1)begin
			ns=finish_st;
		end
		else if(lbp_addr!=12'd4033 && lbp_counter_w==2'd3)begin
			ns=read_s;
		end
		else begin	
			ns=lbp_w;
		end
	end
	finish_st:ns=idle;
	default: ns=read_s;
	endcase
end

//control gray_OE

always@(*) begin//當rst=0且cs=gray_r狀態，gray_read enable=1才能讀
	if(cs==read_s)begin
		gray_OE=1'b1;
	end
	else begin
		gray_OE=1'b0;
	end
end

//entry_index_counter
always@(posedge clk or posedge rst) begin
	if(rst)begin
		entry_counter<=5'd0;
	end
	else begin 
		if(gray_OE && entry_counter<5'd30)begin//counter only run in din==1
			entry_counter<=entry_counter+5'd1;//1clock+1
		end
		else begin
			entry_counter<=5'd0;
		end
	end
end



//gray_data
always@(posedge clk or posedge rst) begin
	if(rst)begin
		gray_addr<=12'd0;
		g_0<=8'd0;
		g_1<=8'd0;
		g_2<=8'd0;
		g_3<=8'd0;
		gc<=8'd0;
		g_4<=8'd0;
		g_5<=8'd0;
		g_6<=8'd0;
		g_7<=8'd0;
	end
	else begin
		if(gray_OE)begin
			if(entry_counter==5'd3)begin//
				if(gray_addr==12'd0)begin
					gray_addr<=gray_addr;
				end
				else begin
					if(gray_addr[5] & gray_addr[4] & gray_addr[3] & gray_addr[2] & gray_addr[1] & gray_addr[0])begin//63 127 191
						gray_addr<=gray_addr-12'd127;//gray addr =191-127=64
					end	
					else begin
						gray_addr<=gray_addr-12'd129;//gray addr =130-129=1
					end
				end
			end
			else if (entry_counter==5'd6)begin	
				gray_addr<=gray_addr+12'd1;//1
				g_0 <= gray_data;//
			end
			else if (entry_counter==5'd9)begin
				gray_addr<=gray_addr+12'd1;//2
				g_1<= gray_data; //
			end
			else if (entry_counter==5'd12)begin
				gray_addr<=gray_addr+12'd62;//64
				g_2 <= gray_data; //
			end
			else if (entry_counter==5'd15)begin
				gray_addr<=gray_addr+12'd1;//65
				g_3 <= gray_data; //
			end
			else if (entry_counter==5'd18)begin
				gray_addr<=gray_addr+12'd1;//66
				gc <= gray_data; //
			end
			else if (entry_counter==5'd21)begin
				gray_addr<=gray_addr+12'd62;//128
				g_4 <= gray_data; 
			end
			else if (entry_counter==5'd24)begin
				gray_addr<=gray_addr+12'd1;//129
				g_5 <= gray_data; 
			end
			else if (entry_counter==5'd27)begin
				gray_addr<=gray_addr+12'd1;//130
				g_6 <= gray_data; 
			end

			else if (entry_counter==5'd30)begin
				g_7 <= gray_data;

			end
			else begin
				gray_addr<=gray_addr;
			end
		end
		else begin
			gray_addr<=gray_addr;
		end
	end
end

always@(*)begin
	if(cs==z_w||(cs==lbp_w&&lbp_addr<12'd4033))begin //4033 off
		lbp_WEN=1'b1;
	end
	else begin
		lbp_WEN=1'b0;
	end
end


//lbp_counter_cal
always@(posedge clk or posedge rst) begin
	if(rst)begin
		lbp_counter_cal<=2'd0;
	end
	else begin 
		if(cs==lbp_cal && lbp_counter_cal<2'd2)begin//counter only run in din==1
			lbp_counter_cal<=lbp_counter_cal+2'd1;//1clock+1
		end
		else begin

			lbp_counter_cal<=2'd0;
		end
	end
end

//lbp_counter_w
always@(posedge clk or posedge rst) begin
	if(rst)begin
		lbp_counter_w<=2'd0;
	end
	else begin 
		if(cs==lbp_w && lbp_counter_w<2'd3)begin//counter only run in din==1
			lbp_counter_w<=lbp_counter_w+2'd1;//1clock+1
		end
		else begin
			lbp_counter_w<=2'd0;
		end
	end
end



//lbp address  lbp_data

	
always@(posedge clk or posedge rst)begin
	if(rst)begin
		lbp_addr<=12'd0;
	end
	else if(cs==z_w && lbp_WEN && lbp_addr<12'd4095)begin //cs=z_w 4'd12  //1state multi clock
		lbp_addr<=lbp_addr+12'd1;//last to 4095  0 to 4095==0
	end
	else if(cs==z_w && lbp_WEN && lbp_addr==12'd4095)begin //cs=z_w
		lbp_addr<=lbp_addr-12'd4030;//return to 65 because delay one clock
	end
	else if(cs==lbp_w &&lbp_counter_w==2'd3)begin// cs==lbp_w   data7==28  4'd11 30 0   cs
			if(lbp_addr[5]&	lbp_addr[4] &lbp_addr[3] & lbp_addr[2] & lbp_addr[1] & !lbp_addr[0])begin//126/190 111110
				lbp_addr<=lbp_addr+12'd3;
			end
			else begin
				lbp_addr<=lbp_addr+12'd1;
			end
	end
	else begin
		lbp_addr<=lbp_addr;
	end
end	
 
always@(posedge clk or posedge rst)begin
	if(rst)begin
		lbp_data<=8'd0;
	end
	else if(cs==z_w && lbp_WEN)begin //cs=z_w 5'd15
		lbp_data<=8'd0;
	end
	else if(cs==lbp_cal &&lbp_counter_cal==2'd1)begin// cs==lbp_w   data7==28  4'd11 30 0   buf
		lbp_data<=m;	
	end
	else begin
		lbp_data<=lbp_data;
	end
end	

//addr finish
always@(posedge clk or posedge rst)begin
	if(rst)begin
		finish<=1'b0;
	end
	else begin	
		if(cs==finish_st)begin
			finish<=1'b1;
		end
		else begin
			finish<=1'b0;
		end		
	end
end		
	
// lbp calculation 馬上算完mask值
always@(*)begin//lbp data cal
	if(g_0 < gc)begin
		m[0] = 1'b0;
	end
	else begin
		m[0] = 1'b1;
	end
	
	if(g_1 < gc)begin
		m[1] = 1'b0;
	end
	else begin
		m[1] = 1'b1;
	end
	
	if(g_2 < gc)begin
		m[2] = 1'b0;
	end
	else begin
		m[2]  = 1'b1;
	end
	
	if(g_3 < gc)begin
		m[3] = 1'b0;
	end
	else begin
		m[3] = 1'b1;
	end
	
	if(g_4 < gc)begin
		m[4] = 1'b0;
	end
	else begin
		m[4] = 1'b1;
	end
	
	if(g_5 < gc)begin
		m[5] = 1'b0;
	end
	else begin
		m[5] = 1'b1;
	end
	
	if(g_6 < gc)begin
		m[6] = 1'b0;
	end
	else begin
		m[6] = 1'b1;
	end
	
	if(g_7 < gc)begin
		m[7] = 1'b0;
	end
	else begin
		m[7] = 1'b1;
	end
end
endmodule
