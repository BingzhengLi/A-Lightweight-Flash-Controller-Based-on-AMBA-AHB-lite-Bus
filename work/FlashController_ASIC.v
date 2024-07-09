`timescale 1ns/1ps
module Flash_Controller_ASIC(
  input  wire        pad_HCLK,
  input  wire        pad_HRST_n,
  input  wire[31 :0] pad_HADDR,
  input  wire[31 :0] pad_HWDATA,
  output wire[31 :0] pad_HRDATA,
  input  wire        pad_HWRITE,
  input  wire        pad_HSELx,
  input  wire[1  :0] pad_HSIZE,
  input  wire[1  :0] pad_HTRANS,
  input  wire        pad_i_pad_pmodb_miso,
  output wire        pad_o_pad_pmodb_mosi,
  output wire        pad_o_pad_pmodb_cs,
  output wire        pad_o_pad_pmodb_spi_clk,
  output wire         pad_HREADY,
  output wire[1 :0]  pad_HRESP
);

AHB_Controler_FLASH_BOOT AHB_Controller_FLASH_BOOT_inst(
  .HCLK        (pad_HCLK),
  .HRST_n      (pad_HRST_n),
  .HADDR       (pad_HADDR),
  .HWRITE      (pad_HWRITE),
  .HWDATA      (pad_HWDATA),
  .HSIZE       (pad_HSIZE),
  .HSELx       (pad_HSELx),
  .HTRANS      (pad_HTRANS),
  .i_pad_pmodb_miso  (pad_i_pad_pmodb_miso),
  .o_pad_pmodb_mosi  (pad_o_pad_pmodb_mosi),
  .o_pad_pmodb_cs    (pad_o_pad_pmodb_cs),
  .HRDATA            (pad_HRDATA),
  .HREADY            (pad_HREADY),
  .HRESP             (pad_HRESP)
);

endmodule
