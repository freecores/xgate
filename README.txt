// 45678901234567890123456789012345678901234567890123456789012345678901234567890
////////////////////////////////////////////////////////////////////////////////
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
   polling xgate registers durning debug mode tests. Will probably change RAM
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

