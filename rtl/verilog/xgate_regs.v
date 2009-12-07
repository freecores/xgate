////////////////////////////////////////////////////////////////////////////////
//
//  Computer Operating Properly - Control registers
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

module xgate_regs #(parameter ARST_LVL = 1'b0,    // asynchronous reset level
                    parameter MAX_CHANNEL = 127)  // Max XGATE Interrupt Channel Number
  (
  output reg                  xge,          // XGATE Module Enable
  output reg                  xgfrz,        // Stop XGATE in Freeze Mode
  output reg                  xgdbg_set,    // Enter XGATE Debug Mode
  output reg                  xgdbg_clear,  // Leave XGATE Debug Mode
  output reg                  xgss,         // XGATE Single Step
  output reg                  xgfact,       // XGATE Flag Activity
  output reg                  xgsweif_c,    // Clear XGATE Software Error Interrupt FLag
  output reg                  xgie,         // XGATE Interrupt Enable
  output reg           [15:1] xgvbr,        // XGATE vector Base Address Register
  output reg           [ 7:0] xgswt,        // XGATE Software Trigger Register for host
  output reg           [15:0] xgisp74,      // XGATE Interrupt level 7-4 stack pointer
  output reg           [15:0] xgisp30,      // XGATE Interrupt level 3-0 stack pointer
  output reg                  clear_xgif_7,    // Strobe for decode to clear interrupt flag bank 7
  output reg                  clear_xgif_6,    // Strobe for decode to clear interrupt flag bank 6
  output reg                  clear_xgif_5,    // Strobe for decode to clear interrupt flag bank 5
  output reg                  clear_xgif_4,    // Strobe for decode to clear interrupt flag bank 4
  output reg                  clear_xgif_3,    // Strobe for decode to clear interrupt flag bank 3
  output reg                  clear_xgif_2,    // Strobe for decode to clear interrupt flag bank 2
  output reg                  clear_xgif_1,    // Strobe for decode to clear interrupt flag bank 1
  output reg                  clear_xgif_0,    // Strobe for decode to clear interrupt flag bank 0
  output reg           [15:0] clear_xgif_data, // Data for decode to clear interrupt flag
  output                      semaph_stat,     // Return Status of Semaphore bit
  output reg                  brk_irq_ena,     // Enable BRK instruction to generate interrupt

  input                       bus_clk,       // Control register bus clock
  input                       async_rst_b,   // Async reset signal
  input                       sync_reset,    // Syncronous reset signal
  input                [15:0] write_bus,     // Write Data Bus
  input                       write_xgmctl,  // Write Strobe for XGMCTL register
  input                       write_xgisp74, // Write Strobe for XGISP74 register
  input                       write_xgisp30, // Write Strobe for XGISP30 register
  input                [ 1:0] write_xgvbr,   // Write Strobe for XGVBR register
  input                [ 1:0] write_xgif_7,  // Write Strobe for Interrupt Flag Register 7
  input                [ 1:0] write_xgif_6,  // Write Strobe for Interrupt Flag Register 6
  input                [ 1:0] write_xgif_5,  // Write Strobe for Interrupt Flag Register 5
  input                [ 1:0] write_xgif_4,  // Write Strobe for Interrupt Flag Register 4
  input                [ 1:0] write_xgif_3,  // Write Strobe for Interrupt Flag Register 3
  input                [ 1:0] write_xgif_2,  // Write Strobe for Interrupt Flag Register 2
  input                [ 1:0] write_xgif_1,  // Write Strobe for Interrupt Flag Register 1
  input                [ 1:0] write_xgif_0,  // Write Strobe for Interrupt Flag Register 0
  input                       write_xgswt    // Write Strobe for XGSWT register
  );


  // registers

  // Wires
  wire [ 1:0] write_any_xgif;

  //
  // module body
  //


  // generate wishbone write registers
  // XGMCTL Register
  always @(posedge bus_clk or negedge async_rst_b)
    if (!async_rst_b)
      begin
        xge         <= 1'b0;
        xgfrz       <= 1'b0;
        xgdbg_set   <= 1'b0;
        xgdbg_clear <= 1'b0;
        xgss        <= 1'b0;
        xgfact      <= 1'b0;
	brk_irq_ena <= 1'b0;
        xgsweif_c   <= 1'b0;
        xgie        <= 1'b0;
       end
    else if (sync_reset)
      begin
        xge         <= 1'b0;
        xgfrz       <= 1'b0;
        xgdbg_set   <= 1'b0;
        xgdbg_clear <= 1'b0;
        xgss        <= 1'b0;
        xgfact      <= 1'b0;
	brk_irq_ena <= 1'b0;
        xgsweif_c   <= 1'b0;
        xgie        <= 1'b0;
     end
    else if (write_xgmctl)
      begin
        xge         <= write_bus[15] ? write_bus[7] : xge;
        xgfrz       <= write_bus[14] ? write_bus[6] : xgfrz;
        xgdbg_set   <= write_bus[13] && write_bus[5];
        xgdbg_clear <= write_bus[13] && !write_bus[5];
        xgss        <= write_bus[12] && write_bus[4];
        xgfact      <= write_bus[11] ? write_bus[3] : xgfact;
        brk_irq_ena <= write_bus[10] ? write_bus[2] : brk_irq_ena;
        xgsweif_c   <= write_bus[ 9] && write_bus[1];
        xgie        <= write_bus[ 8] ? write_bus[0] : xgie;
      end
    else
      begin
        xgss        <= 1'b0;
        xgsweif_c   <= 1'b0;
        xgdbg_set   <= 1'b0;
        xgdbg_clear <= 1'b0;
      end

  // XGVBR Register
  always @(posedge bus_clk or negedge async_rst_b)
    if (!async_rst_b)
      begin
        xgvbr  <= 15'b1111_1110_0000_000;
       end
    else if (sync_reset)
      begin
        xgvbr  <= 15'b1111_1110_0000_000;
      end
    else if (|write_xgvbr && !xge)
      begin
        xgvbr[15:8]  <= write_xgvbr[1] ? write_bus[15:8] : xgvbr[15:8];
        xgvbr[ 7:1]  <= write_xgvbr[0] ? write_bus[ 7:1] : xgvbr[ 7:1];
      end

  // XGISP74 Register
  always @(posedge bus_clk or negedge async_rst_b)
    if (!async_rst_b)
      xgisp74  <= 16'b0;
    else if (sync_reset)
      xgisp74  <= 16'b0;
    else if (write_xgisp74)
      xgisp74  <= xge ? xgisp74 : write_bus;

  // XGISP30 Register
  always @(posedge bus_clk or negedge async_rst_b)
    if (!async_rst_b)
      xgisp30  <= 16'b0;
    else if (sync_reset)
      xgisp30  <= 16'b0;
    else if (write_xgisp30)
      xgisp30  <= xge ? xgisp30 : write_bus;

  // XGIF 7-0 Registers
  assign write_any_xgif = write_xgif_7 | write_xgif_6 | write_xgif_5 | write_xgif_4 |
                          write_xgif_3 | write_xgif_2 | write_xgif_1 | write_xgif_0;

  // Registers to clear the interrupt flags. Decode a specific interrupt to
  //  clear by ANDing the clear_xgif_x signal with the clear_xgif_data.
  always @(posedge bus_clk or negedge async_rst_b)
    if (!async_rst_b)
      begin
        clear_xgif_7    <= 1'b0;
        clear_xgif_6    <= 1'b0;
        clear_xgif_5    <= 1'b0;
        clear_xgif_4    <= 1'b0;
        clear_xgif_3    <= 1'b0;
        clear_xgif_2    <= 1'b0;
        clear_xgif_1    <= 1'b0;
        clear_xgif_0    <= 1'b0;
        clear_xgif_data <= 16'b0;
      end
    else if (sync_reset)
      begin
        clear_xgif_7    <= 1'b0;
        clear_xgif_6    <= 1'b0;
        clear_xgif_5    <= 1'b0;
        clear_xgif_4    <= 1'b0;
        clear_xgif_3    <= 1'b0;
        clear_xgif_2    <= 1'b0;
        clear_xgif_1    <= 1'b0;
        clear_xgif_0    <= 1'b0;
        clear_xgif_data <= 16'b0;
      end
    else
      begin
        clear_xgif_7    <= |write_xgif_7 && (MAX_CHANNEL > 111);
        clear_xgif_6    <= |write_xgif_6 && (MAX_CHANNEL > 95);
        clear_xgif_5    <= |write_xgif_5 && (MAX_CHANNEL > 79);
        clear_xgif_4    <= |write_xgif_4 && (MAX_CHANNEL > 63);
        clear_xgif_3    <= |write_xgif_3 && (MAX_CHANNEL > 47);
        clear_xgif_2    <= |write_xgif_2 && (MAX_CHANNEL > 31);
        clear_xgif_1    <= |write_xgif_1 && (MAX_CHANNEL > 15);
        clear_xgif_0    <= |write_xgif_0;
        clear_xgif_data[15:8] <= write_any_xgif[1] ? write_bus[15:8] : 8'b0;
        clear_xgif_data[ 7:0] <= write_any_xgif[0] ? write_bus[ 7:0] : 8'b0;
      end


  // XGSWT - XGATE Software Trigger Register
  always @(posedge bus_clk or negedge async_rst_b)
    if (!async_rst_b)
      xgswt <= 8'h00;
    else if (sync_reset)
      xgswt <= 8'h00;
    else if (write_xgswt)
      begin
        xgswt[7] <= write_bus[15] ? write_bus[7] : xgswt[7];
        xgswt[6] <= write_bus[14] ? write_bus[6] : xgswt[6];
        xgswt[5] <= write_bus[13] ? write_bus[5] : xgswt[5];
        xgswt[4] <= write_bus[11] ? write_bus[4] : xgswt[4];
        xgswt[3] <= write_bus[12] ? write_bus[3] : xgswt[3];
        xgswt[2] <= write_bus[10] ? write_bus[2] : xgswt[2];
        xgswt[1] <= write_bus[ 9] ? write_bus[1] : xgswt[1];
        xgswt[0] <= write_bus[ 8] ? write_bus[0] : xgswt[0];
      end


endmodule  // xgate_regs


