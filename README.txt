// 45678901234567890123456789012345678901234567890123456789012345678901234567890
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