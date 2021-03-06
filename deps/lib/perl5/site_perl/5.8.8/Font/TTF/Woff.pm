package Font::TTF::Woff;

=head1 NAME

Font::TTF::WOFF - holds Web Open Font File (WOFF) data for the font

=head1 DESCRIPTION

This contains the WOFF packaging data.

=head1 INSTANCE VARIABLES

This object supports the following instance variables (which, because they
reflect the structure of the table, do not begin with a space):

=over

=item majorVersion

=item minorVersion

The two version integers come directly from the WOFF font header. 

=item metaData

Contains a reference to Font::TTF::Woff::Meta structure, if the font has WOFF metadata.

=item privateData

Contains a reference to a Font::TTF::Woff::Private structure, if the font has a WOFF private data block

=back

=head1 METHODS

=cut

use strict;
use vars qw(@ISA %fields @field_info);

require Font::TTF::Table;

@ISA = qw(Font::TTF::Table);

1;
