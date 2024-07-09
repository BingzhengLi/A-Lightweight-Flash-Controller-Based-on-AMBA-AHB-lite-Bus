`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/21 10:35:35
// Design Name: 
// Module Name: flash_sf3
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


module flash_sf3(
input wire clk,
input wire rst,

//Read.
input wire read_rq,
input wire[23:0] read_addr,
input wire[9:0] read_size,
input wire read_id_rq,
output wire[7:0] read_data,
output wire[159:0] flash_id,
output wire read_id_end,
output wire read_ack,
output wire read_end,
output reg[31:0] read_data_word,
output wire[12:0]   FLASH_state_c_out,


//Write.
input wire write_en_req,
input wire write_req,
input wire[23:0] write_page,
input wire[7:0] write_size,
input wire[31:0] write_data,
input wire sector_erase_req,
input wire[23:0] sector_erase_addr,
input wire bulk_erase_req,
output wire sector_erase_end,
output wire bulk_erase_end,
output wire write_en_end,
output wire write_ack,
output wire write_end,
output wire[3:0] spi_state_c_m,
output wire mosi,
input wire miso,
output wire spi_clk,
output wire spi_cs
    );
 //Instructions'definations.
 `define Write_Enable 8'h06
 `define Read_ID 8'h9E//1001_1110.
 `define Read_Data_Bytes 8'h03
 `define Page_Program 8'h02
 `define Sector_Erase 8'hD8
 `define Bulk_Erase 8'hC7
 
 //Parameter.
 localparam Page_Size='d256;
 localparam Bytes_of_Flash_ID='d20;
 localparam Sector_Erase_Bytes='d4;
 localparam Bulk_Erase_Bytes='d1;
 
 localparam Flash_Write_EN_Wait='d10;
 localparam Flash_Read_Bytes_Wait='d10;//100
 localparam Flash_Sector_Erase_Wait=32'd5000_0000;//5000_0000
/*
 * 5000_0000 come from: The frequency of sys_clk = 50MHz whose period = 20 ns;
 * 1 s =1e9 ns, so 5000_0000 cycles means 1s;
 * so that to leave enough time for erasing.
 */
 //localparam Flash_Sector_Erase_Wait=32'd2000;
 localparam Flash_Bulk_Erase_Wait=32'd65_000_000;
 localparam Flash_Page_Program_Wait=32'd20000;//20000
 //localparam Flash_Page_Program_Wait=32'd10;
 
 //State defination.
 localparam Flash_Idle=13'b0_0000_0000_0001;
 localparam Flash_Write_En=13'b0_0000_0000_0010;//0X0002.
 localparam Flash_Write_Disable=13'b0_0000_0000_0100;
 localparam Flash_Read_ID=13'b0_0000_0000_1000;
 localparam Flash_Read_Status_Reg=13'b0_0000_0001_0000;
 //localparam Flash_Write_Status_Reg=13'b0_0000_0010_0000;
 localparam Flash_End1=13'b0_0000_0010_0000;
 localparam Flash_Read_Bytes=13'b0_0000_0100_0000;
 localparam Flash_Read_HighSpeed=13'b0_0000_1000_0000;
 localparam Flash_Page_Program=13'b0_0001_0000_0000;//0X0100.
 localparam Flash_Sector_Erase=13'b0_0010_0000_0000;
 localparam Flash_Bulk_Erase=13'b0_0100_0000_0000;
 localparam Flash_Wait=13'b0_1000_0000_0000;//0X0800.
 localparam Flash_End=13'b1_0000_0000_0000;
 
 reg[12:0] state_c; assign FLASH_state_c_out =   state_c;
 reg[12:0] state_n;
 reg[12:0] state_w;
 
 //SPI  read/write.
 reg spi_read_req;
 
 wire[7:0] spi_read_data;
 wire spi_read_ack;
 
 reg spi_write_req;
 reg[31:0] write_data_shif;
 reg[7:0] spi_write_data;
 wire spi_write_ack;
 
 reg spi_cs_reg;
 assign spi_cs=spi_cs_reg;
 
 reg[9:0] spi_byte_cnt;
 reg[32:0] wait_cnt;
 
 reg[159:0] flash_id_reg;
 
 always@(posedge clk,negedge rst)
 begin
 if(!rst)
 state_c<=Flash_Idle;
 else
 state_c<=state_n;
 end
 
 always@(posedge clk,negedge rst)
 begin
 if(!rst)
 state_w<=Flash_Idle;
 else if(state_c==Flash_Idle)
  if(write_req==1'b1)
   state_w<=Flash_Page_Program;
  else if(sector_erase_req==1'b1)
   state_w<=Flash_Sector_Erase;
  else if(bulk_erase_req==1'b1)
   state_w<=Flash_Bulk_Erase;
  else if(read_rq==1'b1)
   state_w<=Flash_Read_Bytes;
  else if(write_en_req==1'b1)
   state_w<=Flash_Write_En;
  else
   state_w<=Flash_Idle;//bug: add this sentence to solve that state can't be changed.
 else
  state_w<=state_w;
 end
 
 //Waiting time measurement.
 always@(posedge clk,negedge rst)
 begin
 if(!rst)
 wait_cnt<='d0;
 else if(state_c==Flash_Wait)
 //else if(state_w!=Flash_Idle)
 wait_cnt<=wait_cnt+1'b1;
 else
 wait_cnt<='d0;
 end
 
//Next state generation.
always@(*)
begin
case(state_c)
 Flash_Idle:
  if(read_id_rq==1'b1)
   state_n<=Flash_Read_ID;
  else if(write_en_req==1'b1)
   state_n<=Flash_Write_En;
  else if(write_req==1'b1)//ATTENTION.
   state_n<=Flash_Page_Program;
  else if(read_rq==1'b1)
   state_n<=Flash_Read_Bytes;
  else if(sector_erase_req==1'b1)
   state_n<=Flash_Sector_Erase;
  else if(bulk_erase_req==1'b1)
   state_n<=Flash_Bulk_Erase;
  else 
   state_n<=Flash_Idle;
 Flash_Read_ID:
  if(spi_byte_cnt==Bytes_of_Flash_ID&&spi_read_ack==1'b1)//Bytes of flash_ID+Command-1.
   state_n<=Flash_End;
  else 
   state_n<=state_c;
 Flash_Write_En:
   if(spi_write_ack==1'b1)
    state_n<=Flash_Wait;
   else
    state_n<=state_c;
 Flash_Page_Program:
   if((spi_byte_cnt==write_size+'d1+'d3-'d1)&&spi_write_ack==1'b1)
    state_n<=Flash_Wait;
   else
    state_n<=state_c;
 Flash_Read_Bytes:
   if((spi_byte_cnt==read_size+'d1+'d3-'d1)&&spi_read_ack==1'b1)
    state_n<=Flash_Wait;
   else
    state_n<=state_c;
 Flash_Sector_Erase:
   if((spi_byte_cnt==Sector_Erase_Bytes-'d1)&&spi_write_ack==1'b1)//bug:foget to minus 1.!!!!!!!!!!
    state_n<=Flash_Wait;
   else
    state_n<=state_c;
  Flash_Bulk_Erase:
   if((spi_byte_cnt==Bulk_Erase_Bytes-1'b1)&&spi_write_ack==1'b1)
    state_n<=Flash_Wait;
   else
    state_n<=state_c;
  Flash_Wait:
   if(state_w==Flash_Page_Program&&wait_cnt==Flash_Page_Program_Wait)
    state_n<=Flash_End;
   else if((state_w==Flash_Sector_Erase)&&(wait_cnt==Flash_Sector_Erase_Wait))
    state_n<=Flash_End;
   else if(state_w==Flash_Bulk_Erase&&wait_cnt==Flash_Bulk_Erase_Wait)
    state_n<=Flash_End;
   else if(state_w==Flash_Read_Bytes&&wait_cnt==Flash_Read_Bytes_Wait)
    begin//////!!!!!!!!!!11
	state_n<=Flash_End;
    end
   else if(state_w==Flash_Write_En&&wait_cnt==Flash_Write_EN_Wait)
    state_n<=Flash_End;
   else
    state_n<=state_c;//bug solved: it used to be state_n<=state_End.
  Flash_End:
   begin
   	state_n<=Flash_Idle;
   	//state_n<=Flash_End1;
   end	
  Flash_End1:
	state_n<=Flash_Idle;
  default:
   state_n<=Flash_Idle;
endcase 
end  

//ChipSelection. Change from sequential logical to combinatioanl logical. 
//always@(*)
always@(posedge clk,negedge rst)
begin
if(!rst)
spi_cs_reg<=1'b1;
else if(state_c==Flash_Idle || state_c==Flash_End || state_c==Flash_Wait 
	|| state_c == 	Flash_End1)
spi_cs_reg<=1'b1;
else
spi_cs_reg<=1'b0;
end
assign spi_cs=spi_cs_reg;

//spi byte cnt.
always@(posedge clk,negedge rst)
begin
if(!rst)
spi_byte_cnt<='d0;
else if(state_c!=state_n)
spi_byte_cnt<='d0;//Reset the cnt when state changed.
else if(spi_read_ack==1'b1 || spi_write_ack==1'b1)
spi_byte_cnt<=spi_byte_cnt+1'b1;
else
spi_byte_cnt<=spi_byte_cnt;
end
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
//It used to be put in spi_sf3, but it is unavailable because Data want to read
//begins after "command+address[23:0]+content-1"
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
always@(posedge clk,negedge rst)
begin
if(!rst)
begin
read_data_word<=32'b0;
end
else if(spi_byte_cnt>'d3&&spi_read_ack==1'b1)
begin
read_data_word<={read_data_word[23:0],read_data};
end
else
read_data_word<=read_data_word;
end

/*
 This is used to send data in 32 bit in the method of shifting since spi_sf3 module only can send 1 byte each time.
 */
always@(posedge clk)
begin
if(spi_byte_cnt=='d0)//used to be when less than 4.
write_data_shif<=write_data;
else if(spi_byte_cnt>='d4&&spi_write_ack==1'b1&&state_c==Flash_Page_Program)
/*
 * why shif when >=4: 0/1/2/3 means command and address, because it's
 * NONBLOCKING assignment so when give value to spi_write_data write_data_shif
 * has not shif.
 */
begin
//Edited by @Li Bingzheng 20240418.
//Aimed to make it suitable for downloading prog to Flash.
write_data_shif<=(write_data_shif<<8);
//write_data_shif<=(write_data_shif>>8);
end
else 
write_data_shif<=write_data_shif;
end

//Spi read req control.
always@(*)//change from sequential to combinational.
//always@(posedge clk,negedge rst)
begin
if(!rst)
spi_read_req=1'b0;
else if((state_c==Flash_Read_ID)&&(spi_byte_cnt>'d0))
begin
if(spi_byte_cnt==Bytes_of_Flash_ID&&spi_read_ack==1'b1)
 spi_read_req=1'b0;
 else
 spi_read_req=1'b1;
end
else if(state_c==Flash_Read_Bytes&&spi_byte_cnt>'d3)
begin
  if((spi_byte_cnt==read_size+'d1+'d3-'d1)&&(spi_read_ack==1'd1))
    spi_read_req=1'b0;
  else
    spi_read_req=1'b1;
end
else
spi_read_req=1'b0;
end
//Read flash ID.
always@(posedge clk,negedge rst)
begin
if(!rst)
flash_id_reg<='d0;
else if(state_c==Flash_Read_ID&&spi_byte_cnt>'d0)
begin
if(spi_read_ack==1'b1)//Lower than miso.
flash_id_reg<={flash_id_reg[151:0],spi_read_data};
else
flash_id_reg<=flash_id_reg;
end
end
assign flash_id=flash_id_reg;
//Spi write req.
always@(*)//////////////////!!!!!!!change from sequential to combinational.
//always@(posedge clk,negedge rst)
begin
if(!rst)
spi_write_req=1'b0;
else if(state_c==Flash_Write_En&&spi_byte_cnt=='d0)//used to be no &&.
spi_write_req=1'b1;
else if(state_c==Flash_Read_ID&&spi_byte_cnt=='d0)
spi_write_req=1'b1;
else if(state_c==Flash_Page_Program)
spi_write_req=1'b1;
else if(state_c==Flash_Read_Bytes&&spi_byte_cnt<'d4)
spi_write_req=1'b1;
else if(state_c==Flash_Sector_Erase&&spi_byte_cnt<'d4)
spi_write_req=1'b1;
else if(state_c==Flash_Bulk_Erase)
spi_write_req=1'b1;
else
spi_write_req=1'b0;
end
//Spi write data.
always@(posedge clk,negedge rst)
begin
if(!rst)
spi_write_data<=8'd0;
else if(state_c==Flash_Write_En)
spi_write_data<=`Write_Enable;
else if(state_c==Flash_Read_ID&&spi_byte_cnt==1'd0)
spi_write_data<=`Read_ID;
else if(state_c==Flash_Page_Program)//ATTENTION.
case(spi_byte_cnt)
'd0: spi_write_data<=`Page_Program;
'd1: spi_write_data<=write_page[23:16];//Page address.
'd2: spi_write_data<=write_page[15:8];
'd3: spi_write_data<=write_page[7:0];
//Edited by @Li Bingzheng 20240418.
//In order to make it suitable for download prog to Flash.
default:spi_write_data<=write_data_shif[31:24];
//default:spi_write_data<=write_data_shif[7:0];
endcase
else if(state_c==Flash_Read_Bytes)
begin
if(spi_byte_cnt=='d0)
spi_write_data<=`Read_Data_Bytes;
else if(spi_byte_cnt=='d1)
spi_write_data<=read_addr[23:16];
else if(spi_byte_cnt=='d2)
spi_write_data<=read_addr[15:8];
else
spi_write_data<=read_addr[7:0];
end
else if(state_c==Flash_Sector_Erase)
begin
if(spi_byte_cnt=='d0)
spi_write_data<=`Sector_Erase;
else if(spi_byte_cnt=='d1)
spi_write_data<=sector_erase_addr[23:16];
else if(spi_byte_cnt=='d2)
spi_write_data<=sector_erase_addr[15:8];
else
spi_write_data<=sector_erase_addr[7:0];
end
else if(state_c==Flash_Bulk_Erase)
spi_write_data<=`Bulk_Erase;
else
spi_write_data<=8'b0;
end

assign read_ack=((state_c==Flash_Read_Bytes)&&(spi_byte_cnt>'d3)&&spi_read_ack==1'b1)?1'b1:1'b0;//Output a ack each a byte received.
assign read_data=spi_read_data;
assign read_end=((state_c==Flash_Read_Bytes)&&(spi_byte_cnt==read_size+'d1+'d3-'d1)&(spi_read_ack==1'b1))?1'b1:1'b0;

assign write_en_end=((state_c==Flash_Write_En)&&(spi_byte_cnt=='d1)&&(spi_write_ack==1'b1))?1'b1:1'b0;
assign write_ack=((state_c==Flash_Page_Program)&&(spi_byte_cnt>'d3)&&(spi_write_ack==1'b1))?1'b1:1'b0;
assign write_end=((state_c==Flash_Page_Program)&&(spi_byte_cnt=='d3+'d1+write_size-1'b1)&&(spi_write_ack==1'b1));

assign sector_erase_end=((state_c==Flash_Sector_Erase)&&(spi_byte_cnt==Sector_Erase_Bytes)&&(spi_write_ack==1'b1))?1'b1:1'b0;
assign bulk_erase_end=((state_c==Flash_Bulk_Erase)&&(spi_byte_cnt==Bulk_Erase_Bytes)&&(spi_write_ack==1'b1))?1'b1:1'b0;

spi_SF3 SF3(
  .clk(clk),
  .rst(rst),
  .read_req(spi_read_req),
  .read_data(spi_read_data),
 // .read_data_word(read_data_word),
  .read_ack(spi_read_ack),
  .write_req(spi_write_req),
  .write_data(spi_write_data),
  .write_ack(spi_write_ack),
  .spi_clk(spi_clk),
  .miso(miso),
  .spi_state_c_m(spi_state_c_m),
  .mosi(mosi),
  .cs(spi_cs)
  );
endmodule
