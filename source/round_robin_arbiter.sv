/*
The round_robin_arbiter module is designed to fairly allocate resources among multiple requesters
using a round-robin arbitration scheme. It ensures that each requester gets a chance to access the
resource in a cyclic order, preventing any single requester from monopolizing the resource. The
module handles request signals, prioritizes them based on a rotating index, and grants access
accordingly, making it ideal for systems where fair resource distribution is crucial.
Author : Foez Ahmed (foez.official@gmail.com)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module round_robin_arbiter #(
    parameter int NUM_REQ = 4  // Number of requesters
) (
    input logic arst_ni,  // Asynchronous reset, active low
    input logic clk_i,    // Clock input

    input logic [NUM_REQ-1:0] req_i,  // Request signals

    output logic [NUM_REQ-1:0] gnt_o  // Grant signals
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic fp_arb_req[NUM_REQ];  // Requests for fixed priority arbiter
  logic fp_arb_gnt[NUM_REQ];  // Grants from fixed priority arbiter

  logic [$clog2(NUM_REQ)-1:0] index_o;  // Index of granted request

  logic [$clog2(NUM_REQ)-1:0] rot_index;  // Current rotation index
  logic [$clog2(NUM_REQ)-1:0] rot_index_next;  // Next rotation index
  logic [$clog2(NUM_REQ)-1:0] rot_index_latch_en;  // Latch enable signal for rotation index

  logic [$clog2(NUM_REQ)-1:0] final_rot_index;  // Final rotation index

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Calculate the final rotation index
  always_comb final_rot_index = (NUM_REQ - rot_index) % NUM_REQ;

  // Calculate the next rotation index
  always_comb rot_index_next = (1 + rot_index) % NUM_REQ;

  // Enable latch when any grant is active
  always_comb rot_index_latch_en = |gnt_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Rotate requests according to the current rotation index
  rotating_xbar #(
      .NUM_DATA  (NUM_REQ),
      .DATA_WIDTH(1)
  ) u_rotate_req (
      .input_vector_i (req_i),       // Connect request inputs
      .output_vector_o(fp_arb_req),  // Connect rotated request outputs
      .start_select_i (rot_index)    // Connect starting selection index
  );

  // Fixed priority arbiter for the rotated requests
  fixed_priority_arbiter #(
      .NUM_REQ(NUM_REQ)
  ) u_fixed_priority_arbiter (
      .req_i(fp_arb_req),  // Connect rotated request inputs
      .gnt_o(fp_arb_gnt)   // Connect grant outputs
  );

  // Rotate grants back according to the final rotation index
  rotating_xbar #(
      .NUM_DATA  (NUM_REQ),
      .DATA_WIDTH(1)
  ) u_rotate_gnt (
      .input_vector_i (fp_arb_gnt),      // Connect grant inputs from fixed priority arbiter
      .output_vector_o(gnt_o),           // Connect grant outputs
      .start_select_i (final_rot_index)  // Connect final rotation index
  );

  // Encode the grant signals to find the index of the granted request
  encoder #(
      .NUM_WIRE(NUM_REQ)
  ) u_encoder (
      .wire_in(gnt_o),  // Connect grant signals
      .index_o  // Output the index of granted request
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Sequential logic to update the rotation index
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (~arst_ni) begin
      rot_index <= '0;  // Reset the rotation index
    end else if (rot_index_latch_en) begin
      rot_index <= rot_index_next;  // Update the rotation index
    end
  end

endmodule