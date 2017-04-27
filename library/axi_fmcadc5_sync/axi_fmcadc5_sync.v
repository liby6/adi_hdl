// ***************************************************************************
// ***************************************************************************
// Copyright 2011(c) Analog Devices, Inc.
// 
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//     - Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     - Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in
//       the documentation and/or other materials provided with the
//       distribution.
//     - Neither the name of Analog Devices, Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//     - The use of this software may or may not infringe the patent rights
//       of one or more patent holders.  This license does not release you
//       from the requirement that you obtain separate licenses from these
//       patent holders to use this software.
//     - Use of the software either in source or binary form, must be run
//       on or directly connected to an Analog Devices Inc. component.
//    
// THIS SOFTWARE IS PROVIDED BY ANALOG DEVICES "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
// PARTICULAR PURPOSE ARE DISCLAIMED.
//
// IN NO EVENT SHALL ANALOG DEVICES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, INTELLECTUAL PROPERTY
// RIGHTS, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ***************************************************************************
// ***************************************************************************
// this module is a helper core for linux. as much as possible, try not to use this core.
// best thing to do is look at no-os and implement a proper frame work in linux.
// most controls are scattered around other cores, here we collect them to provide a common access.

`timescale 1ns/100ps

module axi_fmcadc5_sync #(parameter integer ID = 0) (

    // receive interface
 
  input             rx_clk, 
  output            rx_sysref,
  input             rx_sync_0,
  input             rx_sync_1,
  output            rx_sysref_p,
  output            rx_sysref_n,
  output            rx_sync_0_p,
  output            rx_sync_0_n,
  output            rx_sync_1_p,
  output            rx_sync_1_n,

  // switching regulator clocks

  output            psync,

  // delay interface
 
  input             delay_rst,
  input             delay_clk,

  // spi override

  input   [  7:0]   spi_csn_o,
  input             spi_clk_o,
  input             spi_sdo_o,

  output  [  7:0]   spi_csn,
  output            spi_clk,
  output            spi_mosi,
  input             spi_miso,

  // axi interface

  input             s_axi_aclk,
  input             s_axi_aresetn,
  input             s_axi_awvalid,
  input   [ 31:0]   s_axi_awaddr,
  output            s_axi_awready,
  input             s_axi_wvalid,
  input   [ 31:0]   s_axi_wdata,
  input   [  3:0]   s_axi_wstrb,
  output            s_axi_wready,
  output            s_axi_bvalid,
  output  [  1:0]   s_axi_bresp,
  input             s_axi_bready,
  input             s_axi_arvalid,
  input   [ 31:0]   s_axi_araddr,
  output            s_axi_arready,
  output            s_axi_rvalid,
  output  [ 31:0]   s_axi_rdata,
  output  [  1:0]   s_axi_rresp,
  input             s_axi_rready,
  input   [ 2:0]    s_axi_awprot,
  input   [ 2:0]    s_axi_arprot);

  // version

  localparam  [31:0]  PCORE_VERSION = 32'h00040063;

  // internal registers

  reg     [  7:0]   up_psync_count = 'd0;
  reg               up_psync = 'd0;
  reg               up_sysref_ack_t_m1 = 'd0;
  reg               up_sysref_ack_t_m2 = 'd0;
  reg               up_sysref_ack_t_m3 = 'd0;
  reg               up_sysref_control_t = 'd0;
  reg     [  1:0]   up_sysref_mode_e = 'd0;
  reg               up_sysref_mode_i = 'd0;
  reg               up_sysref_req_t = 'd0;
  reg               up_sysref_status = 'd0;
  reg               up_sync_control_t = 'd0;
  reg               up_sync_mode = 'd0;
  reg               up_sync_disable_1 = 'd0;
  reg               up_sync_disable_0 = 'd0;
  reg               up_sync_status_t_m1 = 'd0;
  reg               up_sync_status_t_m2 = 'd0;
  reg               up_sync_status_t_m3 = 'd0;
  reg               up_sync_status_1 = 'd0;
  reg               up_sync_status_0 = 'd0;
  reg               up_delay_ld = 'd0;
  reg     [  4:0]   up_delay_wdata = 'd0;
  reg     [  7:0]   up_spi_csn_int = 'd0;
  reg               up_spi_clk_int = 'd0;
  reg               up_spi_mosi_int = 'd0;
  reg               up_spi_gnt = 'd0;
  reg               up_spi_req = 'd0;
  reg     [  7:0]   up_spi_csn = 'd0;
  reg     [  5:0]   up_spi_cnt = 'd0;
  reg     [ 31:0]   up_spi_clk_32 = 'd0;
  reg     [ 31:0]   up_spi_out_32 = 'd0;
  reg     [ 31:0]   up_spi_in_32 = 'd0;
  reg     [  7:0]   up_spi_out = 'd0;
  reg     [ 31:0]   up_scratch = 'd0;
  reg               up_wack = 'd0;
  reg               up_rack = 'd0;
  reg     [ 31:0]   up_rdata = 'd0;
  reg     [  7:0]   rx_sysref_cnt = 'd0;
  reg               rx_sysref_control_t_m1 = 'd0;
  reg               rx_sysref_control_t_m2 = 'd0;
  reg               rx_sysref_control_t_m3 = 'd0;
  reg     [  1:0]   rx_sysref_mode_e = 'd0;
  reg               rx_sysref_mode_i = 'd0;
  reg               rx_sysref_req_t_m1 = 'd0;
  reg               rx_sysref_req_t_m2 = 'd0;
  reg               rx_sysref_req_t_m3 = 'd0;
  reg               rx_sysref_req = 'd0;
  reg               rx_sysref_e = 'd0;
  reg               rx_sysref_i = 'd0;
  reg               rx_sysref_ack_t = 'd0;
  reg               rx_sysref_enb_e = 'd0;
  reg               rx_sysref_enb_i = 'd0;
  reg               rx_sync_control_t_m1 = 'd0;
  reg               rx_sync_control_t_m2 = 'd0;
  reg               rx_sync_control_t_m3 = 'd0;
  reg               rx_sync_mode = 'd0;
  reg               rx_sync_disable_1 = 'd0;
  reg               rx_sync_disable_0 = 'd0;
  reg               rx_sync_out_1 = 'd0;
  reg               rx_sync_out_0 = 'd0;
  reg     [  7:0]   rx_sync_cnt = 'd0;
  reg               rx_sync_hold_1 = 'd0;
  reg               rx_sync_hold_0 = 'd0;
  reg               rx_sync_status_t = 'd0;
  reg               rx_sync_status_1 = 'd0;
  reg               rx_sync_status_0 = 'd0;

  // internal signals

  wire              up_sysref_ack_t_s;
  wire              up_sync_status_t_s;
  wire              up_spi_gnt_s;
  wire    [ 31:0]   up_spi_out_32_s;
  wire    [  7:0]   up_spi_in_s;
  wire              rx_sysref_control_t_s;
  wire              rx_sysref_req_t_s;
  wire              rx_sysref_enb_e_s;
  wire              rx_sync_control_t_s;
  wire    [  4:0]   up_delay_rdata_s;
  wire              up_delay_locked_s;
  wire              up_wreq_s;
  wire    [ 13:0]   up_waddr_s;
  wire    [ 31:0]   up_wdata_s;
  wire              up_rreq_s;
  wire    [ 13:0]   up_raddr_s;
  wire              up_rstn;
  wire              up_clk;

  // signal name changes

  assign up_rstn = s_axi_aresetn;
  assign up_clk = s_axi_aclk;

  // switching regulator clocks (~602K)
 
  assign psync = up_psync;

  always @(negedge up_rstn or posedge up_clk) begin
    if (up_rstn == 1'b0) begin
      up_psync_count <= 7'd0;
      up_psync <= 1'b0;
    end else begin
      if (up_psync_count >= 7'h52) begin
        up_psync_count <= 7'd0;
      end else begin
        up_psync_count <= up_psync_count + 1'b1;
      end
      if (up_psync_count >= 7'h4f) begin
        up_psync <= ~up_psync;
      end
    end
  end

  // sysref register(s) 

  assign up_sysref_ack_t_s = up_sysref_ack_t_m3 ^ up_sysref_ack_t_m2;

  always @(negedge up_rstn or posedge up_clk) begin
    if (up_rstn == 1'b0) begin
      up_sysref_ack_t_m1 <= 1'd0;
      up_sysref_ack_t_m2 <= 1'd0;
      up_sysref_ack_t_m3 <= 1'd0;
    end else begin
      up_sysref_ack_t_m1 <= rx_sysref_ack_t;
      up_sysref_ack_t_m2 <= up_sysref_ack_t_m1;
      up_sysref_ack_t_m3 <= up_sysref_ack_t_m2;
    end
  end

  always @(negedge up_rstn or posedge up_clk) begin
    if (up_rstn == 0) begin
      up_sysref_control_t <= 1'd0;
      up_sysref_mode_e <= 2'd0;
      up_sysref_mode_i <= 1'd0;
      up_sysref_req_t <= 1'd0;
      up_sysref_status <= 1'b0;
    end else begin
      if ((up_wreq_s == 1'b1) && (up_waddr_s == 14'h0040)) begin
        up_sysref_control_t <= ~up_sysref_control_t;
        up_sysref_mode_e <= up_wdata_s[5:4];
        up_sysref_mode_i <= up_wdata_s[0];
      end
      if (up_sysref_status == 1'b1) begin
        if (up_sysref_ack_t_s == 1'b1) begin
          up_sysref_req_t <= up_sysref_req_t;
          up_sysref_status <= 1'b0;
        end
      end else if ((up_wreq_s == 1'b1) && (up_waddr_s == 14'h0041)) begin
        if (up_wdata_s[0] == 1'b1) begin
          up_sysref_req_t <= ~up_sysref_req_t;
          up_sysref_status <= 1'b1;
        end
      end
    end
  end

  // sync register(s) 

  always @(negedge up_rstn or posedge up_clk) begin
    if (up_rstn == 0) begin
      up_sync_control_t <= 1'd0;
      up_sync_mode <= 1'd0;
      up_sync_disable_1 <= 1'd0;
      up_sync_disable_0 <= 1'd0;
    end else begin
      if ((up_wreq_s == 1'b1) && (up_waddr_s == 14'h0030)) begin
        up_sync_control_t <= ~up_sync_control_t;
        up_sync_mode <= up_wdata_s[2];
        up_sync_disable_1 <= up_wdata_s[1];
        up_sync_disable_0 <= up_wdata_s[0];
      end
    end
  end

  // simple current status (no persistence)
 
  assign up_sync_status_t_s = up_sync_status_t_m3 ^ up_sync_status_t_m2;

  always @(negedge up_rstn or posedge up_clk) begin
    if (up_rstn == 0) begin
      up_sync_status_t_m1 <= 1'd0;
      up_sync_status_t_m2 <= 1'd0;
      up_sync_status_t_m3 <= 1'd0;
      up_sync_status_1 <= 1'd0;
      up_sync_status_0 <= 1'd0;
    end else begin
      up_sync_status_t_m1 <= rx_sync_status_t;
      up_sync_status_t_m2 <= up_sync_status_t_m1;
      up_sync_status_t_m3 <= up_sync_status_t_m2;
      if (up_sync_status_t_s == 1'b1) begin
        up_sync_status_1 <= rx_sync_status_1;
        up_sync_status_0 <= rx_sync_status_0;
      end
    end
  end

  // delay register(s)

  always @(negedge up_rstn or posedge up_clk) begin
    if (up_rstn == 0) begin
      up_delay_ld <= 1'd0;
      up_delay_wdata <= 5'd0;
    end else begin
      if ((up_wreq_s == 1'b1) && (up_waddr_s == 14'h0020)) begin
        up_delay_ld <= 1'b1;
      end else begin
        up_delay_ld <= 1'b0;
      end
      if ((up_wreq_s == 1'b1) && (up_waddr_s == 14'h0020)) begin
        up_delay_wdata <= up_wdata_s[4:0];
      end
    end
  end

  // switching must be glitchless
 
  assign spi_csn = up_spi_csn_int;
  assign spi_clk = up_spi_clk_int;
  assign spi_mosi = up_spi_mosi_int;

  always @(negedge up_clk) begin
    if (up_spi_gnt == 1'b1) begin
      up_spi_csn_int <= up_spi_csn;
      up_spi_clk_int <= up_spi_clk_32[31];
      up_spi_mosi_int <= up_spi_out_32[31];
    end else begin
      up_spi_csn_int <= spi_csn_o;
      up_spi_clk_int <= spi_clk_o;
      up_spi_mosi_int <= spi_sdo_o;
    end
  end
  
  assign up_spi_gnt_s = (&spi_csn_o) & ~spi_clk_o;

  always @(posedge up_clk or negedge up_rstn) begin
    if (up_rstn == 1'b0) begin
      up_spi_gnt <= 1'd0;
    end else begin
      if (up_spi_gnt_s == 1'b1) begin
        up_spi_gnt <= up_spi_req;
      end
    end
  end

  // spi data stretching

  assign up_spi_out_32_s[31:28] = {4{up_wdata_s[7]}};
  assign up_spi_out_32_s[27:24] = {4{up_wdata_s[6]}};
  assign up_spi_out_32_s[23:20] = {4{up_wdata_s[5]}};
  assign up_spi_out_32_s[19:16] = {4{up_wdata_s[4]}};
  assign up_spi_out_32_s[15:12] = {4{up_wdata_s[3]}};
  assign up_spi_out_32_s[11: 8] = {4{up_wdata_s[2]}};
  assign up_spi_out_32_s[ 7: 4] = {4{up_wdata_s[1]}};
  assign up_spi_out_32_s[ 3: 0] = {4{up_wdata_s[0]}};

  assign up_spi_in_s[7] = up_spi_in_32[28];
  assign up_spi_in_s[6] = up_spi_in_32[24];
  assign up_spi_in_s[5] = up_spi_in_32[20];
  assign up_spi_in_s[4] = up_spi_in_32[16];
  assign up_spi_in_s[3] = up_spi_in_32[12];
  assign up_spi_in_s[2] = up_spi_in_32[ 8];
  assign up_spi_in_s[1] = up_spi_in_32[ 4];
  assign up_spi_in_s[0] = up_spi_in_32[ 0];

  // spi register(s)

  always @(negedge up_rstn or posedge up_clk) begin
    if (up_rstn == 0) begin
      up_spi_req <= 1'd0;
      up_spi_csn <= {8{1'b1}};
      up_spi_cnt <= 6'd0;
      up_spi_clk_32 <= 32'd0;
      up_spi_out_32 <= 32'd0;
      up_spi_in_32 <= 32'd0;
      up_spi_out <= 8'd0;
    end else begin
      if ((up_wreq_s == 1'b1) && (up_waddr_s == 14'h0010)) begin
        up_spi_req <= up_wdata_s[0];
      end
      if ((up_wreq_s == 1'b1) && (up_waddr_s == 14'h0012)) begin
        up_spi_csn <= up_wdata_s[7:0];
      end
      if (up_spi_cnt[5] == 1'b1) begin
        up_spi_cnt <= up_spi_cnt + 1'b1;
        up_spi_clk_32 <= {up_spi_clk_32[30:0], 1'd0};
        up_spi_out_32 <= {up_spi_out_32[30:0], 1'd0};
        up_spi_in_32 <= {up_spi_in_32[30:0], spi_miso};
        up_spi_out <= up_spi_out;
      end else if ((up_wreq_s == 1'b1) && (up_waddr_s == 14'h0013)) begin
        up_spi_cnt <= 6'h20;
        up_spi_clk_32 <= {8{4'h6}};
        up_spi_out_32 <= up_spi_out_32_s;
        up_spi_in_32 <= {31'd0, spi_miso};
        up_spi_out <= up_wdata_s[7:0];
      end
    end
  end

  // scratch register(s)

  always @(negedge up_rstn or posedge up_clk) begin
    if (up_rstn == 0) begin
      up_scratch <= 'd0;
    end else begin
      if ((up_wreq_s == 1'b1) && (up_waddr_s == 14'h0002)) begin
        up_scratch <= up_wdata_s;
      end
    end
  end

  // processor read interface

  always @(negedge up_rstn or posedge up_clk) begin
    if (up_rstn == 0) begin
      up_wack <= 'd0;
      up_rack <= 'd0;
      up_rdata <= 'd0;
    end else begin
      up_wack <= up_wreq_s;
      up_rack <= up_rreq_s;
      if (up_rreq_s == 1'b1) begin
        case (up_raddr_s)
          14'h0000: up_rdata <= PCORE_VERSION;
          14'h0001: up_rdata <= ID;
          14'h0002: up_rdata <= up_scratch;
          14'h0010: up_rdata <= {31'd0, up_spi_req};
          14'h0011: up_rdata <= {31'd0, up_spi_gnt};
          14'h0012: up_rdata <= {24'd0, up_spi_csn};
          14'h0013: up_rdata <= {24'd0, up_spi_out};
          14'h0014: up_rdata <= {24'd0, up_spi_in_s};
          14'h0015: up_rdata <= {31'd0, up_spi_cnt[5]};
          14'h0020: up_rdata <= {27'd0, up_delay_wdata};
          14'h0021: up_rdata <= {27'd0, up_delay_rdata_s};
          14'h0022: up_rdata <= {31'd0, up_delay_locked_s};
          14'h0030: up_rdata <= {29'd0, up_sync_mode, up_sync_disable_1, up_sync_disable_0};
          14'h0031: up_rdata <= {30'd0, up_sync_status_1, up_sync_status_0};
          14'h0040: up_rdata <= {26'd0, up_sysref_mode_e, 3'b0, up_sysref_mode_i};
          14'h0041: up_rdata <= {31'd0, up_sysref_status};
          default: up_rdata <= 0;
        endcase
      end else begin
        up_rdata <= 32'd0;
      end
    end
  end

  // sysref-control at receive clock

  always @(posedge rx_clk) begin
    rx_sysref_cnt <= rx_sysref_cnt + 1'b1;
  end

  assign rx_sysref_control_t_s = rx_sysref_control_t_m3 ^ rx_sysref_control_t_m2;
  assign rx_sysref_req_t_s = rx_sysref_req_t_m3 ^ rx_sysref_req_t_m2;

  always @(posedge rx_clk) begin
    rx_sysref_control_t_m1 <= up_sysref_control_t;
    rx_sysref_control_t_m2 <= rx_sysref_control_t_m1;
    rx_sysref_control_t_m3 <= rx_sysref_control_t_m2;
    if (rx_sysref_control_t_s == 1'b1) begin
      rx_sysref_mode_e <= up_sysref_mode_e;
      rx_sysref_mode_i <= up_sysref_mode_i;
    end
    rx_sysref_req_t_m1 <= up_sysref_req_t;
    rx_sysref_req_t_m2 <= rx_sysref_req_t_m1;
    rx_sysref_req_t_m3 <= rx_sysref_req_t_m2;
    if ((rx_sysref_cnt == 8'd0) || (rx_sysref_req_t_s == 1'b1)) begin
      rx_sysref_req <= rx_sysref_req_t_s;
    end
  end

  assign rx_sysref_enb_e_s = (rx_sysref_mode_e == 2'b10) ? rx_sysref_req :
    ((rx_sysref_mode_e == 2'b00) ? 1'b1 : 1'b0);

  always @(posedge rx_clk) begin
    rx_sysref_e <= rx_sysref_cnt[7] & rx_sysref_enb_e;
    rx_sysref_i <= rx_sysref_cnt[7] & rx_sysref_enb_i;
    if (rx_sysref_cnt == 8'd0) begin
      if (rx_sysref_enb_e == 1'b1) begin
        rx_sysref_ack_t <= ~rx_sysref_ack_t;
      end
      rx_sysref_enb_e <= rx_sysref_enb_e_s;
      rx_sysref_enb_i <= ~rx_sysref_mode_i;
    end
  end

  // sync-control at receive clock

  assign rx_sync_control_t_s = rx_sync_control_t_m3 ^ rx_sync_control_t_m2;

  always @(posedge rx_clk) begin
    rx_sync_control_t_m1 <= up_sync_control_t;
    rx_sync_control_t_m2 <= rx_sync_control_t_m1;
    rx_sync_control_t_m3 <= rx_sync_control_t_m2;
    if (rx_sync_control_t_s == 1'b1) begin
      rx_sync_mode <= up_sync_mode;
      rx_sync_disable_1 <= up_sync_disable_1;
      rx_sync_disable_0 <= up_sync_disable_0;
    end
    if (rx_sync_mode == 1'b1) begin
      rx_sync_out_1 <= ~rx_sync_disable_1 & rx_sync_1 & rx_sync_0;
      rx_sync_out_0 <= ~rx_sync_disable_0 & rx_sync_1 & rx_sync_0;
    end else begin
      rx_sync_out_1 <= ~rx_sync_disable_1 & rx_sync_1;
      rx_sync_out_0 <= ~rx_sync_disable_0 & rx_sync_0;
    end
  end

  always @(posedge rx_clk) begin
    rx_sync_cnt <= rx_sync_cnt + 1'b1;
    if ((rx_sync_cnt == 8'd0) || (rx_sync_1 == 1'b0)) begin
      rx_sync_hold_1 <= rx_sync_1;
    end
    if ((rx_sync_cnt == 8'd0) || (rx_sync_0 == 1'b0)) begin
      rx_sync_hold_0 <= rx_sync_0;
    end
    if (rx_sync_cnt == 8'd0) begin
      rx_sync_status_t <= ~rx_sync_status_t;
      rx_sync_status_1 <= rx_sync_hold_1;
      rx_sync_status_0 <= rx_sync_hold_0;
    end
  end

  // sync buffers
 
  OBUFDS i_obufds_rx_sync_1 (
    .I (rx_sync_out_1),
    .O (rx_sync_1_p),
    .OB (rx_sync_1_n));

  OBUFDS i_obufds_rx_sync_0 (
    .I (rx_sync_out_0),
    .O (rx_sync_0_p),
    .OB (rx_sync_0_n));

  // sysref delay control

  assign rx_sysref = rx_sysref_i;

  ad_lvds_out #(
    .DEVICE_TYPE (0),
    .SINGLE_ENDED (0),
    .IODELAY_ENABLE (1),
    .IODELAY_CTRL (1),
    .IODELAY_GROUP ("FMCADC5_SYSREF_IODELAY_GROUP"))
  i_rx_sysref (
    .tx_clk (rx_clk),
    .tx_data_p (rx_sysref_e),
    .tx_data_n (rx_sysref_e),
    .tx_data_out_p (rx_sysref_p),
    .tx_data_out_n (rx_sysref_n),
    .up_clk (up_clk),
    .up_dld (up_delay_ld),
    .up_dwdata (up_delay_wdata),
    .up_drdata (up_delay_rdata_s),
    .delay_clk (delay_clk),
    .delay_rst (delay_rst),
    .delay_locked (up_delay_locked_s));

  // up == micro("u") processor
 
  up_axi i_up_axi (
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_axi_awvalid (s_axi_awvalid),
    .up_axi_awaddr (s_axi_awaddr),
    .up_axi_awready (s_axi_awready),
    .up_axi_wvalid (s_axi_wvalid),
    .up_axi_wdata (s_axi_wdata),
    .up_axi_wstrb (s_axi_wstrb),
    .up_axi_wready (s_axi_wready),
    .up_axi_bvalid (s_axi_bvalid),
    .up_axi_bresp (s_axi_bresp),
    .up_axi_bready (s_axi_bready),
    .up_axi_arvalid (s_axi_arvalid),
    .up_axi_araddr (s_axi_araddr),
    .up_axi_arready (s_axi_arready),
    .up_axi_rvalid (s_axi_rvalid),
    .up_axi_rresp (s_axi_rresp),
    .up_axi_rdata (s_axi_rdata),
    .up_axi_rready (s_axi_rready),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata),
    .up_rack (up_rack));

endmodule

// ***************************************************************************
// ***************************************************************************
