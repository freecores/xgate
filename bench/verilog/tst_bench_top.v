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
  parameter MAX_VECTOR = 1800;
  
  //
  // wires && regs
  //
  reg        mstr_test_clk;
  reg [19:0] vector;
  reg [ 7:0] test_num;
  reg [15:0] wb_temp;
  reg        rstn;
  reg        sync_reset;
  reg        por_reset_b;
  reg        stop_mode;
  reg        wait_mode;
  reg        debug_mode;
  reg        scantestmode;
  
  reg       wbm_ack_i;


  wire [31:0] adr;
  wire [15:0] dat_i, dat_o, dat0_i, dat1_i, dat2_i, dat3_i;
  wire we;
  wire stb;
  wire cyc;
  wire ack, ack_1, ack_2, ack_3, ack_4;
  wire inta_1, inta_2, inta_3, inta_4;
  wire count_en_1;
  wire count_flag_1;

  reg [15:0] q, qq;
  
  reg  [  7:0] ram_8 [65535:0];
  wire         write_mem_strb_l;
  wire         write_mem_strb_h;
  reg  [127:0] channel_req;
  wire [  7:0] xgswt;        // XGATE Software Triggers
  wire [MAX_CHANNEL:0] xgif; // Max XGATE Interrupt Channel Number
  wire         xg_sw_irq;    // Xgate Software interrupt


  wire [15:0] xgate_address;
  wire [15:0] write_mem_data;
  wire [15:0] read_mem_data;
  
  wire [15:0] wbm_dat_o;
  wire [15:0] wbm_dat_i;
  wire [15:0] wbm_adr_o;
  wire [ 1:0] wbm_sel_o;


  // Name Address Locations
  parameter XGATE_XGMCTL   = 5'h00;
  parameter XGATE_XGCHID   = 5'h01;
  parameter XGATE_XGISPHI  = 5'h02;
  parameter XGATE_XGISPLO  = 5'h03;
  parameter XGATE_XGVBR    = 5'h04;
  parameter XGATE_XGIF_7   = 5'h05;
  parameter XGATE_XGIF_6   = 5'h06;
  parameter XGATE_XGIF_5   = 5'h07;
  parameter XGATE_XGIF_4   = 5'h08;
  parameter XGATE_XGIF_3   = 5'h09;
  parameter XGATE_XGIF_2   = 5'h0a;
  parameter XGATE_XGIF_1   = 5'h0b;
  parameter XGATE_XGIF_0   = 5'h0c;
  parameter XGATE_XGSWT    = 5'h0d;
  parameter XGATE_XGSEM    = 5'h0e;
  parameter XGATE_RES1     = 5'h0f;
  parameter XGATE_XGCCR    = 5'h10;
  parameter XGATE_XGPC     = 5'h11;
  parameter XGATE_RES1     = 5'h12;
  parameter XGATE_XGR1     = 5'h13;
  parameter XGATE_XGR2     = 5'h14;
  parameter XGATE_XGR3     = 5'h15;
  parameter XGATE_XGR4     = 5'h16;
  parameter XGATE_XGR5     = 5'h17;
  parameter XGATE_XGR6     = 5'h18;
  parameter XGATE_XGR7     = 5'h19;
  
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
  
  parameter COP_CNTRL = 5'b0_0000;

  parameter COP_CNTRL_COP_EVENT  = 16'h0100;  // COP Enable interrupt request

  parameter CHECK_POINT = 16'h8000;
  parameter CHANNEL_ACK = CHECK_POINT + 2;
  parameter CHANNEL_ERR = CHECK_POINT + 4;
  reg [ 7:0] check_point_reg;
  reg [ 7:0] channel_ack_reg;
  reg [ 7:0] channel_err_reg;
  event check_point_wrt;
  event channel_ack_wrt;
  event channel_err_wrt;
  reg [15:0] error_count;
  
  reg        mem_wait_state_enable;
  
  // Registers used to mirror internal registers
  reg [15:0] data_xgmctl;
  reg [15:0] data_xgchid;
  reg [15:0] data_xgvbr;
  reg [15:0] data_xgswt;
  reg [15:0] data_xgsem;

  // initial values and testbench setup
  initial
    begin
      mstr_test_clk = 0;
      vector = 0;
      test_num = 0;
      por_reset_b = 0;
      stop_mode = 0;
      wait_mode = 0;
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
	  error_count = error_count + 1;
	  $display("\n ------ !!!!! Simulation Timeout at vector=%d\n -------", vector);
	  wrap_up;
	end
    end


  // Throw in some wait states from the memory
  always @(posedge mstr_test_clk)
    if (((vector % 5) == 0) && (xgate.risc.load_next_inst || xgate.risc.data_access))
//    if ((vector % 5) == 0)
      wbm_ack_i <= 1'b0;
    else 
      wbm_ack_i <= 1'b1;


  // Write memory interface to RAM
  always @(posedge mstr_test_clk)
    begin
      if (write_mem_strb_l && !write_mem_strb_h && wbm_ack_i)
	ram_8[xgate_address] <= write_mem_data[7:0];
      if (write_mem_strb_h && !write_mem_strb_l && wbm_ack_i)
	ram_8[xgate_address] <= write_mem_data[7:0];
      if (write_mem_strb_h && write_mem_strb_l && wbm_ack_i)
	begin
	  ram_8[xgate_address]   <= write_mem_data[15:8];
	  ram_8[xgate_address+1] <= write_mem_data[7:0];
	end
    end

  // Special Memory Mapped Testbench Registers
  always @(posedge mstr_test_clk or negedge rstn)
    begin
      if (!rstn)
	begin
	  check_point_reg <= 0;
	  channel_ack_reg <= 0;
	  channel_err_reg <= 0;
	end
      if (write_mem_strb_l && wbm_ack_i && (xgate_address == CHECK_POINT))
	begin
	  check_point_reg <= write_mem_data[7:0];
	  #1;
	  -> check_point_wrt;
	end
      if (write_mem_strb_l && wbm_ack_i && (xgate_address == CHANNEL_ACK))
	begin
	  channel_ack_reg <= write_mem_data[7:0];
	  #1;
	  -> channel_ack_wrt;
	end
      if (write_mem_strb_l && wbm_ack_i && (xgate_address == CHANNEL_ERR))
	begin
	  channel_err_reg <= write_mem_data[7:0];
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
      
      
  // hookup wishbone master model
  wb_master_model #(.dwidth(16), .awidth(32))
          u0 (
          .clk(mstr_test_clk),
          .rst(rstn),
          .adr(adr),
          .din(dat_i),
          .dout(dat_o),
          .cyc(cyc),
          .stb(stb),
          .we(we),
          .sel(),
          .ack(ack),
          .err(1'b0),
          .rty(1'b0)
  );


  // Address decoding for different XGATE module instances
  wire stb0 = stb && ~adr[6] && ~adr[5];
  wire stb1 = stb && ~adr[6] &&  adr[5];
  wire stb2 = stb &&  adr[6] && ~adr[5];
  wire stb3 = stb &&  adr[6] &&  adr[5];

  assign dat1_i = 16'h0000;
  assign dat2_i = 16'h0000;
  assign dat3_i = 16'h0000;
  assign ack_2 = 1'b0;
  assign ack_3 = 1'b0;
  assign ack_4 = 1'b0;

  // Create the Read Data Bus
  assign dat_i = ({16{stb0}} & dat0_i) |
                 ({16{stb1}} & dat1_i) |
                 ({16{stb2}} & dat2_i) |
                 ({16{stb3}} & {8'b0, dat3_i[7:0]});
		 
  assign ack = ack_1 || ack_2 || ack_3 || ack_4;
  
  assign read_mem_data = {ram_8[xgate_address], ram_8[xgate_address+1]};

  // hookup XGATE core - Parameters take all default values
  //  Async Reset, 16 bit Bus, 16 bit Granularity
  xgate_top  #(.SINGLE_CYCLE(1'b1),
	       .MAX_CHANNEL(MAX_CHANNEL))    // Max XGATE Interrupt Channel Number
          xgate(
          // Wishbone slave interface
          .wbs_clk_i( mstr_test_clk ),
          .wbs_rst_i( 1'b0 ),         // sync_reset
          .arst_i( rstn ),            // async resetn
          .wbs_adr_i( adr[4:0] ),
          .wbs_dat_i( dat_o ),
          .wbs_dat_o( dat0_i ),
          .wbs_we_i( we ),
          .wbs_stb_i( stb0 ),
          .wbs_cyc_i( cyc ),
          .wbs_sel_i( 2'b11 ),
          .wbs_ack_o( ack_1 ),

          // Wishbone master Signals
          .wbm_dat_o( write_mem_data ),
          .wbm_we_o( wbm_we_o ),
          .wbm_stb_o( wbm_stb_o ),
          .wbm_cyc_o( wbm_cyc_o ),
          .wbm_sel_o( wbm_sel_o ),
          .wbm_adr_o( xgate_address ),
          .wbm_dat_i( read_mem_data ),
          .wbm_ack_i( wbm_ack_i ),

          .xgif( xgif ),             // XGATE Interrupt Flag
          .xg_sw_irq( xg_sw_irq ),
          .risc_clk( mstr_test_clk ),
          .xgswt( xgswt ),
	  .chan_req_i( {channel_req[127:40], xgswt, channel_req[31:0]} ),
	  .write_mem_strb_l( write_mem_strb_l ),
	  .write_mem_strb_h( write_mem_strb_h ),
          .scantestmode( scantestmode )
  );



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// Test Program
initial
  begin
      $readmemh("../../../bench/verilog/inst_test.v", ram_8);
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

//      test_debug_bit; 
      
      wrap_up;
      //
      // program core
      //

      reg_test_16;
      
      repeat(10) @(posedge mstr_test_clk);

      wrap_up;
  end

// Test Debug bit operation
task test_debug_bit;
  begin
    test_num = test_num + 1;
    $display("\nTEST #%d Starts at vector=%d, test_debug_mode", test_num, vector);
    $readmemh("../../../bench/verilog/debug_test.v", ram_8);
    
    data_xgmctl = XGMCTL_XGBRKIEM | XGMCTL_XGBRKIE;
    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Enable interrupt on BRK instruction

    activate_thread_sw(2);
    
    repeat(25) @(posedge mstr_test_clk);

    data_xgmctl = XGMCTL_XGDBGM | XGMCTL_XGDBG;
    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Set Debug Mode Control Bit
//    data_xgmctl = XGMCTL_XGDBGM;
//    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Clear Debug Mode Control Bit
                                                 // Should be back in Run Mode
    wait_irq_set(1);
    u0.wb_write(1, XGATE_XGIF_0, 16'h0004);
    
    data_xgmctl = XGMCTL_XGSWEIFM | XGMCTL_XGSWEIF | XGMCTL_XGBRKIEM;
    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Clear Software Interrupt and BRK Interrupt Enable Bit
    repeat(15) @(posedge mstr_test_clk);
    
  end
endtask

// Test Debug mode operation
task test_debug_mode;
  begin
    test_num = test_num + 1;
    $display("\nTEST #%d Starts at vector=%d, test_debug_mode", test_num, vector);
    $readmemh("../../../bench/verilog/debug_test.v", ram_8);
    
    data_xgmctl = XGMCTL_XGBRKIEM | XGMCTL_XGBRKIE;
    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Enable interrupt on BRK instruction

    activate_thread_sw(1);
    
    wait_debug_set;   // Debug Status bit is set by BRK instruction

    u0.wb_cmp(0, XGATE_XGPC,     16'h203a);      // See Program code (BRK).
    u0.wb_cmp(0, XGATE_XGR3,     16'h0001);      // See Program code.R3 = 1

    data_xgmctl = XGMCTL_XGSSM | XGMCTL_XGSS;

    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Do a Single Step (Load ADDL instruction)
    repeat(5) @(posedge mstr_test_clk);
    u0.wb_cmp(0, XGATE_XGPC,     16'h203c);      // PC + 2.

    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Do a Single Step (Load NOP instruction)
    repeat(5) @(posedge mstr_test_clk);          // Execute ADDL instruction
    u0.wb_cmp(0, XGATE_XGR3,     16'h0002);      // See Program code.(R3 <= R3 + 1)
    u0.wb_cmp(0, XGATE_XGCCR,    16'h0000);      // See Program code.
    u0.wb_cmp(0, XGATE_XGPC,     16'h203e);      // PC + 2.
    repeat(5) @(posedge mstr_test_clk);
    u0.wb_cmp(0, XGATE_XGPC,     16'h203e);      // Still no change.

    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Do a Single Step (Load BRA instruction)
    repeat(9) @(posedge mstr_test_clk);          // Execute NOP instruction
    u0.wb_cmp(0, XGATE_XGPC,     16'h2040);      // See Program code.


    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Do a Single Step
    repeat(5) @(posedge mstr_test_clk);          // Execute BRA instruction
    u0.wb_cmp(0, XGATE_XGPC,     16'h2064);      // PC = Branch destination.
                                                 // Load ADDL instruction
    
    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Do a Single Step (Load LDW R7 instruction)
    repeat(5) @(posedge mstr_test_clk);          // Execute ADDL instruction
    u0.wb_cmp(0, XGATE_XGPC,     16'h2066);      // PC + 2.
    u0.wb_cmp(0, XGATE_XGR3,     16'h0003);      // See Program code.(R3 <= R3 + 1)

    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Do a Single Step (LDW R7)
    repeat(5) @(posedge mstr_test_clk);
    u0.wb_cmp(0, XGATE_XGPC,     16'h2068);      // PC + 2.
    u0.wb_cmp(0, XGATE_XGR7,     16'h00c3);      // See Program code

    repeat(1) @(posedge mstr_test_clk);
    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Do a Single Step (BRA)
    repeat(9) @(posedge mstr_test_clk);
    u0.wb_cmp(0, XGATE_XGPC,     16'h2048);      // See Program code.

    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Do a Single Step (STW R3)
    repeat(5) @(posedge mstr_test_clk);
    u0.wb_cmp(0, XGATE_XGPC,     16'h204a);      // PC + 2.
    u0.wb_cmp(0, XGATE_XGR3,     16'h0003);      // See Program code.(R3 <= R3 + 1)

    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Do a Single Step (R3 <= R3 + 1)
    repeat(5) @(posedge mstr_test_clk);
    u0.wb_cmp(0, XGATE_XGPC,     16'h204c);      // PC + 2.

    repeat(5) @(posedge mstr_test_clk);

    data_xgmctl = XGMCTL_XGDBGM | XGMCTL_XGDBG;
    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Set Debug Mode Control Bit
    data_xgmctl = XGMCTL_XGDBGM;
    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Clear Debug Mode Control Bit
                                                 // Should be back in Run Mode
    wait_irq_set(1);
    u0.wb_write(1, XGATE_XGIF_0, 16'h0002);
    
    data_xgmctl = XGMCTL_XGSWEIFM | XGMCTL_XGSWEIF | XGMCTL_XGBRKIEM;
    u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Clear Software Interrupt and BRK Interrupt Enable Bit
    repeat(15) @(posedge mstr_test_clk);
    
  end
endtask

// Test instruction set
task test_inst_set;
  begin
    test_num = test_num + 1;
    $display("\nTEST #%d Starts at vector=%d, inst_test", test_num, vector);

    activate_thread_sw(1);
    wait_irq_set(1);
    u0.wb_write(1, XGATE_XGIF_0, 16'h0002);
    
    activate_thread_sw(2);
    wait_irq_set(2);
    u0.wb_write(1, XGATE_XGIF_0, 16'h0004);

    activate_thread_sw(3);
    wait_irq_set(3);
    u0.wb_write(1, XGATE_XGIF_0, 16'h0008);
    
    activate_thread_sw(4);
    wait_irq_set(4);
    u0.wb_write(1, XGATE_XGIF_0, 16'h0010);
    
    activate_thread_sw(5);
    wait_irq_set(5);
    u0.wb_write(1, XGATE_XGIF_0, 16'h0020);
    
    activate_thread_sw(6);
    wait_irq_set(6);
    u0.wb_write(1, XGATE_XGIF_0, 16'h0040);
    
    activate_thread_sw(7);
    wait_irq_set(7);
    u0.wb_write(1, XGATE_XGIF_0, 16'h0080);
    
    activate_thread_sw(8);
    wait_irq_set(8);
    u0.wb_write(1, XGATE_XGIF_0, 16'h0100);
    
    activate_thread_sw(9);
    wait_irq_set(9);
    u0.wb_write(1, XGATE_XGIF_0, 16'h0200);
    
    u0.wb_write(1, XGATE_XGSEM, 16'h5050);
    u0.wb_cmp(0, XGATE_XGSEM,    16'h0050);   //
    activate_thread_sw(10);
    wait_irq_set(10);
    u0.wb_write(1, XGATE_XGIF_0, 16'h0400);
    
    u0.wb_write(1, XGATE_XGSEM, 16'hff00);    // clear the old settings
    u0.wb_cmp(0, XGATE_XGSEM,    16'h0000);   //
    u0.wb_write(1, XGATE_XGSEM, 16'ha0a0);    // Verify that bits were unlocked by RISC
    u0.wb_cmp(0, XGATE_XGSEM,    16'h00a0);   // Verify bits were set
    u0.wb_write(1, XGATE_XGSEM, 16'hff08);    // Try to set the bit that was left locked by the RISC
    u0.wb_cmp(0, XGATE_XGSEM,    16'h0000);   // Verify no bits were set
    
    repeat(20) @(posedge mstr_test_clk);

    dump_ram(0);
  end
endtask

// check register bits - reset, read/write
task reg_test_16;
  begin
      test_num = test_num + 1;
      $display("TEST #%d Starts at vector=%d, reg_test_16", test_num, vector);
      u0.wb_cmp(0, XGATE_XGMCTL,   16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGCHID,   16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGISPHI,  16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGISPLO,  16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGVBR,    16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGIF_7,   16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGIF_6,   16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGIF_5,   16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGIF_4,   16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGIF_3,   16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGIF_2,   16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGIF_1,   16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGIF_0,   16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGSWT,    16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGSEM,    16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGCCR,    16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGPC,     16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGR1,     16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGR2,     16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGR3,     16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGR4,     16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGR5,     16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGR6,     16'h0000);   // verify reset
      u0.wb_cmp(0, XGATE_XGR7,     16'h0000);   // verify reset

      u0.wb_write(1, XGATE_XGR1, 16'h5555);
      u0.wb_cmp(  0, XGATE_XGR1, 16'h5555);
      u0.wb_write(1, XGATE_XGR2, 16'haaaa);
      u0.wb_cmp(  0, XGATE_XGR2, 16'haaaa);
      u0.wb_write(1, XGATE_XGR3, 16'h9999);
      u0.wb_cmp(  0, XGATE_XGR3, 16'h9999);
      u0.wb_write(1, XGATE_XGR4, 16'hcccc);
      u0.wb_cmp(  0, XGATE_XGR4, 16'hcccc);
      u0.wb_write(1, XGATE_XGR5, 16'h3333);
      u0.wb_cmp(  0, XGATE_XGR5, 16'h3333);
      u0.wb_write(1, XGATE_XGR6, 16'h6666);
      u0.wb_cmp(  0, XGATE_XGR6, 16'h6666);
      u0.wb_write(1, XGATE_XGR7, 16'ha5a5);
      u0.wb_cmp(  0, XGATE_XGR7, 16'ha5a5);

      u0.wb_write(1, XGATE_XGPC, 16'h5a5a);
      u0.wb_cmp(  0, XGATE_XGPC, 16'h5a5a);

      u0.wb_write(1, XGATE_XGCCR, 16'hfffa);
      u0.wb_cmp(  0, XGATE_XGCCR, 16'h000a);
      u0.wb_write(1, XGATE_XGCCR, 16'hfff5);
      u0.wb_cmp(  0, XGATE_XGCCR, 16'h0005);

  end
endtask


// Poll for XGATE Interrupt set
task wait_irq_set;
  input [ 6:0] chan_val;
  begin
    while(!xgif[chan_val])
      @(posedge mstr_test_clk); // poll it until it is set
    $display("XGATE Interrupt Request #%d set detected at vector =%d", chan_val, vector);
  end
endtask

// Poll for debug bit set
task wait_debug_set;
  begin
    u0.wb_read(1, XGATE_XGMCTL, q);
    while(~|(q & XGMCTL_XGDBG))
      u0.wb_read(1, XGATE_XGMCTL, q); // poll it until it is set
    $display("DEBUG Flag set detected at vector =%d", vector);
  end
endtask


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


task activate_channel;
  input [ 6:0] chan_val;
  begin
      $display("Activating Channel %d", chan_val);

      channel_req[chan_val] = 1'b1; // 
      repeat(1) @(posedge mstr_test_clk);
  end
endtask


task clear_channel;
  input [ 6:0] chan_val;
  begin
      $display("Clearing Channel interrupt input #%d", chan_val);

      channel_req[chan_val] = 1'b0; // 
      repeat(1) @(posedge mstr_test_clk);
   end
endtask


task clear_irq_flag;
  input [ 6:0] chan_val;
  begin
      $display("Clearing Channel interrupt flag #%d", chan_val);
      if (0 < chan_val < 16)
        u0.wb_write(1, XGATE_XGIF_0, 16'hffff);
      if (15 < chan_val < 32)
        u0.wb_write(1, XGATE_XGIF_1, 16'hffff);
      if (31 < chan_val < 48)
        u0.wb_write(1, XGATE_XGIF_2, 16'hffff);
      if (47 < chan_val < 64)
        u0.wb_write(1, XGATE_XGIF_3, 16'hffff);
      if (63 < chan_val < 80)
        u0.wb_write(1, XGATE_XGIF_4, 16'hffff);
      if (79 < chan_val < 96)
        u0.wb_write(1, XGATE_XGIF_5, 16'hffff);
      if (95 < chan_val < 112)
        u0.wb_write(1, XGATE_XGIF_6, 16'hffff);
      if (111 < chan_val < 128)
        u0.wb_write(1, XGATE_XGIF_7, 16'hffff);

      channel_req[chan_val] = 1'b0; // 
      repeat(1) @(posedge mstr_test_clk);
   end
endtask


task activate_thread_sw;
  input [ 6:0] chan_val;
  begin
      $display("Activating Sofrware Thread - Channel #%d", chan_val);

      data_xgmctl = XGMCTL_XGEM | XGMCTL_XGE;
      u0.wb_write(0, XGATE_XGMCTL, data_xgmctl);   // Enable XGATE

      channel_req[chan_val] = 1'b1; // 
      repeat(1) @(posedge mstr_test_clk);
   end
endtask

task dump_ram;
  input [15:0] start_address;
  reg   [15:0] dump_address;
  integer i, j;
  begin
      $display("Dumping RAM - Starting Address #%h", start_address);
      
      dump_address = start_address;
      while (dump_address <= start_address + 16'h0080)
	begin
	  $write("Address = %h", dump_address);
          for (i = 0; i < 16; i = i + 1)
            begin
	      $write(" %h", ram_8[dump_address]);
	      dump_address = dump_address + 1;
	    end
	$write("\n");
	end

  end
endtask

task wrap_up;
  begin
    $display("\nSimulation Finished!! - vector =%d", vector);
    if (error_count == 0)
      $display("Simulation Passed");
    else
      $display("Simulation Failed");

    $finish;
  end
endtask

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

