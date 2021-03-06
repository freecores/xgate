///////////////////////////////////////////////////////////////////////
////                                                               ////
////  WISHBONE rev.B2 Wishbone Master model                        ////
////                                                               ////
////                                                               ////
////  Author: Richard Herveille                                    ////
////          richard@asics.ws                                     ////
////          www.asics.ws                                         ////
////                                                               ////
////  Downloaded from: http://www.opencores.org/projects/mem_ctrl  ////
////                                                               ////
///////////////////////////////////////////////////////////////////////
////                                                               ////
//// Copyright (C) 2001 Richard Herveille                          ////
////                    richard@asics.ws                           ////
////                                                               ////
//// This source file may be used and distributed without          ////
//// restriction provided that this copyright statement is not     ////
//// removed from the file and that any derivative work contains   ////
//// the original copyright notice and the associated disclaimer.  ////
////                                                               ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY       ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS     ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR        ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,           ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES      ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE     ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR          ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT    ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT    ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE           ////
//// POSSIBILITY OF SUCH DAMAGE.                                   ////
////                                                               ////
///////////////////////////////////////////////////////////////////////

//
`include "timescale.v"

module wb_master_model  #(parameter dwidth = 32,
                          parameter awidth = 32)
(
output reg                 cyc,
output reg                 stb,
output reg                 we,
output reg [dwidth/8 -1:0] sel,
output reg [awidth   -1:0] adr,
output reg [dwidth   -1:0] dout,
input      [dwidth   -1:0] din,
input                      clk,
input                      ack,
input                      rst,  // No Connect
input                      err,  // No Connect
input                      rty   // No Connect
);

////////////////////////////////////////////////////////////////////
//
// Local Wires
//

reg [dwidth-1:0] q;

event test_command_start;
event test_command_mid;
event test_command_end;

event cmp_error_detect;

////////////////////////////////////////////////////////////////////
//
// Memory Logic
//

initial
  begin
    adr  = {awidth{1'bx}};
    dout = {dwidth{1'bx}};
    cyc  = 1'b0;
    stb  = 1'bx;
    we   = 1'hx;
    sel  = {dwidth/8{1'bx}};
    #1;
    $display("\nINFO: WISHBONE MASTER MODEL INSTANTIATED (%m)");
  end


////////////////////////////////////////////////////////////////////
//
// Wishbone write cycle
//

task wb_write;
  input   delay;
  integer delay;

  input   [awidth   -1:0] a;
  input   [dwidth   -1:0] d;
  input   [dwidth/8 -1:0] s;

  begin
    -> test_command_start;
    // wait initial delay
    repeat(delay) @(posedge clk);

    // assert wishbone signal
    #1;
    adr  = a;
    dout = d;
    cyc  = 1'b1;
    stb  = 1'b1;
    we   = 1'b1;
    sel  = s;
    @(posedge clk);
    -> test_command_mid;

    // wait for acknowledge from slave
    while(~ack)     @(posedge clk);
    -> test_command_mid;

    // negate wishbone signals
    #1;
    cyc  = 1'b0;
    stb  = 1'bx;
    adr  = {awidth{1'bx}};
    dout = {dwidth{1'bx}};
    we   = 1'hx;
    sel  = {dwidth/8{1'bx}};
    -> test_command_end;
  end

endtask

////////////////////////////////////////////////////////////////////
//
// Wishbone read cycle
//

task wb_read;
  input   delay;
  integer delay;

  input   [awidth   -1:0] a;
  output  [dwidth   -1:0] d;
  input   [dwidth/8 -1:0] s;

  begin
    // wait initial delay
    repeat(delay) @(posedge clk);

    // assert wishbone signals
    #1;
    adr  = a;
    dout = {dwidth{1'bx}};
    cyc  = 1'b1;
    stb  = 1'b1;
    we   = 1'b0;
    sel  = s;
    @(posedge clk);

    // wait for acknowledge from slave
    while(~ack)     @(posedge clk);

    // negate wishbone signals
    d    = din; // Grab the data on the posedge of clock
    #1;         // Delay the clearing (hold time of the control signals
    cyc  = 1'b0;
    stb  = 1'bx;
    adr  = {awidth{1'bx}};
    dout = {dwidth{1'bx}};
    we   = 1'hx;
    sel  = {dwidth/8{1'bx}};
  end

endtask

////////////////////////////////////////////////////////////////////
//
// Wishbone compare cycle (read data from location and compare with expected data)
//

task wb_cmp;
  input   delay;
  integer delay;

  input [awidth   -1:0] a;
  input [dwidth   -1:0] d_exp;
  input [dwidth/8 -1:0] s;

  begin
    wb_read (delay, a, q, s);

    if (d_exp !== q)
      begin
        -> cmp_error_detect;
        $display("Data compare error at address %h. Received %h, expected %h at time %t", a, q, d_exp, $time);
      end
  end

endtask

endmodule


