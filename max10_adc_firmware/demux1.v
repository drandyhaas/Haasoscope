//Verilog module for 1:2 DEMUX
module demux1to2(     Data_in,     sel,    Data_out_0,    Data_out_1    );

//list the inputs and their sizes
    input Data_in;
    input sel;
//list the outputs and their sizes 
    output Data_out_0;
    output Data_out_1;
//Internal variables
    reg Data_out_0;
    reg Data_out_1;

//always block with Data_in and sel in its sensitivity list
    always @(Data_in or sel)
    begin
        case (sel)
            1'b0 : begin
                        Data_out_0 = Data_in;
                        Data_out_1 = 0;
                      end
            1'b1 : begin
                        Data_out_0 = 0;
                        Data_out_1 = Data_in;
                      end
        endcase
    end
    
endmodule
