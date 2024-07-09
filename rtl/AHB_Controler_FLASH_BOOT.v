`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/21 15:25:20
// Design Name: 
// Module Name: AHB_Controler_FLASH_SM
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

module AHB_Controler_FLASH_BOOT(
    input   wire        HCLK,
    input   wire        HRST_n,
    input   wire[31:0]  HADDR,
    input   wire        HWRITE,
    input   wire[31:0]  HWDATA,
    input   wire[1:0]   HSIZE,
    input   wire        HSELx,
    input   wire[1:0]   HTRANS,
    input   wire        i_pad_pmodb_miso,
    output  wire        o_pad_pmodb_mosi,
    output  wire        o_pad_pmodb_cs,
    output  wire        o_pad_pmodb_spi_clk,
    output  reg[31:0]   HRDATA,
    output  reg         HREADY,
    output  wire[1:0]   HRESP
    );
    reg[31:0]   haddr;
    reg[1:0]    htrans;
    reg[31:0]   hwdata;
//FLASH input/output defination which will be instantiated in the FLASH CTRL module. 
//about read.
    wire        FLASH_clk;
    wire        FLASSH_rst;
    reg        FLASH_read_req;
    reg[23:0]  FLASH_read_addr;
    wire[9:0]   FLASH_read_size;
    wire        FLASH_read_ID_req;
    wire[7:0]   FLASH_read_data;
    wire[31:0]  FLASH_read_data_word;
    wire[159:0]  FLASH_ID;
    wire        FLASH_read_id_end;
    wire        FLASH_read_ack;
    wire        FLASH_read_end;
    
    reg        FLASH_write_en_req;
    reg        FLASH_write_req;
    reg[23:0]  FLASH_write_page;
    wire[7:0]   FLASH_write_size;
    reg[31:0]   FLASH_write_data;
    reg        FLASH_sector_erase_req;
    reg[23:0]  FLASH_sector_erase_addr;
    wire        FLASH_bulk_erase_req;
    wire        FLASH_sector_erase_end;
    wire        FLASH_bulk_erase_end;
    wire        FLASH_write_en_end;
    wire        FLASH_write_ack;
    wire        FLASH_write_end;
    wire        FLASH_mosi;
    wire        FLASH_miso;
    wire        FLASH_SPI_CLK;
    wire        FLASH_SPI_cs;
    wire[3:0]   FLASH_SPI_state_c_m;
    wire[12:0]  FLASH_state_c_out;
    
    reg 	hwrite_former;
    reg 	hselx_former;
    reg 	hready_former;
    reg[31:0] 	haddr_former;
    reg[31:0] 	hwdata_former;
    reg[1:0]   	htrans_former;
   /* 
    wire ahbl_Flash_vld;
    assign ahbl_Flash_vld = ((haddr_former >= FLASH_base) &&
                             (haddr_former <= FLASH_end)) ?
                             1'b1 : 1'b0;
    */
    assign FLASH_miso          =        i_pad_pmodb_miso;
    assign o_pad_pmodb_mosi    =        FLASH_mosi;
    assign o_pad_pmodb_cs      =        FLASH_SPI_cs;
    assign o_pad_pmodb_spi_clk =        FLASH_SPI_CLK;
    //Edited by @Li Bingzheng 20240418.
    //Set output of AHB2SPI at Z avoiding multiple driving when AHB2SPI loaded 
    //at IAHBL.
    /*
    assign o_pad_pmodb_mosi      = (ahbl_Flash_vld == 1'b1)?
                                    FLASH_mosi    : 1'bz;
    assign o_pad_pmodb_cs        = (ahbl_Flash_vld == 1'b1)?
                                    FLASH_SPI_cs  : 1'bz;
    assign o_pad_pmodb_spi_clk   = (ahbl_Flash_vld == 1'b1)?
                                    FLASH_SPI_CLK : 1'bz;
    */
//STATE DEFINATION.
    localparam  SLAVE_IDLE              	=   3'b000;
    localparam  SLAVE_Write_EN	        	=   3'b001;
    localparam  SLAVE_Sector_Erase		=   3'b010;
    localparam  SLAVE_Write_Data        	=   3'b111;
    localparam  SLAVE_Send_Data         	=   3'b100;
    localparam  SLAVE_END                       =   3'b110;
//STATE MACHINE DEFINATION.
    reg[2:0]    SLAVE_state_c;
    reg[2:0]    SLAVE_state_n;
//Address defination.(has changed from 0x30000000 to 0x70000000)
    localparam  FLASH_base		=	32'h1000_0000;
    localparam  FLASH_end		=	32'h1004_ffff;
    localparam  FLASH_write_en		=	32'h7004_0008;//0X7000_0008
//It used to be 0x3000_7ffc/0x3000_7ff8, but it's unavilable.
    localparam  FLASH_sector_erase	=	32'h7004_000c;//0X7000_000c
    
    //reg [31 :0] mem[65535 :0];
    //reg sector_erase_flag;
    //reg [12 :0] FLASH_state_c_out_former;
 /*
 always@(posedge HCLK, negedge HRST_n)
    begin
        if(!HRST_n)
            begin
                hwrite_former   <= 1'b0;
                haddr_former    <= 32'b0;
                hwdata_former   <= 32'b0;
		htrans_former	<= 2'b0;
		hselx_former	<= 1'b0;
		hready_former	<= 1'b0;
                FLASH_state_c_out_former <= 13'b0;
            end
        else
            begin
                hwrite_former   <=  HWRITE;
                haddr_former    <=  HADDR;
                hwdata_former   <=  HWDATA;
		htrans_former	<=  HTRANS;
		hselx_former 	<=  HSELx;
		hready_former	<=  HREADY;
                FLASH_state_c_out_former <= FLASH_state_c_out;
            end
            
    end
 */
always@(posedge HCLK, negedge HRST_n)
    begin
        if(!HRST_n)
            begin
                SLAVE_state_c   <=  SLAVE_IDLE;
            end
         else
            SLAVE_state_c   <=  SLAVE_state_n;
    end
always@(posedge HCLK, negedge HRST_n)
//always @(*)
begin
  if(!HRST_n)
  begin
   SLAVE_state_n <= SLAVE_IDLE;
  end
  else
    case(SLAVE_state_c)
      SLAVE_IDLE:
        begin	
                    if((HSELx		==  1'b1)&&
                       (HTRANS[1] 	==  1'b1)&&
                       (HWRITE		==  1'b0)&&
                       //Added by @Li Bingzheng 20240421.
                       (HADDR >= FLASH_base)     &&
                       (HADDR <= FLASH_end))
                        begin
                          SLAVE_state_n   <=  SLAVE_Send_Data;
                          //Edited by @Li Bingzheng 20240421.
                          FLASH_read_req  <= 1'b1;
                          FLASH_read_addr <= HADDR - FLASH_base;
                        end
                     else if((HSELx     == 1'b1) &&
                             (HTRANS[1] == 1'b1) &&
                             (HWRITE    == 1'b1) &&
                             (HADDR     == FLASH_write_en))
                     begin
                       SLAVE_state_n      <= SLAVE_Write_EN;
                       FLASH_write_en_req <= 1'b1;
                     end
                     else if((HSELx     == 1'b1) &&
                             (HTRANS[1] == 1'b1) &&
                             (HWRITE    == 1'b1) &&
                             (HADDR     == FLASH_sector_erase))
                     begin
                       SLAVE_state_n          <= SLAVE_Sector_Erase;
                       FLASH_sector_erase_req <= 1'b1;
                     end
                     else if((HSELx     == 1'b1)       &&
                             (HTRANS[1] == 1'b1)       &&
                             (HWRITE    == 1'b1)       &&
                             (HADDR     >= FLASH_base) &&
                             (HADDR     <= FLASH_end))
                     begin
                       SLAVE_state_n    <= SLAVE_Write_Data;
                       FLASH_write_req  <= 1'b1;
                       FLASH_write_page <= HADDR - FLASH_base;
                     end
                     else
                     begin
                       SLAVE_state_n <= SLAVE_state_c;
                     end
        end		
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
/*The condition of the change from send_data to idle used to be hready=1, but
 * it is unvailable becase hready has been determineded in the 3th part of
 * state machine which might be a logical mistake. But this method can't be
 * verified by smart run simulation because there is no flash answering in the
 * platform after all.*/
            SLAVE_Send_Data:
                begin
                    if(FLASH_state_c_out == 13'b1_0000_0000_0000)
                        begin
                         SLAVE_state_n  <= SLAVE_IDLE;
                         //FLASH_read_req <= 1'b0;
                        end
                    else
                        SLAVE_state_n   <=   SLAVE_state_c;
                    if(FLASH_state_c_out == 13'h800)
                    begin
                      FLASH_read_req <= 1'b0;
                    end
                    else
                    begin
                      FLASH_read_req <= FLASH_read_req;
                    end
                    if(HSELx == 1'b1)
                    begin
                      FLASH_read_req <= 1'b1;
                      FLASH_read_addr <= HADDR - FLASH_base;
                    end
                    else 
                    begin
                      FLASH_read_addr <= FLASH_read_addr;
                    end
                end
            SLAVE_Write_EN:
                begin
                  if(FLASH_state_c_out == 13'b1_0000_0000_0000)
                  begin
                    FLASH_write_en_req <= 1'b0;
                  end
                  else 
                  begin
                    FLASH_write_en_req <= FLASH_write_en_req;
                  end
                end
            SLAVE_Write_Data:
                begin
                  if(FLASH_state_c_out == 13'b1_0000_0000_0000)
                  begin
                    FLASH_write_req <= 1'b0;
                  end
                  else
                  begin
                    FLASH_write_req  <= 1'b1;
                    FLASH_write_data <= HWDATA; 
                  end
                end
            SLAVE_Sector_Erase:
              begin
                if(FLASH_state_c_out == 13'b1_0000_0000_0000)
                begin
                  FLASH_sector_erase_req <= 1'b0;
                end
                else
                begin
                  FLASH_sector_erase_req  <= 1'b1;
                  FLASH_sector_erase_addr <= HWDATA-FLASH_base;
                end
              end
               
            default:
                SLAVE_state_n   <=  SLAVE_IDLE;
        endcase
    end
//always@(posedge HCLK,negedge HRST_n)//////!!!!!!!!!!!!
//always@(HCLK,HRST_n,FLASH_state_c_out)
//always@(posedge HCLK, negedge HRST_n)
always @(*)
    begin
        if(!HRST_n)
            begin
                HREADY  		=  	1'b1;
                HRDATA  		=  	32'bzzzz_zzzz;
            end
        else
        begin
        case(SLAVE_state_c)          
	  SLAVE_Send_Data:
            begin 
              if(FLASH_state_c_out    !=  13'b1_0000_0000_0000)
              begin 
        //The order of the sentence and its former is important!!! 
              HREADY	    		=  1'b0;
              HRDATA	    		=  HRDATA;
            end
            else 
            begin
              HREADY          		=  1'b1;
              `ifdef FLASH_BOOT_SIM
               HRDATA = mem[FLASH_read_addr[17:2]];
               `elsif FLASH_BOOT
               HRDATA  =  FLASH_read_data_word;
               `else
               HRDATA = FLASH_read_data_word;
               `endif
            end                   
            end
           SLAVE_Write_EN:
           begin
             if(FLASH_state_c_out == 13'b1_0000_0000_0000)
             begin
               HREADY = 1'b0;
             end
             else
             begin
               HREADY = 1'b1;
             end
           end
           SLAVE_Write_Data:
           begin
             if(FLASH_state_c_out == 13'b1_0000_0000_0000)
             begin
               HREADY = 1'b0;
             end
             else
             begin
               HREADY = 1'b1;
             end
           end
           SLAVE_Sector_Erase:
           begin
             if(FLASH_state_c_out == 13'b1_0000_0000_0000)
             begin
               HREADY = 1'b0;
             end
             else
             begin
               HREADY = 1'b1;
             end
           end

           
		default:
	        begin
		  HREADY = 1'b1;
		  HRDATA = HRDATA;
	        end
                endcase
            end	
    end
    assign  HRESP =   2'b00;
    /*
    assign  FLASH_read_req  =   ((HWRITE ==  1'b0) && 
                                (HTRANS  ==  2'b10) && 
                                (HREADY ==  1'b1)&&
                                (FLASH_state_c_out  ==  13'b0_0000_0000_0001))
                                ? 1'b1 : 1'b0;
    assign  FLASH_read_addr =   ((HWRITE == 1'b0)&&
                                 (HTRANS == 2'b10)&&
                                 (HREADY == 1'b1)&&
                                 (FLASH_state_c_out ==  13'b0_0000_0000_0001))
                                 ? HADDR : FLASH_read_addr;
    */
//Instantiate FLASH_CTRL.
flash_sf3 AHB2SPI_FLASH_ctrl(
    .clk(HCLK),
    .rst(HRST_n),
    .read_rq(FLASH_read_req),
    .read_size(10'd4),
    .read_id_rq(FLASH_read_ID_req),
    .read_addr(FLASH_read_addr),
    .read_data(FLASH_read_data),
    .read_data_word(FLASH_read_data_word),
    .flash_id(FLASH_ID),
    .read_id_end(FLASH_read_id_end),
    .read_ack(FLASH_read_ack),
    .read_end(FLASH_read_end),
    .write_en_req(FLASH_write_en_req),
    .write_req(FLASH_write_req),
    .write_page(FLASH_write_page),//used to be error.
    .write_size(8'd4),
    .write_data(FLASH_write_data),
    .sector_erase_req(FLASH_sector_erase_req),
    .sector_erase_addr(FLASH_sector_erase_addr),
    .bulk_erase_req(FLASH_bulk_erase_req),
    .sector_erase_end(FLASH_sector_erase_end),
    .bulk_erase_end(FLASH_bulk_erase_end),
    .write_en_end(FLASH_write_en_end),
    .write_ack(FLASH_write_ack),
    .write_end(FLASH_write_end),
    .spi_state_c_m(FLASH_SPI_state_c_m),
    .FLASH_state_c_out(FLASH_state_c_out),
    .mosi(FLASH_mosi),
    .miso(FLASH_miso),
    .spi_clk(FLASH_SPI_CLK),
    .spi_cs(FLASH_SPI_cs)
    );

endmodule
