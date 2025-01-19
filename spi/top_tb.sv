`timescale 1ns/1ps
module top_tb;
    reg clk,new_data,reset;
    reg [11:0] din;
    wire done;
    wire [11:0]dout;

    top dut(.clk(clk),.new_data(new_data),.din(din),.done(done),.dout(dout));

    initial begin
        {clk,new_data,reset,din}<=0;
        forever begin
            #5;
            clk=~clk;
        end
    end

    initial begin
      @(negedge clk)
        reset=1;
      @(negedge clk)
        reset=0;
        #100;
      @(negedge clk)
        din=12'd5;
        new_data=1;
        #500;
        $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

endmodule