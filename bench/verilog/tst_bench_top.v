////////////////////////////////////////////////////////////////////////////////
//
//  WISHBONE revB.2 compliant Xgate Coprocessor - Test Bench
//
//  Author: Bob Hayes
//          rehayes@opencores.org
//
//  Downloaded from: http://www.opencores.org/projects/xgate.....
//
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2009, Robert Hayes
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Supplemental terms.
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Neither the name of the <organization> nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY Robert Hayes ''AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL Robert Hayes BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
////////////////////////////////////////////////////////////////////////////////
// 45678901234567890123456789012345678901234567890123456789012345678901234567890


`include "timescale.v"

module tst_bench_top();

  parameter MAX_CHANNEL = 127;    // Max XGATE Interrupt Channel Number
  parameter STOP_ON_ERROR = 1'b0;
  parameter MAX_VECTOR = 2200;

  parameter L_BYTE = 2'bx1;
  parameter H_BYTE = 2'b1x;
  parameter WORD   = 2'b11;


  // Name Address Locations
  parameter XGATE_BASE     = 32'b0;
  parameter XGATE_XGMCTL   = XGATE_BASE + 5'h00;
  parameter XGATE_XGCHID   = XGATE_BASE + 5'h01;
  parameter XGATE_XGISPHI  = XGATE_BASE + 5'h02;
  parameter XGATE_XGISPLO  = XGATE_BASE + 5'h03;
  parameter XGATE_XGVBR    = XGATE_BASE + 5'h04;
  parameter XGATE_XGIF_7   = XGATE_BASE + 5'h05;
  parameter XGATE_XGIF_6   = XGATE_BASE + 5'h06;
  parameter XGATE_XGIF_5   = XGATE_BASE + 5'h07;
  parameter XGATE_XGIF_4   = XGATE_BASE + 5'h08;
  parameter XGATE_XGIF_3   = XGATE_BASE + 5'h09;
  parameter XGATE_XGIF_2   = XGATE_BASE + 5'h0a;
  parameter XGATE_XGIF_1   = XGATE_BASE + 5'h0b;
  parameter XGATE_XGIF_0   = XGATE_BASE + 5'h0c;
  parameter XGATE_XGSWT    = XGATE_BASE + 5'h0d;
  parameter XGATE_XGSEM    = XGATE_BASE + 5'h0e;
  parameter XGATE_RES1     = XGATE_BASE + 5'h0f;
  parameter XGATE_XGCCR    = XGATE_BASE + 5'h10;
  parameter XGATE_XGPC     = XGATE_BASE + 5'h11;
  parameter XGATE_RES2     = XGATE_BASE + 5'h12;
  parameter XGATE_XGR1     = XGATE_BASE + 5'h13;
  parameter XGATE_XGR2     = XGATE_BASE + 5'h14;
  parameter XGATE_XGR3     = XGATE_BASE + 5'h15;
  parameter XGATE_XGR4     = XGATE_BASE + 5'h16;
  parameter XGATE_XGR5     = XGATE_BASE + 5'h17;
  parameter XGATE_XGR6     = XGATE_BASE + 5'h18;
  parameter XGATE_XGR7     = XGATE_BASE + 5'h19;

  // Define bits in XGATE Control Register
  parameter XGMCTL_XGEM     = 16'h8000;
  parameter XGMCTL_XGFRZM   = 16'h4000;
  parameter XGMCTL_XGDBGM   = 15'h2000;
  parameter XGMCTL_XGSSM    = 15'h1000;
  parameter XGMCTL_XGFACTM  = 15'h0800;
  parameter XGMCTL_XGBRKIEM = 15'h0400;
  parameter XGMCTL_XGSWEIFM = 15'h0200;
  parameter XGMCTL_XGIEM    = 15'h0100;
  parameter XGMCTL_XGE      = 16'h0080;
  parameter XGMCTL_XGFRZ    = 16'h0040;
  parameter XGMCTL_XGDBG    = 15'h0020;
  parameter XGMCTL_XGSS     = 15'h0010;
  parameter XGMCTL_XGFACT   = 15'h0008;
  parameter XGMCTL_XGBRKIE  = 15'h0004;
  parameter XGMCTL_XGSWEIF  = 15'h0002;
  parameter XGMCTL_XGIE     = 15'h0001;

  parameter CHECK_POINT = 16'h8000;
  parameter CHANNEL_ACK = CHECK_POINT + 2;
  parameter CHANNEL_ERR = CHECK_POINT + 4;
  
  parameter SYS_RAM_BASE = 32'h0002_0000;

  //
  // wires && regs
  //
  reg         mstr_test_clk;
  reg  [19:0] vector;
  reg  [15:0] error_count;
  reg  [ 7:0] test_num;
  
  reg  [15:0] q, qq;
  reg  [ 7:0] check_point_reg;
  reg  [ 7:0] channel_ack_reg;
  reg  [ 7:0] channel_err_reg;
  event check_point_wrt;
  event channel_ack_wrt;
  event channel_err_wrt;

  reg         rstn;
  reg         sync_reset;
  reg         por_reset_b;
  reg         stop_mode;
  reg         wait_mode;
  reg         debug_mode;
  reg         scantestmode;

  reg         wbm_ack_i;

  wire [15:0] dat_i, dat1_i, dat2_i, dat3_i;
  wire        ack, ack_2, ack_3, ack_4;

  reg  [MAX_CHANNEL:0] channel_req;  // XGATE Interrupt inputs
  wire [MAX_CHANNEL:0] xgif;         // XGATE Interrupt outputs
  wire         [  7:0] xgswt;        // XGATE Software Trigger outputs
  wire                 xg_sw_irq;    // Xgate Software Error interrupt


  wire [15:0] wbm_dat_o;         // WISHBONE Master Mode data output from XGATE
  wire [15:0] wbm_dat_i;         // WISHBONE Master Mode data input to XGATE
  wire [15:0] wbm_adr_o;         // WISHBONE Master Mode address output from XGATE
  wire [ 1:0] wbm_sel_o;

  reg         mem_wait_state_enable;

  wire [15:0] tb_ram_out;
  wire [31:0] sys_addr;

  // Registers used to mirror internal registers
  reg  [15:0] data_xgmctl;
  reg  [15:0] data_xgchid;
  reg  [15:0] data_xgvbr;
  reg  [15:0] data_xgswt;
  reg  [15:0] data_xgsem;

  wire        sys_cyc;
  wire        sys_stb;
  wire        sys_we;
  wire [ 1:0] sys_sel;
  wire [31:0] sys_adr;
  wire [15:0] sys_dout;
  
  wire        host_ack;
  wire [15:0] host_dout;
  wire        host_cyc;
  wire        host_stb;
  wire        host_we;
  wire [ 1:0] host_sel;
  wire [31:0] host_adr;
  wire [15:0] host_din;
  
  wire        xgate_ack;
  wire [15:0] xgate_dout;
  wire        xgate_cyc;
  wire        xgate_stb;
  wire        xgate_we;
  wire [ 1:0] xgate_sel;
  wire [15:0] xgate_adr;
  wire [15:0] xgate_din;
  
  wire        xgate_s_stb;
  wire        xgate_s_ack;
  wire [15:0] xgate_s_dout;
  
  wire        slv2_stb;
  wire        ram_ack;
  wire [15:0] ram_dout;

  // initial values and testbench setup
  initial
    begin
      mstr_test_clk = 0;
      vector = 0;
      test_num = 0;
      por_reset_b = 0;
      stop_mode  = 0;
      wait_mode  = 0;
      debug_mode = 0;
      scantestmode = 0;
      check_point_reg = 0;
      channel_ack_reg = 0;
      channel_err_reg = 0;
      error_count = 0;
      wbm_ack_i = 1;
      mem_wait_state_enable = 0;
      // channel_req = 0;

      `ifdef WAVES
           $shm_open("waves");
           $shm_probe("AS",tst_bench_top,"AS");
           $display("\nINFO: Signal dump enabled ...\n\n");
      `endif

      `ifdef WAVES_V
           $dumpfile ("xgate_wave_dump.lxt");
           $dumpvars (0, tst_bench_top);
           $dumpon;
           $display("\nINFO: VCD Signal dump enabled ...\n\n");
      `endif

    end

  // generate clock
  always #20 mstr_test_clk = ~mstr_test_clk;

  // Keep a count of how many clocks we've simulated
  always @(posedge mstr_test_clk)
    begin
      vector <= vector + 1;
      if (vector > MAX_VECTOR)
        begin
          error_count <= error_count + 1;
          $display("\n ------ !!!!! Simulation Timeout at vector=%d\n -------", vector);
          wrap_up;
        end
    end

  // Add up errors tha come from WISHBONE read compares
  always @host.cmp_error_detect
    begin
      error_count <= error_count + 1;
    end


  // Throw in some wait states from the memory
  always @(posedge mstr_test_clk)
    if (((vector % 5) == 0) && (xgate.risc.load_next_inst || xgate.risc.data_access))
//    if ((vector % 5) == 0)
      wbm_ack_i <= 1'b0;
    else
      wbm_ack_i <= 1'b1;

  
  // Special Memory Mapped Testbench Registers
  always @(posedge mstr_test_clk or negedge rstn)
    begin
      if (!rstn)
        begin
          check_point_reg <= 0;
          channel_ack_reg <= 0;
          channel_err_reg <= 0;
        end
      if (wbm_sel_o[0] && wbm_ack_i && (wbm_adr_o == CHECK_POINT))
        begin
          check_point_reg <= wbm_dat_o[7:0];
          #1;
          -> check_point_wrt;
        end
      if (wbm_sel_o[0] && wbm_ack_i && (wbm_adr_o == CHANNEL_ACK))
        begin
          channel_ack_reg <= wbm_dat_o[7:0];
          #1;
          -> channel_ack_wrt;
        end
      if (wbm_sel_o[0] && wbm_ack_i && (wbm_adr_o == CHANNEL_ERR))
        begin
          channel_err_reg <= wbm_dat_o[7:0];
          #1;
          -> channel_err_wrt;
        end
    end

  always @check_point_wrt
    $display("\nSoftware Checkpoint #%h -- at vector=%d\n", check_point_reg, vector);

  always @channel_err_wrt
    begin
      $display("\n ------ !!!!! Software Error #%d -- at vector=%d\n  -------", channel_err_reg, vector);
      error_count = error_count + 1;
      if (STOP_ON_ERROR == 1'b1)
        wrap_up;
    end

  wire [ 6:0] current_active_channel = xgate.risc.xgchid;
  always @channel_ack_wrt
    clear_channel(current_active_channel);

  
  // Address decoding for different XGATE module instances
  wire stb0 = host_stb && ~host_adr[6] && ~host_adr[5] && ~|host_adr[31:16];
  wire stb1 = host_stb && ~host_adr[6] &&  host_adr[5] && ~|host_adr[31:16];
  wire stb2 = host_stb &&  host_adr[6] && ~host_adr[5] && ~|host_adr[31:16];
  wire stb3 = host_stb &&  host_adr[6] &&  host_adr[5] && ~|host_adr[31:16];
  
  assign dat1_i = 16'h0000;
  assign dat2_i = 16'h0000;
  assign dat3_i = 16'h0000;
  assign ack_2 = 1'b0;
  assign ack_3 = 1'b0;
  assign ack_4 = 1'b0;

  // Create the Read Data Bus
  assign dat_i = ({16{stb0}} & xgate_s_dout) |
                 ({16{stb1}} & dat1_i) |
                 ({16{stb2}} & dat2_i) |
                 ({16{stb3}} & {8'b0, dat3_i[7:0]});

  assign ack = xgate_s_ack || ack_2 || ack_3 || ack_4;

  // Aribartration Logic for Testbench RAM access
  assign sys_addr     = 1'b1 ? {16'b0, wbm_adr_o} : host_adr;
  

  // Testbench RAM for Xgate program storage and Load/Store instruction tests
  ram p_ram
  (
    // Outputs
    .ram_out( ram_dout ),
    // inputs
    .address( sys_addr[15:0] ),  // sys_addr  sys_adr
    .ram_in( sys_dout ),
    .we( sys_we ),
    .ce( 1'b1 ),
    .stb( mstr_test_clk ),
    .sel( sys_sel ) // wbm_sel_o sys_sel
  );

  // hookup wishbone master model
  wb_master_model #(.dwidth(16), .awidth(32))
    host(
    // Outputs
    .cyc( host_cyc ),
    .stb( host_stb ),
    .we( host_we ),
    .sel( host_sel ),
    .adr( host_adr ),
    .dout( host_dout ),
    // inputs
    .din(host_din),
    .clk(mstr_test_clk),
    .ack(host_ack),
    .rst(rstn),
    .err(1'b0),
    .rty(1'b0)
  );

  bus_arbitration  #(.dwidth(16),
                     .awidth(32))
    arb(
    // System bus I/O
    .sys_cyc( sys_cyc ),
    .sys_stb( sys_stb ),
    .sys_we( sys_we ),
    .sys_sel( sys_sel ),
    .sys_adr( sys_adr ),
    .sys_dout( sys_dout ),
    // Host bus I/O
    .host_ack( host_ack ),
    .host_dout( host_din ),
    .host_cyc( host_cyc ),
    .host_stb( host_stb ),
    .host_we( host_we ),
    .host_sel( host_sel ),
    .host_adr( host_adr ),
    .host_din( host_dout ),
    // Alternate Bus Master #1 Bus I/O
    .alt1_ack( xgate_ack ),
    .alt1_dout( xgate_din ),
    .alt1_cyc( wbm_cyc_o ),
    .alt1_stb( wbm_stb_o ),
    .alt1_we( wbm_we_o ),
    .alt1_sel( wbm_sel_o ),
    .alt1_adr( {16'h0001, wbm_adr_o} ),
    .alt1_din( wbm_dat_o ),
    // Slave #1 Bus I/O
    .slv1_stb( xgate_s_stb ),
    .slv1_ack( xgate_s_ack ),
    .slv1_din( xgate_s_dout ),
    // Slave #2 Bus I/O
    .slv2_stb( slv2_stb ),
    .slv2_ack( wbm_ack_i ),
    .slv2_din( ram_dout ),
    // Miscellaneous
    .host_clk( mstr_test_clk ),
    .risc_clk( mstr_test_clk ),
    .rst( rstn ),  // No Connect
    .err( 1'b0 ),  // No Connect
    .rty( 1'b0 )   // No Connect
  );
  // hookup XGATE core - Parameters take all default values
  //  Async Reset, 16 bit Bus, 8 bit Granularity
  xgate_top  #(.SINGLE_CYCLE(1'b1),
               .MAX_CHANNEL(MAX_CHANNEL))    // Max XGATE Interrupt Channel Number
          xgate(
          // Wishbone slave interface
          .wbs_clk_i( mstr_test_clk ),
          .wbs_rst_i( 1'b0 ),         // sync_reset
          .arst_i( rstn ),            // async resetn
          .wbs_adr_i( sys_adr[4:0] ),
          .wbs_dat_i( sys_dout ),
          .wbs_dat_o( xgate_s_dout ),
          .wbs_we_i( sys_we ),
          .wbs_stb_i( xgate_s_stb ),
          .wbs_cyc_i( sys_cyc ),
          .wbs_sel_i( sys_sel ),
          .wbs_ack_o( xgate_s_ack ),

          // Wishbone master Signals
          .wbm_dat_o( wbm_dat_o ),
          .wbm_we_o( wbm_we_o ),
          .wbm_stb_o( wbm_stb_o ),
          .wbm_cyc_o( wbm_cyc_o ),
          .wbm_sel_o( wbm_sel_o ),
          .wbm_adr_o( wbm_adr_o ),
          .wbm_dat_i( ram_dout ),
          .wbm_ack_i( wbm_ack_i ),

          .xgif( xgif ),             // XGATE Interrupt Flag output
          .xg_sw_irq( xg_sw_irq ),   // XGATE Software Error Interrupt Flag output
          .xgswt( xgswt ),
          .risc_clk( mstr_test_clk ),
          .chan_req_i( {channel_req[MAX_CHANNEL:40], xgswt, channel_req[31:0]} ),
          .scantestmode( scantestmode )
  );



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// Test Program
initial
  begin
    $display("\nstatus at time: %t Testbench started", $time);

    // reset system
    rstn = 1'b1; // negate reset
    channel_req = 1; //
    repeat(1) @(posedge mstr_test_clk);
    sync_reset = 1'b1;  // Make the sync reset 1 clock cycle long
    #2;          // move the async reset away from the clock edge
    rstn = 1'b0; // assert async reset
    #5;          // Keep the async reset pulse with less than a clock cycle
    rstn = 1'b1; // negate async reset
    por_reset_b = 1'b1;
    channel_req = 0; //
    repeat(1) @(posedge mstr_test_clk);
    sync_reset = 1'b0;
    channel_req = 0; //

    $display("\nstatus at time: %t done reset", $time);

    test_inst_set;

    test_debug_mode;

    test_debug_bit;

    test_chid_debug;

    // host_ram;
    // End testing
    wrap_up;

    reg_test_16;

    repeat(10) @(posedge mstr_test_clk);

    wrap_up;
  end

////////////////////////////////////////////////////////////////////////////////
// Test CHID Debug mode operation
task test_chid_debug;
  begin
    test_num = test_num + 1;
    $display("\nTEST #%d Starts at vector=%d, test_chid_debug", test_num, vector);
    $readmemh("../../../bench/verilog/debug_test.v", p_ram.ram_8);

    data_xgmctl = XGMCTL_XGBRKIEM | XGMCTL_XGBRKIE;
    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Enable interrupt on BRK instruction

    activate_thread_sw(3);

    wait_debug_set;   // Debug Status bit is set by BRK instruction

    host.wb_cmp(0, XGATE_XGPC,     16'h20c6, WORD);      // See Program code (BRK).
    host.wb_cmp(0, XGATE_XGR3,     16'h0001, WORD);      // See Program code.R3 = 1
    host.wb_cmp(0, XGATE_XGCHID,   16'h0003, WORD);      // Check for Correct CHID

    channel_req[5] = 1'b1; //
    repeat(7) @(posedge mstr_test_clk);
    host.wb_cmp(0, XGATE_XGCHID,   16'h0003, WORD);      // Check for Correct CHID

    host.wb_write(0, XGATE_XGCHID, 16'h000f, WORD);      // Change CHID
    host.wb_cmp(0, XGATE_XGCHID,   16'h000f, WORD);      // Check for Correct CHID

    host.wb_write(0, XGATE_XGCHID, 16'h0000, WORD);      // Change CHID to 00, RISC should go to IDLE state

    repeat(1) @(posedge mstr_test_clk);

    host.wb_write(0, XGATE_XGCHID, 16'h0004, WORD);      // Change CHID

    repeat(8) @(posedge mstr_test_clk);

    data_xgmctl = XGMCTL_XGDBGM;
    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Clear Debug Mode Control Bit

    wait_debug_set;   // Debug Status bit is set by BRK instruction
    host.wb_cmp(0, XGATE_XGCHID,   16'h0004, WORD);      // Check for Correct CHID
    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Clear Debug Mode Control Bit (Excape from Break State and run)

    wait_debug_set;   // Debug Status bit is set by BRK instruction
    host.wb_cmp(0, XGATE_XGCHID,   16'h0005, WORD);      // Check for Correct CHID
    activate_channel(6);
    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Clear Debug Mode Control Bit (Excape from Break State and run)

    wait_debug_set;   // Debug Status bit is set by BRK instruction
    host.wb_cmp(0, XGATE_XGCHID,   16'h0006, WORD);      // Check for Correct CHID
    host.wb_cmp(0, XGATE_XGPC,     16'h211c, WORD);      // See Program code (BRK)
    data_xgmctl = XGMCTL_XGSSM | XGMCTL_XGSS;
    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Do a Single Step
    repeat(8) @(posedge mstr_test_clk);
    host.wb_cmp(0, XGATE_XGPC,     16'h211e, WORD);      // See Program code (BRA)
    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Do a Single Step
    repeat(8) @(posedge mstr_test_clk);
    host.wb_cmp(0, XGATE_XGPC,     16'h2122, WORD);      // See Program code ()

    repeat(20) @(posedge mstr_test_clk);

    data_xgmctl = XGMCTL_XGDBGM;
    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Clear Debug Mode Control Bit

    repeat(50) @(posedge mstr_test_clk);

    p_ram.dump_ram(0);

  end
endtask

////////////////////////////////////////////////////////////////////////////////
// Test Debug bit operation
task test_debug_bit;
  begin
    test_num = test_num + 1;
    $display("\nTEST #%d Starts at vector=%d, test_debug_bit", test_num, vector);
    $readmemh("../../../bench/verilog/debug_test.v", p_ram.ram_8);

    data_xgmctl = XGMCTL_XGBRKIEM | XGMCTL_XGBRKIE;
    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Enable interrupt on BRK instruction

    activate_thread_sw(2);

    repeat(25) @(posedge mstr_test_clk);

    data_xgmctl = XGMCTL_XGDBGM | XGMCTL_XGDBG;
    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Set Debug Mode Control Bit
    repeat(5) @(posedge mstr_test_clk);

    host.wb_read(1, XGATE_XGR3, q, WORD);
    data_xgmctl = XGMCTL_XGSSM | XGMCTL_XGSS;
    qq = q;

    // The Xgate test program is in an infinate loop incrementing R3
    while (qq == q)  // Look for change in R3 register
      begin
        host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Do a Single Step
        repeat(5) @(posedge mstr_test_clk);
        host.wb_read(1, XGATE_XGR3, q, WORD);
      end
    if (q != (qq+1))
      begin
        $display("Error! - Unexpected value of R3 at vector=%d", vector);
        error_count = error_count + 1;
      end


    host.wb_write(1, XGATE_XGPC, 16'h2094, WORD);        // Write to PC to force exit from infinate loop
    repeat(5) @(posedge mstr_test_clk);

    data_xgmctl = XGMCTL_XGSSM | XGMCTL_XGSS;
    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Do a Single Step (Load ADDL instruction)
    repeat(5) @(posedge mstr_test_clk);
    host.wb_cmp(0, XGATE_XGR4,     16'h0002, WORD);      // See Program code.(R4 <= R4 + 1)

    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Do a Single Step (Load ADDL instruction)
    repeat(5) @(posedge mstr_test_clk);
    host.wb_cmp(0, XGATE_XGR4,     16'h0003, WORD);      // See Program code.(R4 <= R4 + 1)

    data_xgmctl = XGMCTL_XGDBGM;
    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Clear Debug Mode Control Bit
                                                 // Should be back in Run Mode

//    data_xgmctl = XGMCTL_XGSWEIFM | XGMCTL_XGSWEIF | XGMCTL_XGBRKIEM;
//    host.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Clear Software Interrupt and BRK Interrupt Enable Bit
    repeat(15) @(posedge mstr_test_clk);

  end
endtask

////////////////////////////////////////////////////////////////////////////////
// Test Debug mode operation
task test_debug_mode;
  begin
    test_num = test_num + 1;
    $display("\nTEST #%d Starts at vector=%d, test_debug_mode", test_num, vector);
    $readmemh("../../../bench/verilog/debug_test.v", p_ram.ram_8);

    data_xgmctl = XGMCTL_XGBRKIEM | XGMCTL_XGBRKIE;
    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Enable interrupt on BRK instruction

    activate_thread_sw(1);

    wait_debug_set;   // Debug Status bit is set by BRK instruction

    host.wb_cmp(0, XGATE_XGPC,     16'h203a, WORD);      // See Program code (BRK).
    host.wb_cmp(0, XGATE_XGR3,     16'h0001, WORD);      // See Program code.R3 = 1

    data_xgmctl = XGMCTL_XGSSM | XGMCTL_XGSS;

    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Do a Single Step (Load ADDL instruction)
    repeat(5) @(posedge mstr_test_clk);
    host.wb_cmp(0, XGATE_XGPC,     16'h203c, WORD);      // PC + 2.

    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Do a Single Step (Load NOP instruction)
    repeat(5) @(posedge mstr_test_clk);                  // Execute ADDL instruction
    host.wb_cmp(0, XGATE_XGR3,     16'h0002, WORD);      // See Program code.(R3 <= R3 + 1)
    host.wb_cmp(0, XGATE_XGCCR,    16'h0000, WORD);      // See Program code.
    host.wb_cmp(0, XGATE_XGPC,     16'h203e, WORD);      // PC + 2.
    repeat(5) @(posedge mstr_test_clk);
    host.wb_cmp(0, XGATE_XGPC,     16'h203e, WORD);      // Still no change.

    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Do a Single Step (Load BRA instruction)
    repeat(9) @(posedge mstr_test_clk);                  // Execute NOP instruction
    host.wb_cmp(0, XGATE_XGPC,     16'h2040, WORD);      // See Program code.


    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Do a Single Step
    repeat(5) @(posedge mstr_test_clk);                  // Execute BRA instruction
    host.wb_cmp(0, XGATE_XGPC,     16'h2064, WORD);      // PC = Branch destination.
                                                         // Load ADDL instruction

    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Do a Single Step (Load LDW R7 instruction)
    repeat(5) @(posedge mstr_test_clk);                  // Execute ADDL instruction
    host.wb_cmp(0, XGATE_XGPC,     16'h2066, WORD);      // PC + 2.
    host.wb_cmp(0, XGATE_XGR3,     16'h0003, WORD);      // See Program code.(R3 <= R3 + 1)

    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Do a Single Step (LDW R7)
    repeat(5) @(posedge mstr_test_clk);
    host.wb_cmp(0, XGATE_XGPC,     16'h2068, WORD);      // PC + 2.
    host.wb_cmp(0, XGATE_XGR7,     16'h00c3, WORD);      // See Program code

    repeat(1) @(posedge mstr_test_clk);
    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Do a Single Step (BRA)
    repeat(9) @(posedge mstr_test_clk);
    host.wb_cmp(0, XGATE_XGPC,     16'h2048, WORD);      // See Program code.

    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Do a Single Step (STW R3)
    repeat(5) @(posedge mstr_test_clk);
    host.wb_cmp(0, XGATE_XGPC,     16'h204a, WORD);      // PC + 2.
    host.wb_cmp(0, XGATE_XGR3,     16'h0003, WORD);      // See Program code.(R3 <= R3 + 1)

    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Do a Single Step (R3 <= R3 + 1)
    repeat(5) @(posedge mstr_test_clk);
    host.wb_cmp(0, XGATE_XGPC,     16'h204c, WORD);      // PC + 2.

    repeat(5) @(posedge mstr_test_clk);

    data_xgmctl = XGMCTL_XGDBGM;
    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Clear Debug Mode Control Bit
                                                         // Should be back in Run Mode
    wait_irq_set(1);
    host.wb_write(1, XGATE_XGIF_0, 16'h0002, WORD);

    data_xgmctl = XGMCTL_XGSWEIFM | XGMCTL_XGSWEIF | XGMCTL_XGBRKIEM;
    host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Clear Software Interrupt and BRK Interrupt Enable Bit
    repeat(15) @(posedge mstr_test_clk);

  end
endtask

////////////////////////////////////////////////////////////////////////////////
// Test instruction set
task test_inst_set;
  begin
    $readmemh("../../../bench/verilog/inst_test.v", p_ram.ram_8);
    test_num = test_num + 1;
    $display("\nTEST #%d Starts at vector=%d, inst_test", test_num, vector);
    repeat(1) @(posedge mstr_test_clk);

    activate_thread_sw(1);
    wait_irq_set(1);
    host.wb_write(1, XGATE_XGIF_0, 16'h0002, WORD);

    activate_thread_sw(2);
    wait_irq_set(2);
    host.wb_write(1, XGATE_XGIF_0, 16'h0004, WORD);

    activate_thread_sw(3);
    wait_irq_set(3);
    host.wb_write(1, XGATE_XGIF_0, 16'h0008, WORD);

    activate_thread_sw(4);
    wait_irq_set(4);
    host.wb_write(1, XGATE_XGIF_0, 16'h0010, WORD);

    activate_thread_sw(5);
    wait_irq_set(5);
    host.wb_write(1, XGATE_XGIF_0, 16'h0020, WORD);

    activate_thread_sw(6);
    wait_irq_set(6);
    host.wb_write(1, XGATE_XGIF_0, 16'h0040, WORD);

    activate_thread_sw(7);
    wait_irq_set(7);
    host.wb_write(1, XGATE_XGIF_0, 16'h0080, WORD);

    activate_thread_sw(8);
    wait_irq_set(8);
    host.wb_write(1, XGATE_XGIF_0, 16'h0100, WORD);

    activate_thread_sw(9);
    wait_irq_set(9);
    host.wb_write(1, XGATE_XGIF_0, 16'h0200, WORD);

    host.wb_write(1, XGATE_XGSEM, 16'h5050, WORD);
    host.wb_cmp(0, XGATE_XGSEM,    16'h0050, WORD);   //
    activate_thread_sw(10);
    wait_irq_set(10);
    host.wb_write(1, XGATE_XGIF_0, 16'h0400, WORD);

    host.wb_write(1, XGATE_XGSEM, 16'hff00, WORD);    // clear the old settings
    host.wb_cmp(0, XGATE_XGSEM,    16'h0000, WORD);   //
    host.wb_write(1, XGATE_XGSEM, 16'ha0a0, WORD);    // Verify that bits were unlocked by RISC
    host.wb_cmp(0, XGATE_XGSEM,    16'h00a0, WORD);   // Verify bits were set
    host.wb_write(1, XGATE_XGSEM, 16'hff08, WORD);    // Try to set the bit that was left locked by the RISC
    host.wb_cmp(0, XGATE_XGSEM,    16'h0000, WORD);   // Verify no bits were set

    repeat(20) @(posedge mstr_test_clk);

    p_ram.dump_ram(0);

  end
endtask

////////////////////////////////////////////////////////////////////////////////
// check register bits - reset, read/write
task reg_test_16;
  begin
      test_num = test_num + 1;
      $display("TEST #%d Starts at vector=%d, reg_test_16", test_num, vector);
      host.wb_cmp(0, XGATE_XGMCTL,   16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGCHID,   16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGISPHI,  16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGISPLO,  16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGVBR,    16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGIF_7,   16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGIF_6,   16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGIF_5,   16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGIF_4,   16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGIF_3,   16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGIF_2,   16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGIF_1,   16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGIF_0,   16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGSWT,    16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGSEM,    16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGCCR,    16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGPC,     16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGR1,     16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGR2,     16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGR3,     16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGR4,     16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGR5,     16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGR6,     16'h0000, WORD);   // verify reset
      host.wb_cmp(0, XGATE_XGR7,     16'h0000, WORD);   // verify reset

      host.wb_write(1, XGATE_XGR1, 16'h5555, WORD);
      host.wb_cmp(  0, XGATE_XGR1, 16'h5555, WORD);
      host.wb_write(1, XGATE_XGR2, 16'haaaa, WORD);
      host.wb_cmp(  0, XGATE_XGR2, 16'haaaa, WORD);
      host.wb_write(1, XGATE_XGR3, 16'h9999, WORD);
      host.wb_cmp(  0, XGATE_XGR3, 16'h9999, WORD);
      host.wb_write(1, XGATE_XGR4, 16'hcccc, WORD);
      host.wb_cmp(  0, XGATE_XGR4, 16'hcccc, WORD);
      host.wb_write(1, XGATE_XGR5, 16'h3333, WORD);
      host.wb_cmp(  0, XGATE_XGR5, 16'h3333, WORD);
      host.wb_write(1, XGATE_XGR6, 16'h6666, WORD);
      host.wb_cmp(  0, XGATE_XGR6, 16'h6666, WORD);
      host.wb_write(1, XGATE_XGR7, 16'ha5a5, WORD);
      host.wb_cmp(  0, XGATE_XGR7, 16'ha5a5, WORD);

      host.wb_write(1, XGATE_XGPC, 16'h5a5a, WORD);
      host.wb_cmp(  0, XGATE_XGPC, 16'h5a5a, WORD);

      host.wb_write(1, XGATE_XGCCR, 16'hfffa, WORD);
      host.wb_cmp(  0, XGATE_XGCCR, 16'h000a, WORD);
      host.wb_write(1, XGATE_XGCCR, 16'hfff5, WORD);
      host.wb_cmp(  0, XGATE_XGCCR, 16'h0005, WORD);

  end
endtask


////////////////////////////////////////////////////////////////////////////////
// check RAM Read/Write from host
task host_ram;
  begin
    test_num = test_num + 1;
    $display("TEST #%d Starts at vector=%d, host_ram", test_num, vector);

    host.wb_write(1, SYS_RAM_BASE, 16'h5555, WORD);
    host.wb_cmp(  0, SYS_RAM_BASE, 16'h5555, WORD);

    repeat(5) @(posedge mstr_test_clk);
    p_ram.dump_ram(0);

  end
endtask

////////////////////////////////////////////////////////////////////////////////
// Poll for XGATE Interrupt set
task wait_irq_set;
  input [ 6:0] chan_val;
  begin
    while(!xgif[chan_val])
      @(posedge mstr_test_clk); // poll it until it is set
    $display("XGATE Interrupt Request #%d set detected at vector =%d", chan_val, vector);
  end
endtask

////////////////////////////////////////////////////////////////////////////////
// Poll for debug bit set
task wait_debug_set;
  begin
    host.wb_read(1, XGATE_XGMCTL, q, WORD);
    while(~|(q & XGMCTL_XGDBG))
      host.wb_read(1, XGATE_XGMCTL, q, WORD); // poll it until it is set
    $display("DEBUG Flag set detected at vector =%d", vector);
  end
endtask


////////////////////////////////////////////////////////////////////////////////
task system_reset;  // reset system
  begin
      repeat(1) @(posedge mstr_test_clk);
      sync_reset = 1'b1;  // Make the sync reset 1 clock cycle long
      #2;                 // move the async reset away from the clock edge
      rstn = 1'b0;        // assert async reset
      #5;                 // Keep the async reset pulse with less than a clock cycle
      rstn = 1'b1;        // negate async reset
      repeat(1) @(posedge mstr_test_clk);
      sync_reset = 1'b0;

      $display("\nstatus: %t System Reset Task Done", $time);
      test_num = test_num + 1;

      repeat(2) @(posedge mstr_test_clk);
   end
endtask


////////////////////////////////////////////////////////////////////////////////
task activate_channel;
  input [ 6:0] chan_val;
  begin
    $display("Activating Channel %d", chan_val);

    channel_req[chan_val] = 1'b1; //
    repeat(1) @(posedge mstr_test_clk);
  end
endtask


////////////////////////////////////////////////////////////////////////////////
task clear_channel;
  input [ 6:0] chan_val;
  begin
    $display("Clearing Channel interrupt input #%d", chan_val);

    channel_req[chan_val] = 1'b0; //
    repeat(1) @(posedge mstr_test_clk);
  end
endtask


////////////////////////////////////////////////////////////////////////////////
task clear_irq_flag;
  input [ 6:0] chan_val;
  begin
      $display("Clearing Channel interrupt flag #%d", chan_val);
      if (0 < chan_val < 16)
        host.wb_write(1, XGATE_XGIF_0, 16'hffff, WORD);
      if (15 < chan_val < 32)
        host.wb_write(1, XGATE_XGIF_1, 16'hffff, WORD);
      if (31 < chan_val < 48)
        host.wb_write(1, XGATE_XGIF_2, 16'hffff, WORD);
      if (47 < chan_val < 64)
        host.wb_write(1, XGATE_XGIF_3, 16'hffff, WORD);
      if (63 < chan_val < 80)
        host.wb_write(1, XGATE_XGIF_4, 16'hffff, WORD);
      if (79 < chan_val < 96)
        host.wb_write(1, XGATE_XGIF_5, 16'hffff, WORD);
      if (95 < chan_val < 112)
        host.wb_write(1, XGATE_XGIF_6, 16'hffff, WORD);
      if (111 < chan_val < 128)
        host.wb_write(1, XGATE_XGIF_7, 16'hffff, WORD);

      channel_req[chan_val] = 1'b0; //
      repeat(1) @(posedge mstr_test_clk);
   end
endtask


////////////////////////////////////////////////////////////////////////////////
task activate_thread_sw;
  input [ 6:0] chan_val;
  begin
      $display("Activating Sofrware Thread - Channel #%d", chan_val);

      data_xgmctl = XGMCTL_XGEM | XGMCTL_XGE;
      host.wb_write(0, XGATE_XGMCTL, data_xgmctl, WORD);   // Enable XGATE

      channel_req[chan_val] = 1'b1; //
      repeat(1) @(posedge mstr_test_clk);
   end
endtask

////////////////////////////////////////////////////////////////////////////////
task wrap_up;
  begin
    test_num = test_num + 1;
    repeat(10) @(posedge mstr_test_clk);
    $display("\nSimulation Finished!! - vector =%d", vector);
    if (error_count == 0)
      $display("Simulation Passed");
    else
      $display("Simulation Failed  --- Errors =%d", error_count);

    $finish;
  end
endtask

////////////////////////////////////////////////////////////////////////////////
function [15:0] four_2_16;
  input [3:0] vector;
  begin
    case (vector)
      4'h0 : four_2_16 = 16'b0000_0000_0000_0001;
      4'h1 : four_2_16 = 16'b0000_0000_0000_0010;
      4'h2 : four_2_16 = 16'b0000_0000_0000_0100;
      4'h3 : four_2_16 = 16'b0000_0000_0000_1000;
      4'h4 : four_2_16 = 16'b0000_0000_0001_0000;
      4'h5 : four_2_16 = 16'b0000_0000_0010_0000;
      4'h6 : four_2_16 = 16'b0000_0000_0100_0000;
      4'h7 : four_2_16 = 16'b0000_0000_1000_0000;
      4'h8 : four_2_16 = 16'b0000_0001_0000_0000;
      4'h9 : four_2_16 = 16'b0000_0010_0000_0000;
      4'ha : four_2_16 = 16'b0000_0100_0000_0000;
      4'hb : four_2_16 = 16'b0000_1000_0000_0000;
      4'hc : four_2_16 = 16'b0001_0000_0000_0000;
      4'hd : four_2_16 = 16'b0010_0000_0000_0000;
      4'he : four_2_16 = 16'b0100_0000_0000_0000;
      4'hf : four_2_16 = 16'b1000_0000_0000_0000;
    endcase
  end
endfunction

endmodule  // tst_bench_top

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module bus_arbitration  #(parameter dwidth = 32,
                          parameter awidth = 32)
  (
  // System bus I/O
  output                     sys_cyc,
  output                     sys_stb,
  output                     sys_we,
  output     [dwidth/8 -1:0] sys_sel,
  output     [awidth   -1:0] sys_adr,
  output     [dwidth   -1:0] sys_dout,
  
  // Host bus I/O
  output                     host_ack,
  output     [dwidth   -1:0] host_dout,
  input                      host_cyc,
  input                      host_stb,
  input                      host_we,
  input      [dwidth/8 -1:0] host_sel,
  input      [awidth   -1:0] host_adr,
  input      [dwidth   -1:0] host_din,
  
  // Alternate Bus Master #1 Bus I/O
  output                     alt1_ack,
  output     [dwidth   -1:0] alt1_dout,
  input                      alt1_cyc,
  input                      alt1_stb,
  input                      alt1_we,
  input      [dwidth/8 -1:0] alt1_sel,
  input      [awidth   -1:0] alt1_adr,
  input      [dwidth   -1:0] alt1_din,
  
  // Slave #1 Bus I/O
  output                     slv1_stb,
  input                      slv1_ack,
  input      [dwidth   -1:0] slv1_din,
  
  // Slave #2 Bus I/O
  output                     slv2_stb,
  input                      slv2_ack,
  input      [dwidth   -1:0] slv2_din,
  
  // Miscellaneous
  input                      host_clk,
  input                      risc_clk,
  input                      rst,  // No Connect
  input                      err,  // No Connect
  input                      rty   // No Connect
  );
  
  //////////////////////////////////////////////////////////////////////////////
  //
  // Local Wires and Registers
  //
  wire       host_lock;      // Host has the slave bus
  reg        host_lock_ext;  // Host lock extend, Hold the bus till the transaction complets
  reg  [3:0] host_cycle_cnt; // Used to count the cycle the host and break the lock if the risc needs access
  
  wire       risc_lock;      // RISC has the slave bus
  reg        risc_lock_ext;  // RISC lock extend, Hold the bus till the transaction complets
  reg  [3:0] risc_cycle_cnt; // Used to count the cycle the risc and break the lock if the host needs access

  // Aribartration Logic for System Bus access
  always @(posedge host_clk or negedge rst)
    if (!rst)
      host_lock_ext <= 1'b0;
    else
      host_lock_ext <= host_cyc && !host_ack;

  always @(posedge host_clk or negedge rst)
    if (!rst)
      risc_lock_ext <= 1'b0;
    else
      risc_lock_ext <= alt1_cyc && !alt1_ack;

      // Start counting cycles the host has the bus if the risc is also requesting the bus
  always @(posedge host_clk or negedge rst)
    if (!rst)
      host_cycle_cnt <= 0;
    else
      host_cycle_cnt <= (host_lock && alt1_cyc) ? (host_cycle_cnt + 1'b1) : 0;

  // Start counting cycles the risc has the bus if the host is also requesting the bus
  always @(posedge host_clk or negedge rst)
    if (!rst)
      risc_cycle_cnt <= 0;
    else
      risc_cycle_cnt <= (risc_lock && host_cyc) ? (risc_cycle_cnt + 1'b1) : 0;

  assign host_lock = ((host_cyc && !risc_lock_ext) || host_lock_ext) && (host_cycle_cnt < 5);
  assign risc_lock = !host_lock;
  
  wire alt1_master = !host_lock;

  // Address decoding for different XGATE module instances
  assign slv1_stb = sys_stb && ~sys_adr[6] && ~sys_adr[5] && ~|sys_adr[31:16];
  wire slv3_stb = sys_stb && ~sys_adr[6] &&  sys_adr[5] && ~|sys_adr[31:16];
  wire slv4_stb = sys_stb &&  sys_adr[6] && ~sys_adr[5] && ~|sys_adr[31:16];
  wire slv5_stb = sys_stb &&  sys_adr[6] &&  sys_adr[5] && ~|sys_adr[31:16];
  
  // Address decoding for Testbench access to RAM
  assign slv2_stb = alt1_master ? (alt1_stb && sys_adr[16] && ~|sys_adr[31:17]) :
                                  (host_stb && ~sys_adr[16] && sys_adr[17] && ~|sys_adr[31:18]);


  // Create the Host Read Data Bus
  assign host_dout = ({dwidth{slv1_stb}} & slv1_din) |
                     ({dwidth{slv2_stb}} & slv2_din);

  // Create the Alternate #1 Read Data Bus
  assign alt1_dout = ({dwidth{slv1_stb}} & slv1_din) |
                     ({dwidth{slv2_stb}} & slv2_din);

  assign host_ack = host_lock && (slv1_ack || slv2_ack);
  assign alt1_ack = risc_lock && (slv1_ack || slv2_ack);


  // Mux for System Bus access
  assign sys_cyc   = alt1_cyc || host_cyc;
  assign sys_stb   = alt1_master ? alt1_stb  : host_stb;
  assign sys_we    = alt1_master ? alt1_we   : host_we;
  assign sys_sel   = alt1_master ? alt1_sel  : host_sel;
  assign sys_adr   = alt1_master ? alt1_adr  : host_adr;
  assign sys_dout  = alt1_master ? alt1_din  : host_din;

endmodule   // bus_arbitration



