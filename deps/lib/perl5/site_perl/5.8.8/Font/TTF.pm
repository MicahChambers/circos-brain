package Font::TTF;

$VERSION = '1.02';    # MJPH    30-Aug-2012      Fix case typo in Useall
# $VERSION = '1.01';    # MJPH    30-Aug-2012      add IO::String prerequisite
# $VERSION = '1.00';    # MJPH    21-Aug-2012      OS/2, OT & Graphite improvements; bug fixes
# $VERSION = '0.48';    # MJPH    15-DEC-2010      Bug fixes
# $VERSION = '0.47';    # MJPH     7-AUG-2009      Minor bug fix in Name.pm
# $VERSION = '0.46';    # MJPH    26-JAN-2009      Various bug fixes, add Sill table
# $VERSION = '0.45';    # MJPH    11-JUN-2008      Packaging tidying
# $VERSION = '0.44';    # MJPH     9-JUN-2008      Various bug fixes
# $VERSION = '0.43';    # MJPH    20-NOV-2007      Add a test!
# $VERSION = '0.42';    # MJPH    11-OCT-2007      Add Volt2ttf support
# $VERSION = '0.41';    # MJPH    27-MAR-2007      Remove warnings from font copy
#                                                  Bug fixes in Ttopen, GDEF
#                                                  Remove redundant head and maxp ->reads
# $VERSION = '0.40';    # MJPH    31-JUL-2006      Add EBDT, EBLC tables
# $VERSION = 0.39;

1;

=head1 NAME

Font::TTF - Perl module for TrueType Font hacking

=head1 DESCRIPTION

This module allows you to do almost anything to a TrueType/OpenType Font
including modify and inspect nearly all tables.

