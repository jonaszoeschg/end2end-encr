// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
module tb;
  // dep packages
  import uvm_pkg::*;
  import dv_utils_pkg::*;
  import i2c_env_pkg::*;
  import i2c_test_pkg::*;

  // macro includes
  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  wire clk, rst_n;
  wire devmode;
  wire intr_fmt_watermark;
  wire intr_rx_watermark;
  wire intr_fmt_overflow;
  wire intr_rx_overflow;
  wire intr_nak;
  wire intr_scl_interference;
  wire intr_sda_interference;
  wire intr_stretch_timeout;
  wire intr_sda_unstable;
  wire intr_trans_complete;
  wire intr_tx_empty;
  wire intr_tx_overflow;
  wire intr_acq_full;
  wire intr_ack_stop;
  wire intr_host_timeout;
  wire [NUM_MAX_INTERRUPTS-1:0] interrupts;

  wire cio_scl;
  wire cio_sda;
  wire cio_scl_en;
  wire cio_sda_en;

  // interfaces
  clk_rst_if clk_rst_if(.clk(clk), .rst_n(rst_n));
  pins_if #(NUM_MAX_INTERRUPTS) intr_if(interrupts);
  pins_if #(1) devmode_if(devmode);

  tl_if tl_if(.clk(clk), .rst_n(rst_n));

  wire scl, sda;
  i2c_if i2c_if(
    .clk_i(clk),
    .rst_ni(rst_n),
    .scl_io(scl),
    .sda_io(sda)
  );

  // Model PAD behavior
  i2c_port_conv i2c_port_conv (
    .scl_oe_i(cio_scl_en),
    .sda_oe_i(cio_sda_en),
    .scl_o(cio_scl),
    .sda_o(cio_sda),
    .scl_io(scl),
    .sda_io(sda)
  );

  // Model external pull-up resistor
  assign (weak0, weak1) scl = 1'b1;
  assign (weak0, weak1) sda = 1'b1;

  // clk and rst_n is used for alert_if in `DV_ALERT_IF_CONNECT
  `DV_ALERT_IF_CONNECT

  // dut
  i2c dut (
    .clk_i                   (clk        ),
    .rst_ni                  (rst_n      ),

    .tl_i                    (tl_if.h2d  ),
    .tl_o                    (tl_if.d2h  ),

    .alert_rx_i              (alert_rx   ),
    .alert_tx_o              (alert_tx   ),

    .cio_scl_i               (cio_scl               ),
    .cio_scl_o               (/*hardcoded to 0*/    ),
    .cio_scl_en_o            (cio_scl_en            ),
    .cio_sda_i               (cio_sda               ),
    .cio_sda_o               (/*hardcoded to 0*/    ),
    .cio_sda_en_o            (cio_sda_en            ),

    .intr_fmt_watermark_o    (intr_fmt_watermark    ),
    .intr_rx_watermark_o     (intr_rx_watermark     ),
    .intr_fmt_overflow_o     (intr_fmt_overflow     ),
    .intr_rx_overflow_o      (intr_rx_overflow      ),
    .intr_nak_o              (intr_nak              ),
    .intr_scl_interference_o (intr_scl_interference ),
    .intr_sda_interference_o (intr_sda_interference ),
    .intr_stretch_timeout_o  (intr_stretch_timeout  ),
    .intr_sda_unstable_o     (intr_sda_unstable     ),
    .intr_trans_complete_o   (intr_trans_complete   ),
    .intr_tx_empty_o         (intr_tx_empty         ),
    .intr_tx_overflow_o      (intr_tx_overflow      ),
    .intr_acq_full_o         (intr_acq_full         ),
    .intr_ack_stop_o         (intr_ack_stop         ),
    .intr_host_timeout_o     (intr_host_timeout     )
  );

  // interrupt
  assign interrupts[FmtWatermark]   = intr_fmt_watermark;
  assign interrupts[RxWatermark]    = intr_rx_watermark;
  assign interrupts[FmtOverflow]    = intr_fmt_overflow;
  assign interrupts[RxOverflow]     = intr_rx_overflow;
  assign interrupts[Nak]            = intr_nak;
  assign interrupts[SclInference]   = intr_scl_interference;
  assign interrupts[SdaInference]   = intr_sda_interference;
  assign interrupts[StretchTimeout] = intr_stretch_timeout;
  assign interrupts[SdaUnstable]    = intr_sda_unstable;
  assign interrupts[TransComplete]  = intr_trans_complete;
  assign interrupts[TxEmpty]        = intr_tx_empty;
  assign interrupts[TxOverflow]     = intr_tx_overflow;
  assign interrupts[AcqFull]        = intr_acq_full;
  assign interrupts[AckStop]        = intr_ack_stop;
  assign interrupts[HostTimeout]    = intr_host_timeout;

  initial begin
    // drive clk and rst_n from clk_if
    clk_rst_if.set_active();
    uvm_config_db#(virtual clk_rst_if)::set(null, "*.env", "clk_rst_vif", clk_rst_if);
    uvm_config_db#(intr_vif)::set(null, "*.env", "intr_vif", intr_if);
    uvm_config_db#(devmode_vif)::set(null, "*.env", "devmode_vif", devmode_if);
    uvm_config_db#(virtual tl_if)::set(null, "*.env.m_tl_agent*", "vif", tl_if);
    uvm_config_db#(virtual i2c_if)::set(null, "*.env.m_i2c_agent*", "vif", i2c_if);
    $timeformat(-12, 0, " ps", 12);
    run_test();
  end

endmodule : tb
