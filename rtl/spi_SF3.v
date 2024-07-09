`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/19 21:17:49
// Design Name: 
// Module Name: spi_SF3
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spi_SF3(
input wire clk, //sys clk.
input wire rst, // sys reset.
input wire write_req,//write requirement.
input wire read_req,//read requirement.
input wire[7:0] write_data,//the data you want to write in flash.
input wire miso,//master in, slave out.
input wire cs,
output wire[3:0] spi_state_c_m,
output wire write_ack,//ack for writing.
output wire[7:0] read_data,// data read from flash..
//output reg[31:0] read_data_word,
output wire read_ack,//ack for read.
output wire spi_clk,//clock for spi protocol.
output wire mosi//master out alve in.

    );

reg[3:0] spi_read_write_cnt;//count data bits read or write.
reg[7:0] write_data_reg;
reg[7:0] read_data_reg;
reg spi_clk_reg;
reg mosi_reg;

wire posedge_flag;
wire negedge_flag;
reg[1:0] m;
reg spi_clk_1,spi_clk_2,spi_clk_3;
reg[3:0] cnt;
reg[3:0] cnt_write,cnt_read;
//state defination.
localparam spi_idle=4'b0001;
localparam spi_data=4'b0010;
localparam spi_end=4'b0100;
//localparam div_cnt='d20;
localparam div_cnt='d2;
reg[3:0] spi_state_c;assign spi_state_c_m=spi_state_c;
reg[3:0] spi_state_n;
//Sys clk div.

 always@(posedge clk,negedge rst)//Attention.
 begin
 if(!rst)
 begin
 cnt<='d0;
 spi_clk_reg<=1'b1;
 end
 
 else if(spi_state_c==spi_data)
 //else if(cs == 1'b0)
 begin
 if(div_cnt/2-1)
 begin
 cnt<=cnt+1'b1;
 spi_clk_reg<=spi_clk_reg;
 end
 
 else
 begin
 cnt<='d0;
 spi_clk_reg<=~spi_clk_reg;
 //spi_clk_reg<=1'b1;
 end
 end
 else
 //spi_clk_reg<=1'b1;
 spi_clk_reg<=spi_clk_reg;//!!!!!!!!!!!!!!!!!!!!!change from return 1 to keep.
 end
 /*
 always @(posedge clk, negedge rst)
 begin
  if(!rst)
  spi_clk_reg <= 1'b1;
  else if(spi_state_c == spi_data)
  begin
    spi_clk_reg <= ~spi_clk_reg;
  end
  else
     spi_clk_reg <= spi_clk_reg;
 end
 */
 assign spi_clk=spi_clk_reg;
 //Posedge/needge detection.
 always@(posedge clk,negedge rst)
 begin
 if(!rst)
 begin
  m<=2'b00;
  spi_clk_1<=1'b0;
  spi_clk_2<=1'b0;
  spi_clk_3<=1'b0;
 end
 else
 begin
  m<={m[0],spi_clk};
  spi_clk_1<=spi_clk;
  spi_clk_2<=spi_clk_1;
  spi_clk_3<=spi_clk_2;;
 end
 end
 /*
 assign negedge_flag=~m[1]&&m[0];//attention.
 assign posedge_flag=m[1]&&~m[0];
 */
 assign negedge_flag=spi_clk_2&&~spi_clk_3;
 assign posedge_flag=~spi_clk_2&&spi_clk_3;//Attention.
//spi state update.
always@(posedge clk,negedge rst)
 begin
 if(!rst)
 spi_state_c<=spi_idle;
 else
 spi_state_c<=spi_state_n;
 end
 /*
 //load write_data.
always@(posedge clk,negedge rst)
begin
  if(!rst)
  write_data_reg<=8'b0;
  else if(spi_state_c==spi_idle&&(write_req==1'b1 || read_req==1'b1))
  write_data_reg<=write_data;//load the write_data.
  else if(spi_state_c==spi_data&&negedge_flag==1'b1)
  write_data_reg<={write_data_reg[6:0],write_data_reg[7]};//write_data left shift.
  else
  write_data_reg<=write_data_reg;
end
*/
/*
always@(posedge clk,negedge rst)
begin
  if(!rst)
  write_data_reg<=8'b0;
  else if(spi_state_c==spi_idle&&(write_req==1'b1 || read_req==1'b1))
  write_data_reg<=write_data;//load the write_data.
  else
  write_data_reg<=write_data_reg;
end
*/

//Load write data.
always@(posedge clk,negedge rst)
begin
  if(!rst)
  begin
  write_data_reg<=8'b0;
//  cnt_write<='d0;
  end
  else if(spi_state_c==spi_idle&&(write_req==1'b1||read_req==1'b1))//ATTENTION.
  write_data_reg<=write_data;//load the write_data.
  else
  write_data_reg<=write_data_reg;
end

//Put write data on mosi.
/*
always@(negedge clk,negedge rst)
begin
 if(!rst)
 begin
 mosi_reg<=1'b1;
 end
 */
 //else if((spi_state_c==spi_data)&&(write_req==1'b1||read_req==1'b1))//attention:negedge->write_req.
// else if(write_req==1'b1||read_req==1'b1)//attention:negedge->write_req.
 /*ATTENTIO                      Data from MOSI need to be read at the POSEDGE by slave,
 But the original state of MOSI may be a posedge/negedge when SLAVE read at the POSEDGE OF SPI_CLK.
 write_req/read_req become valid at the former cycle of spi_data, so write_data ought to
 be load when write_req/read_req become valid.*/
/*
else if(write_req == 1'b1)
 mosi_reg<=write_data[7-cnt_write];//ATTENTION.
 else
 mosi_reg=1'b1;
end
*/
assign mosi = (write_req == 1'b1 && negedge_flag == 1'b1)? write_data[3'd7 - cnt_write] : mosi;
//assign mosi=mosi_reg;
//Write bit count.
always@(posedge spi_clk,negedge rst)//pos->neg.
begin
if(!rst)
begin
cnt_write<='d0;
end
else if(cnt_write=='d7)
cnt_write<='d0;
else
cnt_write<=cnt_write+1'b1;
end
/*
//Read data from flash.
always@(posedge clk,negedge rst)
begin
 if(!rst)
 read_data_reg<=8'b0;
 else if(spi_state_c==spi_data&&posedge_flag==1'b1)//Attention:posedge->read_req.
 read_data_reg={read_data_reg[6:0],miso};//MSB first.
 else
 read_data_reg<=read_data_reg;
end
*/
//Get data from miso.
//reg[31:0]   read_data_word;
always@(posedge spi_clk,negedge rst)
begin
if(!rst)
begin
read_data_reg<=8'b0;
cnt_read<='d0;
end
else if(spi_state_c==spi_data&&read_req==1'b1)
begin
read_data_reg<={read_data_reg[6:0],miso};
if(cnt_read=='d7)
cnt_read<='d0;
else
cnt_read<=cnt_read+1'b1;
end
else
begin
read_data_reg<=read_data_reg;
end
end
assign read_data=read_data_reg;
/*
always@(posedge spi_clk,negedge rst)
begin
if(!rst)
read_data_word<=32'b0;
//else if(spi_state_c==spi_data&&cnt_read=='d0&&negedge_flag)
else if(read_ack)
read_data_word<={read_data_word[23:0],read_data_reg};
else
read_data_word<=read_data_word;
end
*/
/*
 //Bits count.
 always@(posedge clk, negedge rst)
 begin
  if(!rst)
  spi_read_write_cnt<=4'b0;
  else if(spi_state_c==spi_data && negedge_flag==1'b1&&write_req==1'b1)
  begin
  if(spi_read_write_cnt=='d7)//Attention:the order of if and else; the number is changed to 7 from 8.
  spi_read_write_cnt<='d0;
  else
  spi_read_write_cnt<=spi_read_write_cnt+1'b1;
  end
  else if(spi_state_c==spi_data&&posedge_flag==1'b1&&read_req==1'b1)
  begin
  if(spi_read_write_cnt=='d8)
  spi_read_write_cnt<='d0;
  else
  spi_read_write_cnt<=spi_read_write_cnt+1'b1;
  end
  else
  spi_read_write_cnt<=spi_read_write_cnt;
 end
 */
 //spi state change.
 always@(*)
  begin
  case(spi_state_c)
   spi_idle:
   if(write_req==1'b1 || read_req==1'b1)
              spi_state_n=spi_data;
   else       
              spi_state_n=spi_idle;
   spi_data://!!!!!!!!!!change req from 1 to 0.
   if(cnt_write=='d0&&write_req==1'b1&&negedge_flag==1'b1)//pos->neg.;from 7 to 0@169 pos.
   begin 
              spi_state_n=spi_end;
   end
   else if(cnt_read=='d0&&read_req==1'b1&&negedge_flag==1'b1)//cnt changed to 0 from 7.
   begin
              spi_state_n=spi_end;
   end
   else
              spi_state_n=spi_data;
   spi_end:
              spi_state_n=spi_idle;
   default:
              spi_state_n=spi_idle;
  endcase
  end
  
  //ACK.
  
  assign read_ack=(spi_state_c==spi_end)?1'b1:1'b0;
  assign write_ack=(spi_state_c==spi_end)?1'b1:1'b0;
  
endmodule
