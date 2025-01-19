module spi_master(
    input clk,reset,new_data,
    input [11:0]din,
    output reg cs,mosi,sclk
);

    int count_sclk=0;//for sclk 10 count
    int count_tx=0;//for transmission 12 count

    reg [11:0] temp;

  typedef enum bit {idle=1'b0,send=1'b1} spi_state;

    spi_state state = idle; 

    //sclk generation

    always @(posedge clk) begin
        if(reset) begin
            count_sclk<=0;
            count_tx<=0;

            cs<=0;
        end
        else begin
            if(count_sclk<5) count_sclk<=count_sclk+1;
            else begin
                sclk<=~sclk;
                count_sclk<=0;
            end
        end
    end

    //fsm 

    always@(posedge sclk)begin
        if(reset)begin
            cs<=0;
            temp<=0;
        end

        else begin
            case (state)
                idle: begin
                    if(new_data) begin
                        temp<= din;
                        state<= send;
                        cs<=1;
                    end
                    else {cs,mosi} <=0;
                        
                end
                send: begin
                    if(count_tx<12)begin
                        mosi=temp[11-count_tx];
                        count_tx=count_tx+1;
                    end
                    else begin
                        count_tx<=0;
                        state<=idle;
                    end

                end
                default: state<=idle;
            endcase
        end

    end
    

endmodule

module spi_slave(
    input sclk,cs,mosi,reset,
    output reg [11:0] dout,
    output reg done
);
  typedef enum bit {waiting=1'b0,send=1'b1} spi_state;
    spi_state state =waiting;
    int count_rx=0;

    reg [11:0] temp;

    //fsm state

    always@(posedge sclk)begin
      if(reset) done<=0;
        else begin
            case(state)
                waiting: begin
                    if(cs)begin
                        if(count_rx<12)begin
                            temp[11-count_rx]=mosi;
                            count_rx=count_rx+1;
                        end
                        else begin
                            state<=send;
                            count_rx=0;
                        end
                    end
                end

                send: begin
                    dout<=temp;
                    done<=1;
                    state<=waiting;
                end

            endcase
        end
    end

endmodule

module top(
    input clk,new_data,reset,
    input [11:0] din,
    output done,
    output [11:0]dout
);
    wire cs;
    wire mosi;
    wire sclk;
    spi_master master_dut(.clk(clk),.new_data(new_data),.reset(reset),.din(din),.cs(cs),.mosi(mosi),.sclk(sclk));
    spi_slave slave_dut(.sclk(sclk),.mosi(mosi),.cs(cs),.dout(dout),.done(done));

endmodule