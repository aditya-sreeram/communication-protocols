`timescale 1ns/1ps
module top_tb;
    reg clk,new_data,reset;
    reg [11:0] din;
    wire done;
    wire [11:0]dout;
    
    

    top dut(.clk(clk),.new_data(new_data),.reset(reset),.din(din),.done(done),.dout(dout));

    wire sclk;

    assign sclk = dut.master_dut.sclk;


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
        
      @(posedge sclk)
        new_data<=1;
        din<=12'd791;
      @(posedge sclk)
        new_data<=0;
      @(posedge done)
      @(posedge sclk)
        $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

endmodule