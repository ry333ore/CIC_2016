
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	clk;
input   	reset;
output  [13:0] 	gray_addr;
output         	gray_req;
input   	gray_ready;
input   [7:0] 	gray_data;
output  [13:0] 	lbp_addr;
output  	lbp_valid;
output  [7:0] 	lbp_data;
output  	finish;
//====================================================================
reg         	gray_req;
reg  	        lbp_valid;
reg  [13:0] 	gray_addr;

wire [13:0]     lbp_addr;
assign lbp_addr = gray_addr;

reg  [7:0] 	    lbp_data;
reg  	        finish;
//====================================================================
reg [5:0] cs,ns;
parameter RST=0,READ_gc=1,READ_gn=2,LBP=3,WRITE=4,FINISH=5;

reg [3:0] cnt;//2的次方
reg [13:0] num;//位移
reg [7:0] gc;
reg [7:0] two;

always@(posedge clk or posedge reset)begin
    if(reset)begin
        cs <= 'd0;
        cs[RST] <= 1'd1;
    end
    else cs <= ns;
end

always@(*)begin
    ns = 'd0;
    case (1'd1)
        cs[RST]:begin
            if(gray_ready)              ns[READ_gc] = 1'd1;
            else                        ns[RST] = 1'd1;
        end                 
        cs[READ_gc]:                    ns[READ_gn] = 1'd1;
        cs[READ_gn]:begin
            if(cnt==4'd9)               ns[WRITE] = 1'd1;
            else                        ns[LBP] = 1'd1;
        end           
        cs[LBP]:                        ns[READ_gn] = 1'd1;
        cs[WRITE]:begin
            if(gray_addr == 14'd16254)  ns[FINISH] = 1'd1;
            else                        ns[READ_gc] = 1'd1;
        end
        cs[FINISH]:                     ns[FINISH] = 1'd1;
    endcase
end

always @(posedge clk or posedge reset) begin
    if(reset)begin
        gc <= 8'd0;
        gray_req <= 1'd0;
        lbp_valid <= 1'd0;
        gray_addr <= 14'd128;
        
        lbp_data <= 8'd0;
        finish <= 1'd0;

        num <= -14'd129;
        cnt <= 4'd0;
        two <= 8'b00000001;
    end
    else begin
        case (1'd1)
            ns[RST]:begin
            gc <= 8'd0;
            gray_req <= 1'd0;
            lbp_valid <= 1'd0;
            gray_addr <= 14'd128;
            lbp_data <= 8'd0;
            finish <= 1'd0;
            num <= -14'd129;
            cnt <= 4'd0;
            two <= 8'b00000001;
            end
            ns[READ_gc]:begin
                lbp_data <= 1'd0;
                lbp_valid <= 1'd0;
                gray_req <= 1'd1;
                cnt <= 4'd0;
                if(((gray_addr - 14'd126) & 7'h7F) == 0) gray_addr <= gray_addr + 14'd3;  
                else gray_addr <= gray_addr + 14'd1;
            end
            ns[READ_gn]:begin
                //gc <= gray_data;
                gray_req <= 1'd1;
                gray_addr <= gray_addr + num;
                cnt <= cnt+4'd1;
                case (cnt)
                    4'd0: begin
                        num <= 14'd1;
                        gc <= gray_data;
                    end
                    4'd1: num <= 14'd1;
                    4'd2: num <= 14'd126;
                    4'd3: num <= 14'd2;
                    4'd4: num <= 14'd126;
                    4'd5: num <= 14'd1;
                    4'd6: num <= 14'd1;
                    4'd7: num <= -14'd129;
                    4'd8: num <= num;
                endcase
            end
            ns[LBP]:begin
                gray_req <=1'd0;
                two <= {two[6:0],1'd0};
                if(gray_data>=gc)begin
                    lbp_data <= lbp_data + two; 
                end
                else begin
                    lbp_data <= lbp_data;
                end
            end
            ns[WRITE]:begin
                lbp_valid <= 1'd1;
                gray_req <= 1'd0;
                two <= 8'b00000001;
            end
            ns[FINISH]:begin
                lbp_valid <= 1'd0;
                finish <= 1'd1;
            end
        endcase
    end    
end
//====================================================================
endmodule

