module mball(clk, BouncingObject, inotherball, CounterX, CounterY, ballX, ballY, inball, ballspeed, ballmass);
input clk;
input BouncingObject;
input inotherball;
input [9:0] CounterX;
input [8:0] CounterY;
parameter [9:0] startX;
parameter [8:0] startY;
parameter ballsize = 5;
parameter twoballsize = 2*ballsize;
output reg [9:0] ballX;
output reg [8:0] ballY;
output reg [8:0] ballspeed;
parameter [8:0] pballmass;
parameter [8:0] pballspeed;

output [8:0] ballmass = pballmass;//just set to the input parameter

reg ball_inX, ball_inY;
always @(posedge clk)
if(ball_inX==0) ball_inX <= (CounterX==ballX) & ball_inY; else ball_inX <= !(CounterX==ballX+twoballsize);
always @(posedge clk)
if(ball_inY==0) ball_inY <= (CounterY==ballY); else ball_inY <= !(CounterY==ballY+twoballsize);
output inball = ball_inX & ball_inY;

initial begin
    ballX<=startX;
	 ballY<=startY;
	 ball_dirX <= startX%2;
	 ball_dirY <= startY%2;
	 ballspeed<=pballspeed;
end

reg ResetCollision;
always @(posedge clk) ResetCollision <= (CounterY==500) & (CounterX==0);  // active only once for every video frame

reg CollisionX1, CollisionX2, CollisionY1, CollisionY2;
always @(posedge clk) if(ResetCollision) CollisionX1<=0; else if(BouncingObject & (CounterX==ballX   ) & (CounterY==ballY+ballsize)) CollisionX1<=1;
always @(posedge clk) if(ResetCollision) CollisionX2<=0; else if(BouncingObject & (CounterX==ballX+twoballsize) & (CounterY==ballY+ballsize)) CollisionX2<=1;
always @(posedge clk) if(ResetCollision) CollisionY1<=0; else if(BouncingObject & (CounterX==ballX+ballsize) & (CounterY==ballY   )) CollisionY1<=1;
always @(posedge clk) if(ResetCollision) CollisionY2<=0; else if(BouncingObject & (CounterX==ballX+ballsize) & (CounterY==ballY+twoballsize)) CollisionY2<=1;

wire UpdateBallPosition = ResetCollision;  // update the ball position at the same time that we reset the collision detectors

reg ballcollision;
always @(posedge clk) if(ResetCollision) ballcollision<=0; else if (inotherball) ballcollision<=1;//inotherball;

reg ball_dirX, ball_dirY;
always @(posedge clk) begin
	if(UpdateBallPosition) begin
		if(~(CollisionX1 & CollisionX2))        // if collision on both X-sides, don't move in the X direction
		begin
			if (ballcollision) begin
			   ball_dirX = !ball_dirX;
				ballspeed = 1+((ballspeed+1)%2);//ballcollision;///ballmass; // v=p/m
			end
			ballX = ballX + (ball_dirX ? -ballspeed : ballspeed);
			if (CollisionX2) ball_dirX <= 1; else if (CollisionX1) ball_dirX <= 0;
		end
	
		if(~(CollisionY1 & CollisionY2))        // if collision on both Y-sides, don't move in the Y direction
		begin
			ballY <= ballY + (ball_dirY ? -1 : 1);
			if (CollisionY2) ball_dirY <= 1; else if (CollisionY1) ball_dirY <= 0;
		end
	end
end

endmodule
