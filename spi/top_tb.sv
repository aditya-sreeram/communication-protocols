`timescale 1ns/1ps
module top_tb;
    reg clk,new_data,reset;
    reg [11:0] din;
    wire done;
    wire [11:0]dout;
    
    //delete this
    // wire cs;
    // wire mosi;
    // wire sclk;

    top dut(.clk(clk),.new_data(new_data),.reset(reset),.din(din),.done(done),.dout(dout));

    // spi_master dut2(.clk(clk),.new_data(new_data),.reset(reset),.din(din),.cs(cs),.mosi(mosi),.sclk(sclk));

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
        din=12'd791;
        new_data=1;
        #100;
        new_data=0;
        #2000;
        $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

endmodule