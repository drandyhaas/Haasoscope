// from http://www.sparxeng.com/blog/software/communicating-with-your-cyclone-ii-fpga-over-serial-port-part-3-number-crunching

module processor_slave(clk, rxReady, rxData, txBusy, txStart, txData, readdata, newgotdata, gotdata);
  input clk;
  input[7:0] rxData;
  input rxReady;
  input txBusy;
  output reg txStart;
  output reg[7:0] txData;
  output reg[7:0] readdata;//first byte we got
  input newgotdata;//from other processor
  input[7:0] gotdata;
  
  localparam READ=0, SOLVING=1, WRITE1=2, WRITE2=3;
  localparam LEN = 1;
  localparam LENMAX = LEN - 1;

  integer ioCount;
  reg[7:0] data[0:LENMAX];
  integer state;

  initial begin
    state = READ;
  end

  always @(posedge clk) begin
    case (state)
	 
      READ: begin
		  txStart = 0;
        if (rxReady) begin
          data[ioCount] = rxData;
			 if (ioCount == 0) readdata = rxData;
          if (ioCount == LENMAX) begin
            ioCount = 0;
            state = SOLVING;
          end else begin
            ioCount = ioCount + 1;
          end
        end
		  	if (newgotdata) begin
				ioCount = 0;
				data[0]=gotdata;
				state=WRITE1;
			end
      end

      SOLVING: begin
		  begin
          //if (readdata == 49) get_ext_data=1;
        end
		  state=READ;
        //state = WRITE1;
      end

      WRITE1: begin
        if (!txBusy) begin
          txData = data[ioCount];
          txStart = 1;
          state = WRITE2;
        end
      end

      WRITE2: begin
        txStart = 0;
        if (ioCount != LENMAX) begin
          ioCount = ioCount + 1;
          state = WRITE1;
        end else begin
          ioCount = 0;
          state = READ;
        end
      end
		
    endcase
	 
  end
endmodule
