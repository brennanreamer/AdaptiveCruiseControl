module FP_CruiseControl (input [5:0] initial_speed, speed_otherCar, input btn_enable, clk, brake, accel, input [3:0] distance, output cc_LED, LED_Warning, output reg [6:0] seg1_set_speed, seg2_set_speed, seg1_current_speed, seg2_current_speed, seg1_otherCar_speed, seg2_otherCar_speed);

reg seg_clk;
parameter MAX_COUNT = 10000000;
reg [23:0] count;

reg [5:0] set_speed;
//Clk
always @ (posedge clk) begin
	if (count < MAX_COUNT) begin
		count = count + 1;
	end else begin
		count <= 0;
		seg_clk <= ~seg_clk;
	end
end
/////////////////////////////////////////
//New State-Based Code

localparam A = 0, B = 1, C = 2, D = 3, E = 4;
reg [1:0] current_state, next_state;

always @ (posedge clk) begin
	if (reset) begin
		current_state <= A; //Initial State
	end else begin
		current_state <= next_state;
	end
end
//Next State
always @ (*) begin
	case (present_state)
		A: begin
			if (btn_enable == 0) begin
				next_state = B;
			end else begin
				next_state = A;
			end
		end
		B: begin
			if (brake == 0) begin
				next_state = A;
			end else if ((distance < 10) || ((speed_otherCar < current_speed) && (distance < 20))) begin
				next_state = E;
			end else if (current_speed > set_speed) begin
				next_state = C;
			end else if (current_speed < set_speed) begin
				next_state = D;
			end else begin
				next_state = B;
			end
		end
		C: begin
			if (brake == 0) begin
				next_state = A;
			if (current_speed <= set_speed || accel == 0) begin
				next_state = B;
			end else begin
				next_state = C;
			end
		end
		D: begin
			if (brake == 0) begin
				next_state = A;
			if (current_speed >= set_speed) begin
				next_state = B;
			end else begin
				next_state = D;
			end
		end
		E: begin
			if (brake == 0) begin
				next_state = A;
			if (distance >= 10 && speed_otherCar > current_speed) begin
				next_state = B;
			end else begin
				next_state = E;
			end
		end
	endcase	
end

//Output
always @ (*) begin
	cc_LED = 0; LED_Warning = 0; Z = 0; X = 0;
	case (current_state)
		A: cc_LED = 0; LED_Warning = 0; Z = 0; X = 0;
		B: cc_LED = 1; LED_Warning = 0; Z = 0; X = 0;
		C: cc_LED = 1; LED_Warning = 0; Z = 1; X = 0;
		D: cc_LED = 1; LED_Warning = 0; Z = 0; X = 1;
		E: cc_LED = 1; LED_Warning = 1; Z = 1; X = 0;
	endcase
end


















//////////////////////////////////////////
//Cruise Control Enable
always @ (*) begin
	if (btn_enable == 0) begin
		set_speed = initial_speed;
		cc_LED = 1;
	end
end
//Maintain Speed
always @ (posedge clk) begin
	if (initial_speed > set_speed) begin
		initial_speed = initial_speed - 1;
	end else if (initial_speed < set_speed) begin
		initial_speed = initial_speed + 1;
	end
end
//Brakes
always @ (posedge clk) begin
	if (brake == 1) begin
		cc_LED = 0;
		set_speed = 0;
		current_speed = current_speed - 1;
	end
end
//Accelerator
always @ (posedge clk) begin
	if (accel == 1) begin
		current_speed = current_speed + 1;
	end
end
//*Set/Input Speed
//7-seg 1
always @ (*) begin
	case (set_speed)
		0:seg1_set_speed = 7'b1000000;
		1:seg1_set_speed = 7'b1111001;
		2:seg1_set_speed = 7'b0100100;
		3:seg1_set_speed = 7'b0110000;
		4:seg1_set_speed = 7'b0011001;
		5:seg1_set_speed = 7'b0010010;
		6:seg1_set_speed = 7'b0000010;
		7:seg1_set_speed = 7'b1111000;
		8:seg1_set_speed = 7'b0000000;
		9:seg1_set_speed = 7'b0010000;
		default: seg1_set_speed = 7'b0000000;
	endcase
end
//7-seg 2
always @ (*) begin
case (set_speed)
0:seg2_set_speed = 7'b1000000;
1:seg2_set_speed = 7'b1111001;
2:seg2_set_speed = 7'b0100100;
3:seg2_set_speed = 7'b0110000;
4:seg2_set_speed = 7'b0011001;
5:seg2_set_speed = 7'b0010010;
6:seg2_set_speed = 7'b0000010;
default: seg2_set_speed = 7'b0000000;
endcase
end
//*Current Speed
//7-seg 1
always @ (*) begin
case (initial_speed)
0:seg1_current_speed = 7'b1000000;
1:seg1_current_speed = 7'b1111001;
2:seg1_current_speed = 7'b0100100;
3:seg1_current_speed = 7'b0110000;
4:seg1_current_speed = 7'b0011001;
5:seg1_current_speed = 7'b0010010;
6:seg1_current_speed = 7'b0000010;
7:seg1_current_speed = 7'b1111000;
8:seg1_current_speed = 7'b0000000;
9:seg1_current_speed = 7'b0010000;
default: seg1_current_speed = 7'b0000000;
endcase
end
//7-seg 2
always @ (*) begin
case (initial_speed)
0:seg2_current_speed = 7'b1000000;
1:seg2_current_speed = 7'b1111001;
2:seg2_current_speed = 7'b0100100;
3:seg2_current_speed = 7'b0110000;
4:seg2_current_speed = 7'b0011001;
5:seg2_current_speed = 7'b0010010;
6:seg2_current_speed = 7'b0000010;
default: seg2_current_speed = 7'b0000000;
endcase
end
//*Other Car
always @ (posedge clk) begin
if (distance <= 10) begin
current_speed = current_speed - 1;
LED_Warning = 1;
end else if (distance <= 20 && initial_speed > speed_otherCar) begin
current_speed = current_speed - 1;
LED_Warning = 1;
end
end
//speed_otherCar
//7-seg 1
always @ (*) begin
case (speed_otherCar)
0:seg1_otherCar_speed = 7'b1000000;
1:seg1_otherCar_speed = 7'b1111001;
2:seg1_otherCar_speed = 7'b0100100;
3:seg1_otherCar_speed = 7'b0110000;
4:seg1_otherCar_speed = 7'b0011001;
5:seg1_otherCar_speed = 7'b0010010;
6:seg1_otherCar_speed = 7'b0000010;
7:seg1_otherCar_speed = 7'b1111000;
8:seg1_otherCar_speed = 7'b0000000;
9:seg1_otherCar_speed = 7'b0010000;
default: seg1_otherCar_speed = 7'b0000000;
endcase
end
//7-seg 2
always @ (*) begin
case (speed_otherCar)
0:seg2_otherCar_speed = 7'b1000000;
1:seg2_otherCar_speed = 7'b1111001;
2:seg2_otherCar_speed = 7'b0100100;
3:seg2_otherCar_speed = 7'b0110000;
4:seg2_otherCar_speed = 7'b0011001;
5:seg2_otherCar_speed = 7'b0010010;
6:seg2_otherCar_speed = 7'b0000010;
default: seg2_otherCar_speed = 7'b0000000;
endcase
end
endmodule

