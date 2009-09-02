////////////////////////////////////////////////////////////////////////////////
//
//  XGATE Coprocessor - XGATE Top Level Module
//
//  Author: Robert Hayes
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

module xgate_top #(parameter ARST_LVL = 1'b0,      // asynchronous reset level
                   parameter SINGLE_CYCLE = 1'b0,  // 
		   parameter MAX_CHANNEL = 127,    // Max XGATE Interrupt Channel Number
		   parameter DWIDTH = 16)          // Data bus width
  (
  // Wishbone Signals
  output [DWIDTH-1:0] wbs_dat_o,     // databus output
  output              wbs_ack_o,     // bus cycle acknowledge output
  input               wbs_clk_i,     // master clock input
  input               wbs_rst_i,     // synchronous active high reset
  input               arst_i,        // asynchronous reset
  input         [4:0] wbs_adr_i,     // lower address bits
  input  [DWIDTH-1:0] wbs_dat_i,     // databus input
  input               wbs_we_i,      // write enable input
  input               wbs_stb_i,     // stobe/core select signal
  input               wbs_cyc_i,     // valid bus cycle input
  input         [1:0] wbs_sel_i,     // Select byte in word bus transaction
  // XGATE IO Signals
  output          [ 7:0] xgswt,        // XGATE Software Trigger Register
  output          [15:0] xgate_address,
  output                 write_mem_strb_l, // Strobe for writing low data byte
  output                 write_mem_strb_h, // Strobe for writing high data bye
  output          [15:0] write_mem_data,
  output [MAX_CHANNEL:0] xgif,             // XGATE Interrupt Flag
  input           [15:0] read_mem_data,
  input  [MAX_CHANNEL:0] chan_req_i,       // XGATE Interrupt request
  input                  risc_clk,         // Clock for RISC core
  input                  scantestmode      // Chip in in scan test mode
  );

  
  wire        zero_flag;
  wire        negative_flag;
  wire        carry_flag;
  wire        overflow_flag;
  wire [15:0] xgr1;          // XGATE Register #1
  wire [15:0] xgr2;          // XGATE Register #2
  wire [15:0] xgr3;          // XGATE Register #3
  wire [15:0] xgr4;          // XGATE Register #4
  wire [15:0] xgr5;          // XGATE Register #5
  wire [15:0] xgr6;          // XGATE Register #6
  wire [15:0] xgr7;          // XGATE Register #7

  wire [15:0] xgisp74;       // XGATE Interrupt level 7-4 stack pointer
  wire [15:0] xgisp30;       // XGATE Interrupt level 3-0 stack pointer

  wire        write_xgmctl;  // Write Strobe for XGMCTL register
  wire        write_xgisp74; // Write Strobe for XGISP74 register
  wire        write_xgisp31; // Write Strobe for XGISP31 register
  wire        write_xgvbr;   // Write Strobe for XGVBR_LO register
  wire        write_xgif_7;  // Write Strobe for Interrupt Flag Register 7
  wire        write_xgif_6;  // Write Strobe for Interrupt Flag Register 6
  wire        write_xgif_5;  // Write Strobe for Interrupt Flag Register 5
  wire        write_xgif_4;  // Write Strobe for Interrupt Flag Register 4
  wire        write_xgif_3;  // Write Strobe for Interrupt Flag Register 3
  wire        write_xgif_2;  // Write Strobe for Interrupt Flag Register 2
  wire        write_xgif_1;  // Write Strobe for Interrupt Flag Register 1
  wire        write_xgif_0;  // Write Strobe for Interrupt Flag Register 0
  wire        write_xgswt;   // Write Strobe for XGSWT register
  wire        write_xgsem;   // Write Strobe for XGSEM register
  wire        write_xgccr;   // Write Strobe for XGATE Condition Code Register
  wire        write_xgpc;    // Write Strobe for XGATE Program Counter
  wire        write_xgr7;    // Write Strobe for XGATE Data Register R7
  wire        write_xgr6;    // Write Strobe for XGATE Data Register R6
  wire        write_xgr5;    // Write Strobe for XGATE Data Register R5
  wire        write_xgr4;    // Write Strobe for XGATE Data Register R4
  wire        write_xgr3;    // Write Strobe for XGATE Data Register R3
  wire        write_xgr2;    // Write Strobe for XGATE Data Register R2
  wire        write_xgr1;    // Write Strobe for XGATE Data Register R1

  wire        clear_xgif_7;    // Strobe for decode to clear interrupt flag bank 7
  wire        clear_xgif_6;    // Strobe for decode to clear interrupt flag bank 6
  wire        clear_xgif_5;    // Strobe for decode to clear interrupt flag bank 5
  wire        clear_xgif_4;    // Strobe for decode to clear interrupt flag bank 4
  wire        clear_xgif_3;    // Strobe for decode to clear interrupt flag bank 3
  wire        clear_xgif_2;    // Strobe for decode to clear interrupt flag bank 2
  wire        clear_xgif_1;    // Strobe for decode to clear interrupt flag bank 1
  wire        clear_xgif_0;    // Strobe for decode to clear interrupt flag bank 0
  wire [15:0] clear_xgif_data; // Data for decode to clear interrupt flag

  wire        xge;           // XGATE Module Enable
  wire        xgfrz;         // Stop XGATE in Freeze Mode
  wire        xgdbg;         // XGATE Debug Mode
  wire        xgss;          // XGATE Single Step
  wire        xgsweif_c;     // Clear XGATE Software Error Interrupt FLag
  wire        xgie;          // XGATE Interrupt Enable
  wire [ 6:0] int_req;       // Encoded interrupt request
  wire [ 6:0] xgchid;        // Channel actively being processed
  wire [15:1] xgvbr;         // XGATE vector Base Address Register
  
  wire [ 2:0] semaph_risc;   // Semaphore register select from RISC
  wire [ 7:0] host_semap;    // Semaphore status for host
//  wire [15:0] write_mem_data;
//  wire [15:0] read_mem_data;
//  wire [15:0] perif_data;
  

  // ---------------------------------------------------------------------------
  // Wishbone Slave Bus interface
  xgate_wbs_bus #(.ARST_LVL(ARST_LVL),
                 .SINGLE_CYCLE(SINGLE_CYCLE))
    wishbone_s(
    .wbs_dat_o( wbs_dat_o ),
    .wbs_ack_o( wbs_ack_o ),
    .wbs_clk_i( wbs_clk_i ),
    .wbs_rst_i( wbs_rst_i ),
    .arst_i( arst_i ),
    .wbs_adr_i( wbs_adr_i ),
    .wbs_dat_i( wbs_dat_i ),
    .wbs_we_i( wbs_we_i ),
    .wbs_stb_i( wbs_stb_i ),
    .wbs_cyc_i( wbs_cyc_i ),
    .wbs_sel_i( wbs_sel_i ),
    
    // outputs
    .sync_reset( sync_reset ),
    .write_xgmctl( write_xgmctl ),
    .write_xgisp74( write_xgisp74 ),
    .write_xgisp30( write_xgisp30 ),
    .write_xgvbr( write_xgvbr ),
    .write_xgif_7( write_xgif_7 ),
    .write_xgif_6( write_xgif_6 ),
    .write_xgif_5( write_xgif_5 ),
    .write_xgif_4( write_xgif_4 ),
    .write_xgif_3( write_xgif_3 ),
    .write_xgif_2( write_xgif_2 ),
    .write_xgif_1( write_xgif_1 ),
    .write_xgif_0( write_xgif_0 ),
    .write_xgswt( write_xgswt ),
    .write_xgsem( write_xgsem ),
    .write_xgccr( write_xgccr ),
    .write_xgpc( write_xgpc ),
    .write_xgr7( write_xgr7 ),
    .write_xgr6( write_xgr6 ),
    .write_xgr5( write_xgr5 ),
    .write_xgr4( write_xgr4 ),
    .write_xgr3( write_xgr3 ),
    .write_xgr2( write_xgr2 ),
    .write_xgr1( write_xgr1 ),
    // inputs    
    .async_rst_b  ( async_rst_b ),
    .read_regs    (               // in  -- read register bits
		   { xgr7,             // XGR7
		     xgr6,             // XGR6
		     xgr5,             // XGR5
		     xgr4,             // XGR4
		     xgr3,             // XGR3
		     xgr2,             // XGR2
		     xgr1,             // XGR1
		     16'b0,            // Reserved (XGR0)
		     xgate_address,    // XGPC
		     {12'h000,  negative_flag, zero_flag, overflow_flag, carry_flag},  // XGCCR
		     16'b0,  // Reserved
		     {8'h00, host_semap},  // XGSEM
		     {8'h00, xgswt},  // XGSWT
		     xgif[ 15:  0],  // XGIF_0
		     xgif[ 31: 16],  // XGIF_1
		     xgif[ 47: 32],  // XGIF_2
		     xgif[ 63: 48],  // XGIF_3
		     xgif[ 79: 64],  // XGIF_4
		     xgif[ 95: 80],  // XGIF_5
		     xgif[111: 96],  // XGIF_6
		     xgif[127:112],  // XGIF_7
		     {xgvbr[15:1], 1'b0},  // XGVBR
		     xgisp30,  // Reserved
		     xgisp74,  // Reserved
		     {8'b0, 1'b0, xgchid},  // XGCHID
		     {8'b0, xge, xgfrz, 1'b0, xgdbg, 2'b0, 1'b0, xgie}  // XGMCTL
		   }
		  )
  );

  // ---------------------------------------------------------------------------
  xgate_regs #(.ARST_LVL(ARST_LVL),
               .MAX_CHANNEL(MAX_CHANNEL))
    regs(
    // outputs
    .xge( xge ),
    .xgfrz( xgfrz ),
    .xgdbg( xgdbg ),
    .xgss( xgss ),
    .xgsweif_c( xgsweif_c ),
    .xgie( xgie ),
    .xgvbr( xgvbr ),
    .xgswt( xgswt ),
    .xgisp74( xgisp74 ), 
    .xgisp30( xgisp30 ),
    .clear_xgif_7( clear_xgif_7 ),
    .clear_xgif_6( clear_xgif_6 ),
    .clear_xgif_5( clear_xgif_5 ),
    .clear_xgif_4( clear_xgif_4 ),
    .clear_xgif_3( clear_xgif_3 ),
    .clear_xgif_2( clear_xgif_2 ),
    .clear_xgif_1( clear_xgif_1 ),
    .clear_xgif_0( clear_xgif_0 ),
    .clear_xgif_data( clear_xgif_data ),

    // inputs
    .async_rst_b( async_rst_b ),
    .sync_reset( sync_reset ),
    .bus_clk( wbs_clk_i ),
    .write_bus( wbs_dat_i ),
    .write_xgmctl( write_xgmctl ),
    .write_xgisp74( write_xgisp74 ),
    .write_xgisp30( write_xgisp30 ),
    .write_xgvbr( write_xgvbr ),
    .write_xgif_7( write_xgif_7 ),
    .write_xgif_6( write_xgif_6 ),
    .write_xgif_5( write_xgif_5 ),
    .write_xgif_4( write_xgif_4 ),
    .write_xgif_3( write_xgif_3 ),
    .write_xgif_2( write_xgif_2 ),
    .write_xgif_1( write_xgif_1 ),
    .write_xgif_0( write_xgif_0 ),
    .write_xgswt( write_xgswt )

    
  );

  // ---------------------------------------------------------------------------
  xgate_risc #(.MAX_CHANNEL(MAX_CHANNEL))
    risc(
    // outputs
    .xgate_address( xgate_address ),
    .write_mem_strb_l( write_mem_strb_l ),
    .write_mem_strb_h( write_mem_strb_h ),
    .write_mem_data( write_mem_data ),
    .zero_flag( zero_flag ),
    .negative_flag( negative_flag ),
    .carry_flag( carry_flag ),
    .overflow_flag( overflow_flag ),
    .xgchid( xgchid ),
    .host_semap( host_semap ),
    .xgr1( xgr1 ),
    .xgr2( xgr2 ),
    .xgr3( xgr3 ),
    .xgr4( xgr4 ),
    .xgr5( xgr5 ),
    .xgr6( xgr6 ),
    .xgr7( xgr7 ),
    .xgif( xgif ),
  
    // inputs
    .risc_clk( risc_clk ),
    .perif_data( wbs_dat_i ),
    .async_rst_b( async_rst_b ),
    .read_mem_data( read_mem_data ),
    .xge( xge ),
    .xgfrz( xgfrz ),
    .xgdbg( xgdbg ),
    .xgss( xgss ),
    .xgvbr( xgvbr ),
    .int_req(int_req),
    .write_xgsem( write_xgsem ),
    .write_xgccr( write_xgccr ),
    .write_xgpc( write_xgpc ),
    .write_xgr7( write_xgr7 ),
    .write_xgr6( write_xgr6 ),
    .write_xgr5( write_xgr5 ),
    .write_xgr4( write_xgr4 ),
    .write_xgr3( write_xgr3 ),
    .write_xgr2( write_xgr2 ),
    .write_xgr1( write_xgr1 ),
    .clear_xgif_7( clear_xgif_7 ),
    .clear_xgif_6( clear_xgif_6 ),
    .clear_xgif_5( clear_xgif_5 ),
    .clear_xgif_4( clear_xgif_4 ),
    .clear_xgif_3( clear_xgif_3 ),
    .clear_xgif_2( clear_xgif_2 ),
    .clear_xgif_1( clear_xgif_1 ),
    .clear_xgif_0( clear_xgif_0 ),
    .clear_xgif_data( clear_xgif_data )
  );

  xgate_irq_encode #(.MAX_CHANNEL(MAX_CHANNEL)) 
    irq_encode(
    // outputs
    .int_req( int_req ),
    // inputs
    .chan_req_i( chan_req_i )
  );


endmodule  // xgate_top
