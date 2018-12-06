`include "sm4_define.v"

module tb_sm4();
   reg clk,rst_n;
   reg start,action;
   reg [127:0] text_in;
   reg [127:0] key;
   
   reg [127 : 0] RandText;
   reg [127 : 0] RandKey;
   reg [127 : 0] result;
   integer i;
   wire [127 : 0] text_out;
   wire done;
   
   
  integer dumpwave; 
   initial begin
    $value$plusargs("DUMPWAVE=%d",dumpwave);
    if(dumpwave != 0)begin
      $fsdbDumpfile("tb_sm4.fsdb");
      $fsdbDumpvars(0, tb_sm4, "+mda");
     end
   end


    initial
    begin
        //$sdf_annotate ("SM4_v.sdo", SM4_Logic_ware, , , ,);
        clk = 0;
        rst_n = 0;
        start = 0;
        action = 0;
        key = 0;
        text_in = 0;
        RandText = 0;
        RandKey = 0;
        result = 0;
        i = 0;
        
        @(posedge clk);
        @(posedge clk);
        #5 rst_n = 1'b1;
        @(posedge clk);
        @(posedge clk);
        
        /*
        //stand testing
        //testing for enc        
        text_in = 128'h0123456789abcdeffedcba9876543210;
        key = 128'h0123456789abcdeffedcba9876543210;
        
        enc(text_in, key);
        
        if(text_out == 128'h681edf34d206965e86b3e94f536e4246)
        begin
            $display("The result of enc in stand testing is right:%x", text_out);
        end
        else
        begin
            $display("The result of enc in stand testing is wrong:%x", text_out);
            $stop;
        end
        
        
        //testing for enc        
        text_in =  128'h681edf34d206965e86b3e94f536e4246;
        key = 128'h0123456789abcdeffedcba9876543210;
        
        dec(text_in, key);
        
        if(text_out == 128'h0123456789abcdeffedcba9876543210)
        begin
            $display("The result of dec in stand testing  is right:%x", text_out);
        end
        else
        begin
            $display("The result of dec in stand testing  is wrong:%x", text_out);
            $stop;
        end
        */
        
        text_in = 128'hef17c228c89532680e7ad25347d34a00;
        key = 128'h9cf66f6660830c13b10b0fb700001206;
        
        enc(text_in, key);
        
        if(text_out == 128'h681edf34d206965e86b3e94f536e4246)
        begin
            $display("The result of enc in stand testing is right:%x", text_out);
        end
        else
        begin
            $display("The result of enc in stand testing is wrong:%x", text_out);
           // $stop;
        end
        
        
        //testing for enc        
               
        text_in = 128'hef17c228c89532680e7ad25347d34a00;
        key = 128'h9cf66f6660830c13b10b0fb700001206;

        dec(text_in, key);
        
        if(text_out == 128'h0123456789abcdeffedcba9876543210)
        begin
            $display("The result of dec in stand testing  is right:%x", text_out);
        end
        else
        begin
            $display("The result of dec in stand testing  is wrong:%x", text_out);
            $stop;
        end

        
        // random testing        
        while(i < 10000)
        begin
            RandText = {$random, $random,$random, $random};
            RandKey = {$random, $random,$random, $random};
            enc(RandText, RandKey);
            
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            
            dec(result, RandKey);
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            
            if(result == RandText)
            begin
                $display("the %d times in random testing is right", i);
                $display("%x", RandText);
                $display("%x", result);
            end
            else
            begin
                $display("the %d times in random testing is wrong", i);
                $display("the text is ", RandText);
                $display("the key is ", RandKey);
                $stop;
            end
            i = i + 1;
        end
        
        $finish;
        
    end
    
    task enc;        
        input [127 : 0] text_in_tmp;
        input [127 : 0] key_tmp;
        
        begin
            text_in = text_in_tmp;
            key = key_tmp;
            action = 0;
            
            @(posedge clk);
            #5 start = 1;            
            @(posedge clk);
            #5 start = 0;
            
            @(posedge clk);
            @(posedge clk);
            
            while(!done)
            begin
                @(posedge clk);
            end
            @(posedge clk);
            @(posedge clk);
            result = text_out;
            
        end
        
endtask

    task dec;
        input [127 : 0] text_in_tmp;
        input [127 : 0] key_tmp;
        
        begin
            text_in = text_in_tmp;
            key = key_tmp;
            action = 1;
            
            @(posedge clk);
            #5 start = 1;            
            @(posedge clk);
            #5 start = 0;
            
            @(posedge clk);
            @(posedge clk);
            
            while(!done)
            begin
                @(posedge clk);
            end
            @(posedge clk);
            @(posedge clk);
            result = text_out;
            
        end
endtask
    
    always #20 clk = ~clk;
    
   
   sm4_logic u_sm4_logic(
                            .clk(clk),
                            .rst_n(rst_n),
                            .start(start),
                            .text_in(text_in),
                            .key(key),
                            .action(action),
                            .text_out(text_out),
                            .done(done)
                        );
   
endmodule
