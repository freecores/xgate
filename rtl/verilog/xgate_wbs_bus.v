////////////////////////////////////////////////////////////////////////////////
//
//  WISHBONE revB.2 compliant Xgate Coprocessor - Slave Bus interface
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

module xgate_wbs_bus #(parameter ARST_LVL = 1'b0,    // asynchronous reset level
  		       parameter DWIDTH = 16,
                       parameter SINGLE_CYCLE = 1'b0)
  (
  // Wishbone Signals
  output      [DWIDTH-1:0] wbs_dat_o,     // databus output
  output                   wbs_ack_o,     // bus cycle acknowledge output
  input                    wbs_clk_i,     // master clock input
  input                    wbs_rst_i,     // synchronous active high reset
  input                    arst_i,        // asynchronous reset
  input             [ 5:1] wbs_adr_i,     // lower address bits
  input       [DWIDTH-1:0] wbs_dat_i,     // databus input
  input                    wbs_we_i,      // write enable input
  input                    wbs_stb_i,     // stobe/core select signal
  input                    wbs_cyc_i,     // valid bus cycle input
  input              [1:0] wbs_sel_i,     // Select byte in word bus transaction
  // XGATE Control Signals
  output reg               write_xgmctl, // Write Strobe for XGMCTL register
  output reg               write_xgchid, // Write Strobe for XGCHID register
  output reg               write_xgisp74,// Write Strobe for XGISP74 register
  output reg               write_xgisp30,// Write Strobe for XGISP30 register
  output reg         [1:0] write_xgvbr,  // Write Strobe for XGVBR register
  output reg         [1:0] write_xgif_7, // Write Strobe for Interrupt Flag Register 7
  output reg         [1:0] write_xgif_6, // Write Strobe for Interrupt Flag Register 6
  output reg         [1:0] write_xgif_5, // Write Strobe for Interrupt Flag Register 5
  output reg         [1:0] write_xgif_4, // Write Strobe for Interrupt Flag Register 4
  output reg         [1:0] write_xgif_3, // Write Strobe for Interrupt Flag Register 3
  output reg         [1:0] write_xgif_2, // Write Strobe for Interrupt Flag Register 2
  output reg         [1:0] write_xgif_1, // Write Strobe for Interrupt Flag Register 1
  output reg         [1:0] write_xgif_0, // Write Strobe for Interrupt Flag Register 0
  output reg               write_xgswt,  // Write Strobe for XGSWT register
  output reg               write_xgsem,  // Write Strobe for XGSEM register
  output reg               write_xgccr,  // Write Strobe for XGATE Condition Code Register
  output reg         [1:0] write_xgpc,   // Write Strobe for XGATE Program Counter
  output reg         [1:0] write_xgr7,   // Write Strobe for XGATE Data Register R7
  output reg         [1:0] write_xgr6,   // Write Strobe for XGATE Data Register R6
  output reg         [1:0] write_xgr5,   // Write Strobe for XGATE Data Register R5
  output reg         [1:0] write_xgr4,   // Write Strobe for XGATE Data Register R4
  output reg         [1:0] write_xgr3,   // Write Strobe for XGATE Data Register R3
  output reg         [1:0] write_xgr2,   // Write Strobe for XGATE Data Register R2
  output reg         [1:0] write_xgr1,   // Write Strobe for XGATE Data Register R1
  output                   async_rst_b,  //
  output                   sync_reset,   //
  input            [415:0] read_regs     // status register bits
  );


  // registers
  reg                bus_wait_state;  // Holdoff wbs_ack_o for one clock to add wait state
  reg  [DWIDTH-1:0]  rd_data_mux;     // Pseudo Register, WISHBONE Read Data Mux
  reg  [DWIDTH-1:0]  rd_data_reg;     // Latch for WISHBONE Read Data
  
  reg                write_reserv1;   // Dummy Reg decode for Reserved address
  reg                write_reserv2;   // Dummy Reg decode for Reserved address

  // Wires
  wire   module_sel;       // This module is selected for bus transaction
  wire   wbs_wacc;         // WISHBONE Write Strobe (Clock gating signal)
  wire   wbs_racc;         // WISHBONE Read Access (Clock gating signal)

  //
  // module body
  //

  // generate internal resets
  assign async_rst_b = arst_i ^ ARST_LVL;
  assign sync_reset  = wbs_rst_i;

  // generate wishbone signals
  assign module_sel  = wbs_cyc_i && wbs_stb_i;
  assign wbs_wacc    = module_sel && wbs_we_i && (wbs_ack_o || SINGLE_CYCLE);
  assign wbs_racc    = module_sel && !wbs_we_i;
  assign wbs_ack_o   = SINGLE_CYCLE ? module_sel : bus_wait_state;
  assign wbs_dat_o   = SINGLE_CYCLE ? rd_data_mux : rd_data_reg;

  // generate acknowledge output signal, By using register all accesses takes two cycles.
  //  Accesses in back to back clock cycles are not possable.
  always @(posedge wbs_clk_i or negedge async_rst_b)
    if (!async_rst_b)
      bus_wait_state <=  1'b0;
    else if (sync_reset)
      bus_wait_state <=  1'b0;
    else
      bus_wait_state <=  module_sel && !bus_wait_state;

  // assign data read bus -- DAT_O
  always @(posedge wbs_clk_i)
    if ( wbs_racc )                     // Clock gate for power saving
      rd_data_reg <= rd_data_mux;

      
  // WISHBONE Read Data Mux
  always @*
      case (wbs_adr_i) // synopsys parallel_case
	// 16 bit Bus, 16 bit Granularity
	5'b0_0000: rd_data_mux = read_regs[ 15:  0];
	5'b0_0001: rd_data_mux = read_regs[ 31: 16];
	5'b0_0010: rd_data_mux = read_regs[ 47: 32];
	5'b0_0011: rd_data_mux = read_regs[ 63: 48];
	5'b0_0100: rd_data_mux = read_regs[ 79: 64];
	5'b0_0101: rd_data_mux = read_regs[ 95: 80];
	5'b0_0110: rd_data_mux = read_regs[111: 96];
	5'b0_0111: rd_data_mux = read_regs[127:112];
	5'b0_1000: rd_data_mux = read_regs[143:128];
	5'b0_1001: rd_data_mux = read_regs[159:144];
	5'b0_1010: rd_data_mux = read_regs[175:160];
	5'b0_1011: rd_data_mux = read_regs[191:176];
	5'b0_1100: rd_data_mux = read_regs[207:192];
	5'b0_1101: rd_data_mux = read_regs[223:208];
	5'b0_1110: rd_data_mux = read_regs[239:224];
	5'b0_1111: rd_data_mux = read_regs[255:240];
	5'b1_0000: rd_data_mux = read_regs[271:256];
	5'b1_0001: rd_data_mux = read_regs[287:272];
	5'b1_0010: rd_data_mux = read_regs[303:288];
	5'b1_0011: rd_data_mux = read_regs[319:304];
	5'b1_0100: rd_data_mux = read_regs[335:320];
	5'b1_0101: rd_data_mux = read_regs[351:336];
	5'b1_0110: rd_data_mux = read_regs[367:352];
	5'b1_0111: rd_data_mux = read_regs[383:368];
	5'b1_1000: rd_data_mux = read_regs[399:384];
	5'b1_1001: rd_data_mux = read_regs[415:400];
	default: rd_data_mux = 16'h0000;
      endcase

  // generate wishbone write register strobes
  always @*
    begin
      write_reserv1 = 1'b0;
      write_reserv2 = 1'b0;
      write_xgmctl  = 1'b0;
      write_xgchid  = 1'b0;
      write_xgisp74 = 1'b0;
      write_xgisp30 = 1'b0;
      write_xgvbr  = 2'b00;
      write_xgif_7 = 2'b00;
      write_xgif_6 = 2'b00;
      write_xgif_5 = 2'b00;
      write_xgif_4 = 2'b00;
      write_xgif_3 = 2'b00;
      write_xgif_2 = 2'b00;
      write_xgif_1 = 2'b00;
      write_xgif_0 = 2'b00;
      write_xgswt  = 1'b0;
      write_xgsem  = 1'b0;
      write_xgccr  = 1'b0;
      write_xgpc   = 2'b00;
      write_xgr7   = 2'b00;
      write_xgr6   = 2'b00;
      write_xgr5   = 2'b00;
      write_xgr4   = 2'b00;
      write_xgr3   = 2'b00;
      write_xgr2   = 2'b00;
      write_xgr1   = 2'b00;
      if (wbs_wacc)
	case (wbs_adr_i) // synopsys parallel_case
           // 16 bit Bus, 8 bit Granularity
	   5'b0_0000 : write_xgmctl  = &wbs_sel_i;
	   5'b0_0001 : write_xgchid  = wbs_sel_i[0];
	   5'b0_0010 : write_xgisp74 = 1'b1;
	   5'b0_0011 : write_xgisp30 = 1'b1;
	   5'b0_0100 : write_xgvbr   = wbs_sel_i;
	   5'b0_0101 : write_xgif_7  = wbs_sel_i;
	   5'b0_0110 : write_xgif_6  = wbs_sel_i;
	   5'b0_0111 : write_xgif_5  = wbs_sel_i;
	   5'b0_1000 : write_xgif_4  = wbs_sel_i;
	   5'b0_1001 : write_xgif_3  = wbs_sel_i;
	   5'b0_1010 : write_xgif_2  = wbs_sel_i;
	   5'b0_1011 : write_xgif_1  = wbs_sel_i;
	   5'b0_1100 : write_xgif_0  = wbs_sel_i;
	   5'b0_1101 : write_xgswt   = &wbs_sel_i;
	   5'b0_1110 : write_xgsem   = &wbs_sel_i;
	   5'b0_1111 : write_reserv1 = 1'b1;
	   5'b1_0000 : write_xgccr   = wbs_sel_i[0];
	   5'b1_0001 : write_xgpc    = wbs_sel_i;
	   5'b1_0010 : write_reserv2 = 1'b1;
	   5'b1_0011 : write_xgr1    = wbs_sel_i;
	   5'b1_0100 : write_xgr2    = wbs_sel_i;
	   5'b1_0101 : write_xgr3    = wbs_sel_i;
	   5'b1_0110 : write_xgr4    = wbs_sel_i;
	   5'b1_0111 : write_xgr5    = wbs_sel_i;
	   5'b1_1000 : write_xgr6    = wbs_sel_i;
	   5'b1_1001 : write_xgr7    = wbs_sel_i;
	   default: ;
	endcase
    end

endmodule  // xgate_wbs_bus
