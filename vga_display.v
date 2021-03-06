module vga_display(
	input 				vga_clk,	//VGA驱动时钟
	input				sys_rst_n,	//复位信号
	input 				sta_en,		
	
	input		[3:0]	direct_x,	//操纵方向,0：上，1：左，2：右，3：下
	input		[9:0] 	pixel_xpos,	//像素点横坐标
	input		[9:0]	pixel_ypos,	//像素点纵坐标
	output 	reg	[2:0]	pixel_data	//像素点数据
	);
//parameter define
parameter	H_DISP	= 10'd640;		//分辨率—行
parameter	V_DISP	= 10'd480;		//分辨率—列

localparam	SIDE_W	= 10'd20;		//边框宽度
localparam	BLOCK_W	= 10'd20;		//方块宽度



localparam POS_X = 10'd0;
localparam POS_Y = 10'd160;
localparam WIDTH = 10'd640;
localparam HEIGHT = 10'd160;

//颜色
localparam	BLACK	= 3'b000;
localparam	BLUE	= 3'b001;
localparam	RED		= 3'b010;
localparam	PIN		= 3'b011;
localparam	GREEN	= 3'b100;
localparam	INDIGO	= 3'b101;
localparam	YELLOW	= 3'b110;
localparam	WHITE	= 3'b111;

//reg define	
reg [9:0] 	block_x	[31:0];	    	//蛇方块左上角横坐标
reg [9:0]	block_y	[31:0];		    //蛇方块左上角纵坐标
reg	[5:0]	block_l;				//蛇身区域长度
reg [21:0] 	div_cnt;				//时钟分频计数器
reg [1:0]	direct_s;				//前进方向,00：上，01：左，10：右，11：下
reg	[9:0]	rb;                     //蛇头所在位置	
reg [31:0] r[23:0];
reg gameover;
reg num_en;                         //生成苹果使能信号
reg [6:0]	qx,qy;

reg [63:0] char[15:0];
//wire define
wire move_en;						//方块移动使能信号
wire[9:0] x_cnt;
wire[9:0] y_cnt;

assign x_cnt = pixel_xpos - POS_X;
assign y_cnt = pixel_ypos - POS_Y;

//initial
initial begin
block_l <= 10'd3;
rb <= 10'd0;
qx <= 4'd8;
qy <= 4'd5;
r[0]  <= 32'b11111111111111111111111111111111;
r[1]  <= 32'b11111111111111111111111111111111;
r[2]  <= 32'b11000000000000000000000000000011;
r[3]  <= 32'b11000000000000000000000000000011;
r[4]  <= 32'b11000000000000000000000000000011;
r[5]  <= 32'b11000000000000000000000000000011;
r[6]  <= 32'b11000000000000000000000000000011;
r[7]  <= 32'b11000000000000000000000000000011;
r[8]  <= 32'b11000000000000000000000000000011;
r[9]  <= 32'b11000000000000000000000000000011;
r[10] <= 32'b11000000000000000000000000000011;
r[11] <= 32'b11000000000000000000000000000011;
r[12] <= 32'b11000000000000000000000000000011;
r[13] <= 32'b11000000000000000000000000000011;
r[14] <= 32'b11000000000000000000000000000011;
r[15] <= 32'b11000000000000000000000000000011;
r[16] <= 32'b11000000000000000000000000000011;
r[17] <= 32'b11000000000000000000000000000011;
r[18] <= 32'b11000000000000000000000000000011;
r[19] <= 32'b11000000000000000000000000000011;
r[20] <= 32'b11000000000000000000000000000011;
r[21] <= 32'b11000000000000000000000000000011;
r[22] <= 32'b11111111111111111111111111111111;
r[23] <= 32'b11111111111111111111111111111111;
end
//**********************************************************
//**                    main code
//**********************************************************
assign move_en = (div_cnt == 22'd25000000 - 1'b1)?1'b1 : 1'b0;

//通过对VGA驱动时钟技术，实现时钟分频
always @(posedge vga_clk or negedge sys_rst_n) 
begin
	if(!sys_rst_n)
		div_cnt <= 22'd0;
	else 
		begin
			if(div_cnt < 22'd25000000 - 1'b1)
				div_cnt <= div_cnt + 1'b1;
			else
				div_cnt <= 22'd0;
		end
end

//通过按键控制蛇前进方向
always @(posedge vga_clk or negedge sys_rst_n) 
begin
	if(!sys_rst_n)
		direct_s <= 2'd00;
	else begin//前进方向,00：上，01：左，10：右，11：下
		
		if(direct_s == 2'b00)//运动方向为上
			if(direct_x == 4'b1101) direct_s <= 2'b01;//输入方向为左
			else if(direct_x == 4'b1011) direct_s <= 2'b10;//输入方向为右
			else direct_s <= direct_s;
			
		else if	(direct_s == 2'b01)//运动方向为左
			if(direct_x == 4'b0111) direct_s <= 2'b11;//输入方向为下
			else if(direct_x == 4'b1110) direct_s <= 2'b00;//输入方向为上
			else direct_s <= direct_s;
			
		else if	(direct_s == 2'b10)//运动方向为右
			if(direct_x == 4'b1110) direct_s <= 2'b00;//输入方向为上
			else if(direct_x == 4'b0111) direct_s <= 2'b11;//输入方向为下
			else direct_s <= direct_s;
			
		else if	(direct_s == 2'b11)//运动方向为下
			if(direct_x == 4'b1011) direct_s <= 2'b10;//输入方向为右
			else if(direct_x == 4'b1101) direct_s <= 2'b01;//输入方向为左
			else direct_s <= direct_s;	
			
		else direct_s <= direct_s;
		end
end

//控制蛇前进
always @(posedge vga_clk or negedge sys_rst_n)
begin
	if(!sys_rst_n) 
	begin
		block_x[0] <= 10'd400;	    	//蛇方块左上角横坐标
		block_y[0] <= 10'd200;          //蛇方块左上角纵坐标
		block_l <= 10'd3;				//蛇身区域长度
		rb <= 10'd0;                    //蛇头所在位置	
		gameover = 0;
		qx <= 4'd8;
		qy <= 4'd5;
		r[0]  <= 32'b11111111111111111111111111111111;
		r[1]  <= 32'b11111111111111111111111111111111;
		r[2]  <= 32'b11000000000000000000000000000011;
		r[3]  <= 32'b11000000000000000000000000000011;
		r[4]  <= 32'b11000000000000000000000000000011;
		r[5]  <= 32'b11000000000000000000000000000011;
		r[6]  <= 32'b11000000000000000000000000000011;
		r[7]  <= 32'b11000000000000000000000000000011;
		r[8]  <= 32'b11000000000000000000000000000011;
		r[9]  <= 32'b11000000000000000000000000000011;
		r[10] <= 32'b11000000000000000000000000000011;
		r[11] <= 32'b11000000000000000000000000000011;
		r[12] <= 32'b11000000000000000000000000000011;
		r[13] <= 32'b11000000000000000000000000000011;
		r[14] <= 32'b11000000000000000000000000000011;
		r[15] <= 32'b11000000000000000000000000000011;
		r[16] <= 32'b11000000000000000000000000000011;
		r[17] <= 32'b11000000000000000000000000000011;
		r[18] <= 32'b11000000000000000000000000000011;
		r[19] <= 32'b11000000000000000000000000000011;
		r[20] <= 32'b11000000000000000000000000000011;
		r[21] <= 32'b11000000000000000000000000000011;
		r[22] <= 32'b11111111111111111111111111111111;
		r[23] <= 32'b11111111111111111111111111111111;
	end
	 
	else if(move_en && sta_en)
	begin
		rb = rb + 1;
		if(direct_s == 2'b00)//运动方向为上
			begin
			block_x[rb] = block_x[rb - 1];
			block_y[rb] = block_y[rb - 1] - 10'd20;
			end
			
		else if(direct_s == 2'b01)//运动方向为左
			begin
			block_x[rb] = block_x[rb-1] - 10'd20;
			block_y[rb] = block_y[rb-1];
			end
		
		else if(direct_s == 2'b10)//运动方向为右
			begin
			block_x[rb] = block_x[rb-1] + 10'd20;
			block_y[rb] = block_y[rb-1];
			end
		
		else if(direct_s == 2'b11)//运动方向为下
			begin
			block_x[rb] = block_x[rb-1];
			block_y[rb] = block_y[rb-1] + 10'd20;
			
			end
		if((r[block_y[rb]/20-1][block_x[rb]/20-1]==1)&&((block_y[rb]/20+1!=qy)||(block_x[rb]/20+1!=qx)))
			gameover=1;
		else if(block_y[rb]/20+1==qy && block_x[rb]/20+1==qx)
			begin
			block_l=block_l+1;
			num_en=1;
			r[block_y[rb]/20-1][block_x[rb]/20-1]=1;
			end 
		else
			begin
			r[block_y[rb]/20-1][block_x[rb]/20-1]=1;
			r[block_y[rb-block_l]/20-1][block_x[rb-block_l]/20-1]=0;
			end
		
		
		if(num_en == 1)
		begin
			case(qx)
				6'b000000: qx <= 6'b000100;
				6'b000100: qx <= 6'b001000;
				6'b001000: qx <= 6'b000111;
				6'b000111: qx <= 6'b000101;
				6'b000101: qx <= 6'b001010;
				6'b001010: qx <= 6'b001011;
				6'b001011: qx <= 6'b001111;
				6'b001111: qx <= 6'b001001;
				6'b001001: qx <= 6'b001100;
				6'b001100: qx <= 6'b010000;
				6'b010000: qx <= 6'b010010;
				6'b010010: qx <= 6'b011000;
				6'b011000: qx <= 6'b010101;
				6'b010101: qx <= 6'b010110;
				6'b010110: qx <= 6'b010111;
				6'b010111: qx <= 6'b010100;
				6'b010100: qx <= 6'b001101;
				6'b001101: qx <= 6'b001110;
				6'b001110: qx <= 6'b010001;
				6'b010001: qx <= 6'b010011;
				6'b010011: qx <= 6'b000100;
				default:   qx <= 6'b000100;
				endcase
				
				
				
				
				case(qy)
				6'b000000: qy <= 6'b000101;
				6'b000101: qy <= 6'b001010;
				6'b001010: qy <= 6'b001000;
				6'b001000: qy <= 6'b010000;
				6'b010000: qy <= 6'b001111;
				6'b001111: qy <= 6'b000100;
				6'b000100: qy <= 6'b000111;
				6'b000111: qy <= 6'b001001;
				6'b001001: qy <= 6'b001011;
				6'b001011: qy <= 6'b001100;
				6'b001100: qy <= 6'b001101;
				6'b001101: qy <= 6'b000110;
				6'b000110: qy <= 6'b001110;
				6'b001110: qy <= 6'b000101;
				default:   qy <= 6'b000101;
				endcase
			    num_en = 0;
		end
		
		
	end
end

always @(posedge vga_clk)
begin
	char[0]  <=64'h0000000000000000;
	char[1]  <=64'h0000000000000000;
	char[2]  <=64'h0000000000000000;
	char[3]  <=64'h0000001C0000003C;
	char[4]  <=64'h0000002200000022;
	char[5]  <=64'h0000004100000022;
	char[6]  <=64'h0000004100000001;
	char[7]  <=64'h773C77413C7F1C01;
	char[8]  <=64'h4C42224142922201;
	char[9]  <=64'h0442224142923071;
	char[10]  <=64'h047E14417E922C21;
	char[11]  <=64'h0402144102922222;
	char[12]  <=64'h0442082242923222;
	char[13]  <=64'h1F3C081C3CB76C1C;
	char[14]  <=64'h0000000000000000;
	char[15]  <=64'h0000000000000000;
	
	end

//显示
always @(posedge vga_clk or negedge sys_rst_n)
begin
	if(!sys_rst_n)
		pixel_data <= BLACK;
	else 
	begin
			if(gameover==0)
				begin
				if((pixel_xpos < SIDE_W) || (pixel_xpos >= H_DISP - SIDE_W)
				|| (pixel_ypos < SIDE_W) || (pixel_ypos >= V_DISP - SIDE_W))
					pixel_data <= BLUE;
				else 
					if(r[pixel_ypos/20][pixel_xpos/20] == 1) 
						pixel_data <= BLACK;
					else if((pixel_xpos/20+2)==qx && (pixel_ypos/20+2)==qy)
						pixel_data <= GREEN;
					else
						pixel_data <= WHITE;
				end
			else
				if((pixel_xpos >= POS_X) &&(pixel_xpos < POS_X + WIDTH)
					&&(pixel_ypos >= POS_Y) &&(pixel_ypos < POS_Y + HEIGHT))
					begin
					if(char[y_cnt/10][x_cnt/10])
						pixel_data <= WHITE;
					else
						pixel_data <= BLACK;
					end
				else
					pixel_data <= BLACK;
	end
end


endmodule
