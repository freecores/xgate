

module xgate_jtag #(parameter IR_BITS = 4)    // Number of Instruction Register Bits
  (
  output           jtag_tdo,      // JTAG Serial Output Data
  output           jtag_tdo_en,   // JTAG Serial Output Data tri-state enable

  input            jtag_tdi,      // JTAG Serial Input Data
  input            jtag_clk,      // JTAG Test clock
  input            jtag_reset_n,  // JTAG Async reset signal
  input            jtag_tms       // JTAG Test Mode Select
  );

  wire [3:0] jtag_state;
  wire [3:0] next_jtag_state;

  wire           update_ir;
  wire           capture_ir;
  wire           shift_ir;
  wire           update_dr;
  wire           capture_dr;
  wire           shift_dr;

  assign jtag_tdo = 1'b1;
  assign jtag_tdo_en = 1'b0;

  // ---------------------------------------------------------------------------
  xgate_jtag_sm
    jtag_sm(
    .jtag_state(jtag_state),
    .next_jtag_state(next_jtag_state),
    .update_ir(update_ir),
    .capture_ir(capture_ir),
    .shift_ir(shift_ir),
    .update_dr(update_dr),
    .capture_dr(capture_dr),
    .shift_dr(shift_dr),
    .jtag_clk(jtag_clk),
    .jtag_reset_n(jtag_reset_n),
    .jtag_tms(jtag_tms)
    );

  // ---------------------------------------------------------------------------
  xgate_jtag_ir #(.IR_BITS(IR_BITS))
    jtag_ir(
    .update_ir(update_ir),
    .capture_ir(capture_ir),
    .shift_ir(shift_ir),
    .jtag_clk(jtag_clk),
    .jtag_tdi(jtag_tdi),
    .jtag_reset_n(jtag_reset_n),
    .jtag_tms(jtag_tms)
    );
    
  // ---------------------------------------------------------------------------
  bc_2
    gpio_0_bc2(
    .capture_clk(),
    .update_clk(),
    .capture_en(bsr_capture),
    .update_en(bsr_update),
    .shift_dr(bsr_shift),
    .mode(),
    .si(),
    .data_in(from_core_gpio_0),
    .reset_n(),
    .data_out(to_pad_gpio_0),
    .so(gpio_0_bc2_so)
  );


endmodule  // xgate_jtag


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module xgate_jtag_sm
  (
  output reg [3:0] jtag_state,        // JTAG State
  output reg [3:0] next_jtag_state,   // Pseudo Register for JTAG next state logic

  output           update_ir,
  output           capture_ir,
  output           shift_ir,

  output           update_dr,
  output           capture_dr,
  output           shift_dr,

  input            jtag_clk,      // JTAG Test clock
  input            jtag_reset_n,  // JTAG Async reset signal
  input            jtag_tms       // JTAG Test Mode Select
  );

parameter RESET         = 4'b0000,
          RUN_TEST_IDLE = 4'b1000,
          SEL_DR_SCAN   = 4'b0001,
          CAPTURE_DR    = 4'b0010,
          SHIFT_DR      = 4'b0011,
          EXIT1_DR      = 4'b0100,
          PAUSE_DR      = 4'b0101,
          EXIT2_DR      = 4'b0110,
          UPDATE_DR     = 4'b0111,
          SEL_IR_SCAN   = 4'b1001,
          CAPTURE_IR    = 4'b1010,
          SHIFT_IR      = 4'b1011,
          EXIT1_IR      = 4'b1100,
          PAUSE_IR      = 4'b1101,
          EXIT2_IR      = 4'b1110,
          UPDATE_IR     = 4'b1111;

  assign update_ir  = jtag_state == UPDATE_IR;
  assign capture_ir = jtag_state == CAPTURE_IR;
  assign shift_ir   = jtag_state == SHIFT_IR;

  assign update_dr  = jtag_state == UPDATE_DR;
  assign capture_dr = jtag_state == CAPTURE_DR;
  assign shift_dr   = jtag_state == SHIFT_DR;


// Define the JTAG State Register
  always @(posedge jtag_clk or negedge jtag_reset_n)
    if (!jtag_reset_n)
      jtag_state <= RESET;
    else
      jtag_state <= next_jtag_state;

// Define the JTAG State Transitions
  always @*
    begin
      case(jtag_state)
        RESET:
          next_jtag_state = jtag_tms ? RESET : RUN_TEST_IDLE;
        RUN_TEST_IDLE:
          next_jtag_state = jtag_tms ? SEL_DR_SCAN : RUN_TEST_IDLE;
        SEL_DR_SCAN:
          next_jtag_state = jtag_tms ? SEL_IR_SCAN : CAPTURE_DR;
        CAPTURE_DR:
          next_jtag_state = jtag_tms ? EXIT1_DR : SHIFT_DR;
        SHIFT_DR:
          next_jtag_state = jtag_tms ? EXIT1_DR : SHIFT_DR;
        EXIT1_DR:
          next_jtag_state = jtag_tms ? UPDATE_DR : PAUSE_DR;
        PAUSE_DR:
          next_jtag_state = jtag_tms ? EXIT2_DR : PAUSE_DR;
        EXIT2_DR:
          next_jtag_state = jtag_tms ? UPDATE_DR : SHIFT_DR;
        UPDATE_DR:
          next_jtag_state = jtag_tms ? SEL_DR_SCAN : RUN_TEST_IDLE;

        SEL_IR_SCAN:
          next_jtag_state = jtag_tms ? RESET : CAPTURE_IR;
        CAPTURE_IR:
          next_jtag_state = jtag_tms ? EXIT1_IR : SHIFT_IR;
        SHIFT_IR:
          next_jtag_state = jtag_tms ? EXIT1_IR : SHIFT_IR;
        EXIT1_IR:
          next_jtag_state = jtag_tms ? UPDATE_IR : PAUSE_IR;
        PAUSE_IR:
          next_jtag_state = jtag_tms ? EXIT2_IR : PAUSE_IR;
        EXIT2_IR:
          next_jtag_state = jtag_tms ? UPDATE_IR : SHIFT_IR;
        UPDATE_IR:
          next_jtag_state = jtag_tms ? SEL_DR_SCAN : RUN_TEST_IDLE;
      endcase
    end

endmodule  // xgate_jtag_sm


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module xgate_jtag_ir #(parameter IR_BITS = 4)    // Number of Instruction Register Bits
  (
  output reg [IR_BITS-1:0] ir_reg,

  input            update_ir,
  input            capture_ir,
  input            shift_ir,

  input            jtag_tdi,      // JTAG Serial Input Data
  input            jtag_clk,      // JTAG Test clock
  input            jtag_reset_n,  // JTAG Async reset signal
  input            jtag_tms       // JTAG Test Mode Select
  );

  reg [IR_BITS-1:0] ir_shift_reg;

// JTAG Instruction Shift Register
  always @(posedge jtag_clk or negedge jtag_reset_n)
    if (!jtag_reset_n)
      ir_shift_reg <= 0;
    else if (capture_ir)
      ir_shift_reg <= ir_reg;
    else if (shift_ir)
      ir_shift_reg <= {jtag_tdi, ir_shift_reg[(IR_BITS-1):1]};

// JTAG Instruction Register
  always @(posedge jtag_clk or negedge jtag_reset_n)
    if (!jtag_reset_n)
      ir_reg <= 0;
    else if (update_ir)
      ir_reg <= ir_shift_reg;


endmodule  // xgate_jtag_ir


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module test_mode_cntrl #(parameter NUM_BITS  = 10)
  (
   // OUTPUT
   output so,
   output reg [NUM_BITS-1:0] mode_bits,

   // INPUTs
   input [NUM_BITS-1:0] obs_in,
   input si,
   input capture_clk,
   input update_clk,
   input capture_en,
   input update_en,
   input inst_en,
   input shift_en,
   input reset_n
  );


  reg [NUM_BITS-1:0] shift_reg;

  wire [NUM_BITS-1:0] din_mux = shift_en ? {shift_reg[NUM_BITS-1:1], si} : obs_in;
  wire [NUM_BITS-1:0] cap_mux = capture_en ? shift_reg : din_mux;
  wire [NUM_BITS-1:0] update_mux = update_en ? shift_reg : mode_bits;

  always @(posedge capture_clk or negedge reset_n)
    if (!reset_n)
      shift_reg <= 0;
    else if (inst_en)
      shift_reg <= cap_mux;

  always @(posedge update_clk or negedge reset_n)
    if (!reset_n)
      mode_bits <= 0;
    else if (inst_en)
      mode_bits <= update_mux;

  assign so = shift_reg[NUM_BITS-1];

endmodule  //


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module bc_7
(
  input capture_clk,
  input update_clk,
  input capture_en,
  input update_en,
  input shift_dr,
  input mode1,
  input si,
  input pin_input,
  input control_out,
  input output_data,
  input reset_n,

  output     ic_input,
  output     data_out,
  output reg so
  );

  reg data_reg;
  reg enable_reg;
  reg control_reg;
  reg so_0;

  // Shift register
  always @(posedge capture_clk or negedge reset_n)
    if (!reset_n)
      so <= 0;
    else if (capture_en)
      so <= shift_dr ? si : ((!control_out || mode1) ? pin_input : output_data);

  // Holding register
  always @(posedge update_clk or negedge reset_n)
    if (!reset_n)
      data_reg <= 0;
    else if (update_en)
      data_reg <= so;

  assign data_out = mode ? data_reg : output_data;

endmodule  // bc_7


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module bc_2
(
  input      capture_clk,  // Shift and input capture clock
  input      update_clk,   // Load holding register
  input      capture_en,   // Enable shift/capture register input loading,
  input      update_en,    // Enable holding register input loading
  input      shift_dr,     // Select eather shift mode or parallel capture mode
  input      mode,         // Select test mode or mission mode output
  input      si,           // Serial data input
  input      data_in,      // Mission mode input
  input      reset_n,      // reset

  output     data_out,     // Final data to pad
  output reg so            // Serial data out
  );

  reg data_reg;

  // Shift register
  always @(posedge capture_clk or negedge reset_n)
    if (!reset_n)
      so <= 0;
    else if (capture_en)
      so <= shift_dr ? si : data_out;

  // Holding register
  always @(posedge update_clk or negedge reset_n)
    if (!reset_n)
      data_reg <= 0;
    else if (update_en)
      data_reg <= so;

  assign data_out = mode ? data_reg : data_in;

endmodule  // bc_2
