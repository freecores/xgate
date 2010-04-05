// 45678901234567890123456789012345678901234567890123456789012345678901234567890
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// SVN tag: None

Apr 5,2010
RTL - First pass at fixing bug when entering DEBUG by command from the slave
    WISHBONE bus. All tests now pass when the RAM wait states are set to zero,
    although there are errors in DEBUG mode when RAM wait states are increased.
   Icarus Verilog version 0.9.2 now supports the "generate" command. This is
    now used to instantiate the semaphore registers.

Testbench - Added capability to insert wait states on RAM access.

Doc - No change.

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// SVN tag: None

Feb 12,2010
RTL - Update to the WISHBONE interface when wait states are enabled to trade
   16 data flops for 5 address registers. This change now also requires single
   cycle timing on the WISHBONE address bus, multi-cycle timing is still
   allowed on the WISHBONE write data bus. In the old design WISHBONE read
   cycles required the address to be decoded and the read data to be latched
   in the first cycle and the there was a whole cycle to drive the read data
   bus. The new design latches the address in the first cycle then decodes the
   address and outputs the data in the second cycle. (The WISHBONE bus doesn't
   require the address or data to be latched for multi-cycle operation but by
   doing this it is hoped some power will be saved in the combinational logic
   by reducing the decoding activity at each address change.)

Testbench - No change.

Doc - No change.

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// SVN tag: None

Jan 27,2010
RTL - 85% done -- Fixed error in wbs_ack_o signal when Xgate wait states were
   enabled. If a slave bus transaction was started but not completed in the
   second cycle a wbs_ack_o output was still generated. Added a wbs_err_o output
   signal to flag this input condition but not sure if it is really needed.
  The old testbench was "helping" the Xgate module by sending an almost
   continuous wbm_ack_i signal which allowed the RISC state machine to advance
   when it shouldn't. Changes were made to the WISHBONE master bus interface
   and the RISC control logic.

Updates to testbench -- Extensive changes to testbench. The bus arbitration
   module has been completely rewritten. It now completely controls access to the
   system bus and RAM. It internally generates a WISHBONE ack signal for the RAM.
   The test control registers have been moved out of the top level and put into
   a new WISHBONE slave module which also attaches to the system bus. The Xgate
   modules master and slave buses are fully integrated with the bus arbitration
   module and the system bus. The new testbench looks a lot more like a real
   system environment.
  To Do: Add back "random" wait state generation for RAM access.

Updates to User Guide -- Minor corrections to instruction set details. Needs more
  review on condition code settings.

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// SVN tag: None

Jan 11,2010
RTL - 85% done -- Fix error in Zero Flag calculation for ADC and SBC instructions
  Fix Error in loading R2 durning cpu_state == BOOT_3.
  THere is a bug in DEBUG mode that is sensitive to number of preceding
   instructions and wait states that needs to be resolved.

Updates to testbench -- 

Updates to User Guide -- First pass with instruction set details. Needs more
  review on condition code settings.

////////////////////////////////////////////////////////////////////////////////
// SVN tag: None

Dec 08,2009
RTL - 85% done -- Updated code so there is only one program counter adder.
   Updated WISHBONE Slave bus for word addressability and byte selection.
   Deleted two stack pointer registers.

Updates to testbench -- 

Updates to User Guide -- Minor cleanup.

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// SVN tag: None

Nov 09,2009
RTL - 85% done - Minor changes to Mastermode bus.

Updates to testbench, Moved RAM.to submodule, Added bus arbitration module
   but this is not fully functional. Causes timing problems when master is
   polling Xgate registers durning debug mode tests. Will probably change RAM
   model to dual port in next revision.
   Updated master module to include WISHBONE select inputs.

Updates to User Guide.

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// SVN tag: None

Oct 07,2009
RTL - 85% done
All debug commands now working, including writes to XGCHID register.

Updates to testbench, added timeout and total error count.

Updates to User Guide --.

Created the sw directory and copied over the software stuff from the bench
directory.

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// SVN tag: None

Sept 23,2009
BRK instruction working. Single Step Command in debug mode working.
Software error interrupt added.

Updates to testbench.
New assembly code directory: debug_test

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// SVN tag: None

Sept 10,2009
Added WISHBONE master bus submodule and some related top level signals but still
  not much real functionality.
  
Added code to allow for memory access stalls.

Upgraded testbench to insert memory wait states. Added more error detection
  and summery.

Improved instruction decoder. Still needs more work to remove redundant adders
  to improve synthesis results.

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// SVN tag: None

Sept 1, 2009
This is a prerelease checkin and should be looked at as an incremental backup
and not representative of what may be in the final release.

RTL - 75% done
What works:
  Basic instruction set execution simulated and verified. Condition code
  operation on instructions partially verified.

  Basic WISHBONE slave bus operation used, full functionality not verified.

What's broken or unimplemented:
  All things related to debug mode.
  WISHBONE master bus interface.

User Documentation - 30% done

