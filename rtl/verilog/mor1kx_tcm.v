/* ****************************************************************************
  This Source Code Form is subject to the terms of the
  Open Hardware Description License, v. 1.0. If a copy
  of the OHDL was not distributed with this file, You
  can obtain one at http://juliusbaxter.net/ohdl/ohdl.txt

  Description: mor1kx Instruction TCM memory. Also, adds a Wishbone slave bus
  which can be used to access this TCM memory independent of processor.

  Copyright (C) 2017 Authors

  Author(s): Rohit Kumar Singh <rohit.singh@gmx.com>

***************************************************************************** */

`include "mor1kx-defines.v"

module mor1kx_ibus_tcm
  #(
    parameter TCM_SIZE   = 32,
    parameter INSN_WIDTH = 32
    )
   (
    input clk,
    input rst,

    // CPU ibus interface
    input  [31:0] cpu_adr_i,
    input         cpu_req_i,
    input         cpu_burst_i,
    output [31:0] cpu_dat_o,
    output        cpu_err_o,
    output        cpu_ack_o,

    // TCM Wishbone slave interface
    input  [31:0]  wbs_adr_i,
    input          wbs_stb_i,
    input          wbs_cyc_i,
    input  [3:0]   wbs_sel_i,
    input          wbs_we_i,
    input  [2:0]   wbs_cti_i,
    input  [1:0]   wbs_bte_i,
    input  [31:0]  wbs_dat_i,
    output         wbs_err_o,
    output         wbs_ack_o,
    output [31:0]  wbs_dat_o,
    output         wbs_rty_o
    );

    reg cpu_ack = 1'b0;
    reg wbs_ack = 1'b0;

    assign cpu_ack_o = cpu_ack;
    assign cpu_err_o = 1'b0;

    assign wbs_ack_o = wbs_ack;
    assign wbs_err_o = 1'b0;
    assign wbs_rty_o = 1'b0;

    // Burst transfers are not supported. Ignore `wbs_cti_i` and `wbs_bte_i`.
    always @ ( posedge clk ) begin
      if (wbs_cyc_i & wbs_stb_i & wbs_ack_o) begin
        wbs_ack <= 1'b0;
      end else if (wbs_cyc_i & wbs_stb_i & ~wbs_ack_o) begin
        wbs_ack <= 1'b1;
      end else begin
        wbs_ack <= 1'b0;
      end
    end

    // mor1kx ibus burst reads are not supported. Ignore `cpu_burst_i` signal.
    // TODO: Add mor1kx ibus burst reads since we can support it with dpram
    always @ ( posedge clk ) begin
      if (cpu_req_i & cpu_ack_o) begin
        cpu_ack <= 1'b0;
      end else if (cpu_req_i & ~cpu_ack_o) begin
        cpu_ack <= 1'b1;
      end else begin
        cpu_ack <= 1'b0;
      end
    end

    mor1kx_true_dpram_sclk
      #(
        .ADDR_WIDTH  (TCM_SIZE),
        .DATA_WIDTH  (INSN_WIDTH)
      )
    ibus_tcm
      (
        .clk         (clk),

        // Port A: Used by mor1kx ibus
        .addr_a      (cpu_adr_i[TCM_SIZE-1:2]),
        .dout_a      (cpu_dat_o),
        .din_a       ({INSN_WIDTH{1'b0}}),
        .we_a        (1'b0),

        // Port B: Used by Wishbone slave interface
        .addr_b      (wbs_adr_i[TCM_SIZE-1:2]),
        .dout_b      (wbs_dat_o),
        .din_b       (wbs_dat_i),
        .we_b        (wbs_cyc_i & wbs_stb_i & wbs_we_i & wbs_ack_o));

endmodule // mor1kx_tcm
