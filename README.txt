// 45678901234567890123456789012345678901234567890123456789012345678901234567890
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

