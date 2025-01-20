class transaction;
    bit new_data;
    rand bit [11:0] din;
    bit [11:0] dout;

    //copy function
    function transaction copy();
        copy=new();
        copy.new_data= this.new_data;
        copy.din=this.din;
        copy.dout=this.dout;

    endfunction

endclass

//generator

class generator;
    transaction tr;
    mailbox #(transaction) mbx; // to driver and score board
    event done;// to indicate completion
    int count = 0; 

    event sconext; // from scoreboard

    function new(mailbox #(transaction) mbx);
        this.mbx=mbx;
        tr=new(); //create new transaction, object of transaction mentioned before

    endfunction

    task run();
        repeat(count) begin
        assert(tr.randomize) else $error("[gen]: randomization error");
        mbx.put(tr.copy); //put a copy to mailbox
        $display("[GEN]: din : %0d", tr.din);
        $display("[GEN]: Triggering drvnext");
        @(sconext); // wait for signal from scoreboard
        end
        -> done;
    endtask 

endclass

//driver class

class driver;
    virtual spi_if vif; // needed for interfacing
    transaction tr;

    mailbox #(transaction) mbx; //from generator
    mailbox #(bit [11:0]) mbxds; // to output of monitor

    bit [11:0] din; //data input

    function new(mailbox #(bit [11:0])mbxds, mailbox #(transaction)mbx);
        this.mbxds= mbxds;
        this.mbx= mbx;
    endfunction

    task reset();
        vif.reset<=1'b1;
        vif.new_data<= 1'b0;
        vif.din <= 1'b0;
        repeat(20) @(posedge vif.clk);
        vif.reset <= 1'b0;
        repeat(5) @(posedge vif.clk);
        $display("[DRV]: Reset Done");
        $display("-------------------");

    endtask

    task run();
        forever begin
            mbx.get(tr);
            vif.new_data <= 1'b1;
            vif.din <= tr.din;
            mbxds.put(tr.din); //put data in mailbox 
            @(posedge vif.sclk);
            vif.new_data <= 1'b0;
            @(posedge vif.done);
            $display("[DRV] : Data Sent to DAC: %0d", tr.din);
        end
    endtask
endclass

//monitor

class monitor;
    transaction tr;
    mailbox #(bit [11:0]) mbx; //data output

    virtual spi_if vif;

    function new(mailbox #(bit [11:0])mbx);
        this.mbx=mbx;
    endfunction

    task run();
        tr=new();
        forever begin
            @(posedge vif.sclk);//why?
            @(posedge vif.done);
            tr.dout = vif.dout;
            @(posedge vif.sclk);
            $display("[MON]: Data Sent: %0d", tr.dout);
            mbx.put(tr.dout);
        end
    endtask
endclass

//scoreboard 

class scoreboard;
    mailbox #(bit [11:0])mbxds, mbxms; //mailbox from driver and monitor
    bit [11:0] ds; //data from driver
    bit [11:0] ms; //data from monitor

    event sconext; //

    function new(mailbox #(bit[11:0])mbxds, mailbox #(bit[11:0])mbxms);
        this.mbxds=mbxds;
        this.mbxms=mbxms;
    endfunction

    task run();
        forever begin
            mbxds.get(ds); //to get data
            mbxms.get(ms);
            $display("[SCO]: Drv: %0d Mon: %0d",ds,ms);

            if(ds==ms) $display("[SCO]: Data Matched");
            else $display("[SCO]: Data Mismatched");

            $display("---------------------");
            -> sconext; //to generator
        end
    endtask

endclass

//environment

class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard sco;

    event nextgs;

    mailbox #(transaction) mbxgd; //generator to driver
    mailbox #(bit [11:0]) mbxds; //driver to monitor
    mailbox #(bit [11:0]) mbxms; //monitor to scoreboard

    virtual spi_if vif;

    function new(virtual spi_if vif);
        mbxgd = new();
        mbxms = new();
        mbxds = new();
        gen = new(mbxgd);
        drv = new(mbxds,mbxgd);
        mon = new(mbxms);
        sco = new(mbxds, mbxms);

        this.vif = vif;
        drv.vif = this.vif;
        mon.vif = this.vif;

        gen.sconext =nextgs;
        sco.sconext =nextgs;

    endfunction

    task pre_test();
        drv.reset();
    endtask

    task test();
        fork
            gen.run();
            drv.run();
            mon.run();
            sco.run();
        join_any
    endtask

    task post_test();
        wait(gen.done.triggered);
        $finish();
    endtask

    task run();
        pre_test();
        test();
        post_test();
      	$display("[ENV]: gen.drvnext = %p", gen.drvnext);
		$display("[ENV]: drv.drvnext = %p", drv.drvnext);
    endtask

endclass

//testbench
module tb;
    spi_if vif();

    top dut(
        .clk(vif.clk),
        .reset(vif.reset),
        .new_data(vif.new_data),
        .din(vif.din),
        .dout(vif.dout),
        .done(vif.done));
    initial begin
        vif.clk <=0;
    end

    always #5 vif.clk <= ~vif.clk;

    environment env;

    assign vif.sclk = dut.master_dut.sclk;

    initial begin
        env = new(vif);
        env.gen.count= 5;
        env.run();
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end
endmodule

interface spi_if;
    logic clk;
    logic new_data;
    logic reset;
    logic [11:0]din;
    logic [11:0]dout;
    logic done;
    logic sclk;
    logic cs;
    logic mosi;

endinterface