module chain_delay(clk,start,stop,result);
input clk, start, stop;
parameter CHAIN_LEN = 200;
wire [CHAIN_LEN-2:0] input1 = {{CHAIN_LEN-2{1'b0}},start} /* synthesis keep */; // that's ...0000000 or ...00000001
wire [CHAIN_LEN-1:0] chain = {CHAIN_LEN-1{1'b1}} + input1 /* synthesis keep */; // that's 1111...1111, added to 1 or 0

// I think it works like this... 
// when start is 0:  011111111 + 0000 = 011111111
// when start goes to 1:  011111111 + 0001 = 100000000  i.e. 255+1=256
// before the operation completes: 011110000, so the more 0's, the longer it ran
// if it got to the end, the last bit should be a 1

output reg [CHAIN_LEN-1:0] result /* synthesis keep */;
always @(posedge stop) result<=chain;

endmodule
