/*
Description
Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module round_robin_arbiter_tb;

  `define ENABLE_DUMPFILE 

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int NUM_REQ = 4;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef logic [NUM_REQ-1:0] n_req_gnt;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  logic arst_ni;
  logic allow_i = '1;
  n_req_gnt req_i;
  n_req_gnt gnt_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  int n_sent = 0;
  int grant_iter;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-INTERFACES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-CLASSES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  round_robin_arbiter #(
      .NUM_REQ(NUM_REQ)
  ) u_rra_tb_1 (
      .arst_ni,
      .clk_i,
      .allow_i,
      .req_i,
      .gnt_o
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic apply_reset();
    @(posedge clk_i);
    arst_ni <= 0;
    @(posedge clk_i);
    arst_ni <= 1;
  endtask 

  task automatic start_random_driver();
    @(posedge clk_i);
    fork
      begin
        forever begin
          @(posedge clk_i);
          allow_i <= '1;
          req_i   <= 'b1101;
          n_sent++;
        end
      end
    join_none
  endtask

  task automatic start_in_out_monitor();
    fork
      forever begin
        @(posedge clk_i);
        $display("sim: [%.1f], rotation: %d", $time, n_sent);
        $display("requests allowed: %b", allow_i);
        $display("requests profile: %b", req_i);
        $display("grants profile: %b", gnt_o);
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  int test_sent;

  initial begin  // main initial
    start_clk_i();
    apply_reset();
    start_random_driver();
    start_in_out_monitor();
  end

  // initial begin
  //   #105ns;
  //   apply_reset();
  //   $display("[%.1f] Sent in a reset XD", $time);
  // end

  initial begin
    test_sent = 20;
    forever begin
      @(posedge clk_i);
      if (n_sent == test_sent) begin
        $display("Simulation: %0d", n_sent);
        $finish;
      end
    end
  end

endmodule