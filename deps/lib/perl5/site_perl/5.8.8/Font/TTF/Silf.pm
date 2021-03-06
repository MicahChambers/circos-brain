package Font::TTF::Silf;

=head1 NAME

Font::TTF::Silf - The main Graphite table

=head1 DESCRIPTION

The Silf table holds the core of the Graphite rules for a font. A Silf table has
potentially multiple silf subtables, although there is usually only one. Within a silf subtable,
there are a number of passes which contain the actual finite state machines to match rules
and the constraint and action code to be executed when a rule matches.

=head1 INSTANCE VARIABLES

=over 4

=item Version

Silf table format version

=item Compiler

Lowest compiler version necessary to fully support the semantics expressed in this
Graphite description

=item SILF

An array of Silf subtables

=over 4

=item maxGlyphID

The maximum glyph id referenced including pseudo and non glyphs

=item Ascent

Extra ascent to be added to the font ascent.

=item Descent

Extra descent to be added to the font descent. Both values are assumed to be
positive for a descender below the base line.

=item substPass

Pass index into PASS of the first substitution pass.

=item posPass

Pass index into PASS of the first positioning pass.

=item justPass

Pass index into PASS of the first justification pass.

=item bidiPass

Pass index of the pass before which the bidirectional processing pass will be executed.
0xFF indicates that there is no bidi pass to be executed.

=item Flags

A bitfield of flags:

    0 - Indicates there are line end contextual rules in one of the passes

=item maxPreContext

Maximum length of a context preceding a cross line boundary contextualisation.

=item maxPostContext

Maximum length of a context following a cross line boundary contextualsation.

=item attrPseudo

Glyph attribute for the actual glyph id associated with a pseudo glyph.

=item attrBreakWeight

Glyph attribute number of the attribute holding the default breakweight associated with a glyph.

=item attrDirectionality

Glyph attribute number of the attribute holding the default directionality value associated with a glyph.

=item JUST

The may be a number of justification levels each with their own property values.
This points to an array of hashes, one for each justification level.

=over 4

=item attrStretch

Glyph attribute number for the amount of stretch allowed before this glyph.

=item attrShrink

Glyph attribute number for the amount of shrink allowed before this glyph.

=item attrStep

Glyph attribute number specifying the minimum granularity of actual spacing associated with this glyph at this level.

=item attrWeight

Glyph attribute number giving the weight associated with spreading space across a run of glyphs.

=item runto

Which level starts the next stage.

=back

=item numLigComp

Number of initial glyph attributes that represent ligature components

=item numUserAttr

Number of user defined slot attributes referenced. Tells the engine how much space to
allocate to a slot for user attributes.

=item maxCompPerLig

Maximum number of components per ligature.

=item direction

Supported directions for this writing system

=item CRIT_FEATURE

Array of critical features.

=item scripts

Array of script tags that indicate which set of GDL rules to execute if there is more than one in a font.

=item lbGID

Glyph ID of the linebreak pseudo glyph.

=item pseudos

Hash of Unicode values to pseduo glyph ids.

=item classes

This is an array of classes, each of which is an array of glyph ids in class order.

=item PASS

The details of rules and actions are stored in passes. This value is an array of pass subobjects one for each pass.

=over 4

=item flags

This is a bitfield:

    0 - If true, this pass makes no change to the slot stream considered as a sequence of glyph ids.
        Only slot attributes are expected to change (for example during positioning).

=item maxRuleLoop

How many times the engine will allow rules to be tested and run without the engine advancing through the
input slot stream.

=item maxRuleContext

Number of slots of input needed to run this pass.

=item maxBackup

Number of slots by which the following pass needs to trail this pass (i.e. the maximum this pass is allowed to back up).

=item numRules

Number of action code blocks, and so uncompressed rules, in this pass.

=item numRows

Number of rows in the finite state machine.

=item numTransitional

Number of rows in the finite state machine that are not final states. This specifies the number of rows in the fsm
element.

=item numSuccess

Number of success states. A success state may also be a transitional state.

=item numColumns

Number of columns in the finite state machine.

=item colmap

A hash, indexed by glyphid, that gives the fsm column number associated with that glyphid. If not present, then
the glyphid is not part of the fsm and will finish fsm processing if it occurs.

=item rulemap

An array of arrays, one for each success state. Each array holds a list of rule numbers associated with that state.

=item minRulePreContext

Minimum number of items in a rule's precontext.

=item maxRulePreContext

The maximum number of items in any rule's precontext.

=item startStates

Array of starting state numbers dependeing on the length of actual precontext.
There are maxRulePreContext - minRulePreContext + 1 of these.

=item ruleSortKeys

An array of sort keys one for each rule giving the length of the rule without its precontext.

=item rulePreContexts

An array of precontext lengths for each rule.

=item fsm

A two dimensional array such that $p->{'fsm'}[$row][$col] gives the row of the next node to try in the fsm.

=item passConstraintLen

Length in bytes of the passConstraint code.

=item passConstraintCode

A byte string holding the pass constraint code.

=item constraintCode

An array of byte strings holding the constraint code for each rule.

=item actionCode

An array of byte strings holding the action code for each rule.

=back

=back

=back

=cut

use Font::TTF::Table;
use Font::TTF::Utils;
use strict;
use vars qw(@ISA);

@ISA = qw(Font::TTF::Table);

=head2 @opcodes

Each array holds the name of the opcode, the number of operand bytes and a string describing the operands.
The characterse in the string have the following meaning:

    c - lsb of class id
    C - msb of class id
    f - feature index
    g - lsb of glyph attribute id
    G - msb of glyph attribute id
    l - lsb of a 32-bit extension to a 16-bit number
    L - msb of a 32-bit number
    m - glyph metric id
    n - lsb of a number
    N - msb of a 16-bit number
    o - offset (jump)
    s - slot reference
    S - slot attribute id
    v - variable number of following arguments

=cut

our @opcodes = ( ["nop", 0, ""], ["push_byte", 1, "n"], ["push_byte_u", 1, "n"], ["push_short", 2, "Nn"],
             ["push_short_u", 2, "Nn"], ["push_long", 4, "LlNn"], ["add", 0, ""], ["sub", 0, ""],
             ["mul", 0, ""], ["div", 0, ""], ["min", 0, ""], ["max", 0, ""],
             ["neg", 0, ""], ["trunc8", 0, ""], ["trunc16", 0, ""], ["cond", 0, ""],
             ["and", 0, ""], ["or", 0, ""], ["not", 0, ""], ["equal", 0, ""],
             ["not_eq", 0, ""], ["less", 0, ""], ["gtr", 0, ""], ["less_eq", 0, ""],
             ["gtr_eq", 0, ""], ["next", 0, ""], ["next_n", 1, "n"], ["copy_next", 0, ""],
             ["put_glyph_8bit_obs", 1, "c"], ["put_subs_8bit_obs", 3, "scc"], ["put_copy", 1, "s"], ["insert", 0, ""],
             ["delete", 0, ""], ["assoc", -1, "v"], ["cntxt_item", 2, "so"], ["attr_set", 1, "S"],
             ["attr_add", 1, "S"], ["attr_sub", 1, "S"], ["attr_set_slot", 1, "S"], ["iattr_set_slot", 2, "Sn"],
             ["push_slot_attr", 2, "Ss"], ["push_glyph_attr_obs", "gs"], ["push_glyph_metric", 3, "msn"], ["push_feat", 2, "fs"],
             ["push_att_to_gattr_obs", 2, "gs"], ["push_att_to_glyph_metric", 3, "msn"], ["push_islot_attr", 3, "Ssn"], ["push_iglyph_attr", 3, "gsn"],
             ["pop_ret", 0, ""], ["ret_zero", 0, ""], ["ret_true", 0, ""], ["iattr_set", 2, "Sn"],
             ["iattr_add", 2, "Sn"], ["iattr_sub", 2, "Sn"], ["push_proc_state", 1, "n"], ["push_version", 0, ""],
             ["put_subs", 5, "sCcCc"], ["put_subs2", 4, "cscc"], ["put_subs3", 7, "scscscc"], ["put_glyph", 2, "Cc"],
             ["push_glyph_attr", 3, "Ggs"], ["push_att_to_glyph_attr", 3, "Ggs"] );

=head2 read

Reads the Silf table into the internal data structure

=cut

sub read
{
    my ($self) = @_;
    my ($dat, $d);
    my ($fh) = $self->{' INFILE'};
    my ($moff) = $self->{' OFFSET'};
    my ($numsilf, @silfo);
    
    $self->SUPER::read or return $self;
    $fh->read($dat, 4);
    ($self->{'Version'}) = TTF_Unpack("v", $dat);
    if ($self->{'Version'} >= 3)
    {
        $fh->read($dat, 4);
        ($self->{'Compiler'}) = TTF_Unpack("v", $dat);
    }
    $fh->read($dat, 4);
    ($numsilf) = TTF_Unpack("S", $dat);
    $fh->read($dat, $numsilf * 4);
    foreach my $i (0 .. $numsilf - 1)
    { push (@silfo, TTF_Unpack("L", substr($dat, $i * 4, 4))); }

    foreach my $sili (0 .. $numsilf - 1)
    {
        my ($silf) = {};
        my (@passo, @classo, $classbase, $numJust, $numCritFeatures, $numScript, $numPasses, $numPseudo, $i);

        push (@{$self->{'SILF'}}, $silf);
        $fh->seek($moff + $silfo[$sili], 0);
        if ($self->{'Version'} >= 3)
        {
            $fh->read($dat, 8);
            ($silf->{'Version'}) = TTF_Unpack("v", $dat);
        }
        $fh->read($dat, 20);
        ($silf->{'maxGlyphID'}, $silf->{'Ascent'}, $silf->{'Descent'},
         $numPasses, $silf->{'substPass'}, $silf->{'posPass'}, $silf->{'justPass'}, $silf->{'bidiPass'},
         $silf->{'Flags'}, $silf->{'maxPreContext'}, $silf->{'maxPostContext'}, $silf->{'attrPseudo'},
         $silf->{'attrBreakWeight'}, $silf->{'attrDirectionality'}, $d, $d, $numJust) = 
            TTF_Unpack("SssCCCCCCCCCCCCCC", $dat);
        if ($numJust)
        {
            foreach my $j (0 .. $silf->{'numJust'} - 1)
            {
                my ($just) = {};
                push (@{$silf->{'JUST'}}, $just);
                $fh->read($dat, 8);
                ($just->{'attrStretch'}, $just->{'attrShrink'}, $just->{'attrStep'}, $just->{'attrWeight'},
                 $just->{'runto'}) = TTF_Unpack("CCCCC", $dat);
            }
        }
        $fh->read($dat, 10);
        ($silf->{'numLigComp'}, $silf->{'numUserAttr'}, $silf->{'maxCompPerLig'}, $silf->{'direction'},
         $d, $d, $d, $d, $numCritFeatures) = TTF_Unpack("SCCCCCCCC", $dat);
        if ($numCritFeatures)
        {
            $fh->read($dat, $numCritFeatures * 2);
            $silf->{'CRIT_FEATURE'} = [TTF_Unpack("S$numCritFeatures", $dat)];
        }
        $fh->read($dat, 2);
        ($d, $numScript) = TTF_Unpack("CC", $dat);
        if ($numScript)
        {
            $fh->read($dat, $numScript * 4);
            foreach (0 .. $numScript - 1)
            { push (@{$silf->{'scripts'}}, unpack('a4', substr($dat, $_ * 4, 4))); }
        }
        $fh->read($dat, 2);
        ($silf->{'lbGID'}) = TTF_Unpack("S", $dat);
        $fh->read($dat, $numPasses * 4 + 4);
        @passo = unpack("N*", $dat);
        $fh->read($dat, 8);
        ($numPseudo) = TTF_Unpack("S", $dat);
        if ($numPseudo)
        {
            $fh->read($dat, $numPseudo * 6);
            foreach (0 .. $numPseudo - 1)
            {
                my ($uni, $gid) = TTF_Unpack("LS", substr($dat, $_ * 6, 6));
                $silf->{'pseudos'}{$uni} = $gid;
            }
        }
        $classbase = $fh->tell();
        $fh->read($dat, 4);
        my ($numClasses, $numLinearClasses) = TTF_Unpack("SS", $dat);
        $fh->read($dat, $numClasses * 2 + 2);
        @classo = unpack("n*", $dat);
        $fh->read($dat, $classo[-1] - $classo[0]);
        for ($i = 0; $i < $numLinearClasses; $i++)
        {
            my ($c) = 0;
            push (@{$silf->{'classes'}}, { map {$_ => $c++} 
                                                unpack("n*", substr($dat, $classo[$i] - $classo[0], 
                                                            $classo[$i+1] - $classo[$i])) }); 
        }
        for ($i = $numLinearClasses; $i < $numClasses; $i++)
        {
            push (@{$silf->{'classes'}}, { unpack("n*",
                substr($dat, $classo[$i] - $classo[0] + 8, $classo[$i+1] - $classo[$i] - 8)) });
        }
        foreach (0 .. $numPasses - 1)
        { $self->read_pass($fh, $passo[$_], $moff + $silfo[$sili], $silf); }
    }
    return $self;
}

sub chopcode
{
    my ($dest, $dat, $offsets) = @_;
    my ($last) = $offsets->[-1];
    my ($i);

    for ($i = $#{$offsets} - 1; $i >= 0; $i--)
    {
        if ($offsets->[$i])
        {
            unshift(@{$dest}, substr($dat, $offsets->[$i], $last - $offsets->[$i]));
            $last = $offsets->[$i];
        }
        else
        { unshift(@{$dest}, ""); }
    }
}


sub read_pass
{
    my ($self, $fh, $offset, $base, $silf) = @_;
    my ($pass) = {};
    my ($d, $dat, $i, @orulemap, @oconstraints, @oactions, $numRanges);

    $fh->seek($offset + $base, 0);
    push (@{$silf->{'PASS'}}, $pass);
    $fh->read($dat, 40);
    ($pass->{'flags'}, $pass->{'maxRuleLoop'}, $pass->{'maxRuleContext'}, $pass->{'maxBackup'},
     $pass->{'numRules'}, $d, $d, $d, $d, $d, $pass->{'numRows'}, $pass->{'numTransitional'},
     $pass->{'numSuccess'}, $pass->{'numColumns'}, $numRanges) =
        TTF_Unpack("CCCCSSLLLLSSSSS", $dat);
    $fh->read($dat, $numRanges * 6);
    foreach $i (0 .. $numRanges - 1)
    {
        my ($first, $last, $col) = TTF_Unpack('SSS', substr($dat, $i * 6, 6));
        foreach ($first .. $last)
        { $pass->{'colmap'}{$_} = $col; }
    }
    $fh->read($dat, $pass->{'numSuccess'} * 2 + 2);
    @orulemap = unpack("n*", $dat);
    $fh->read($dat, $orulemap[-1] * 2);
    foreach (0 .. $pass->{'numSuccess'} - 1)
    { push (@{$pass->{'rulemap'}}, [unpack("n*", substr($dat, $orulemap[$_] * 2, ($orulemap[$_+1] - $orulemap[$_]) * 2))]); }
    $fh->read($dat, 2);
    ($pass->{'minRulePreContext'}, $pass->{'maxRulePreContext'}) = TTF_Unpack("CC", $dat);
    $fh->read($dat, ($pass->{'maxRulePreContext'} - $pass->{'minRulePreContext'} + 1) * 2);
    $pass->{'startStates'} = [unpack('n*', $dat)];
    $fh->read($dat, $pass->{'numRules'} * 2);
    $pass->{'ruleSortKeys'} = [unpack('n*', $dat)];
    $fh->read($dat, $pass->{'numRules'});
    $pass->{'rulePreContexts'} = [unpack('C*', $dat)];
    $fh->read($dat, 3);
    ($d, $pass->{'passConstraintLen'}) = TTF_Unpack("CS", $dat);
    $fh->read($dat, ($pass->{'numRules'} + 1) * 2);
    @oconstraints = unpack('n*', $dat);
    $fh->read($dat, ($pass->{'numRules'} + 1) * 2);
    @oactions = unpack('n*', $dat);
    foreach (0 .. $pass->{'numTransitional'} - 1)
    {
        $fh->read($dat, $pass->{'numColumns'} * 2);
        push (@{$pass->{'fsm'}}, [unpack('n*', $dat)]);
    }
    $fh->read($dat, 1);
    if ($pass->{'passConstraintLen'})
    { $fh->read($pass->{'passConstraintCode'}, $pass->{'passConstraintLen'}); }
    $fh->read($dat, $oconstraints[-1]);
    $pass->{'constraintCode'} = [];
    chopcode($pass->{'constraintCode'}, $dat, \@oconstraints);
    $fh->read($dat, $oactions[-1]);
    $pass->{'actionCode'} = [];
    chopcode($pass->{'actionCode'}, $dat, \@oactions);
    return $pass;
}

sub chopranges
{
    my ($map) = @_;
    my ($dat, $numRanges);
    my (@keys) = sort {$a <=> $b} keys %{$map};
    my ($first, $last, $col, $g);

    $first = -1;
    $last = -1;
    $col = -1;
    foreach $g (@keys)
    {
        if ($g != $last + 1 || $map->{$g} != $col)
        {
            if ($col != -1)
            {
                $dat .= pack("SSS", $first, $last, $col);
                $numRanges++;
            }
            $first = $last = $g;
            $col = $map->{$g};
        }
    }
    if ($col != -1)
    {
        $dat .= pack("SSS", $first, $last, $col);
        $numRanges++;
    }
    return ($numRanges, $dat);
}

sub packcode
{
    my ($code) = @_;
    my ($dat, $c, $res);

    foreach (@{$code})
    {
        if ($_)
        {
            push(@{$res}, $c);
            $dat .= $_;
            $c += length($_);
        }
        else
        { push(@{$res}, 0); }
    }
    push(@{$res}, $c);
    return ($res, $dat);
}

sub out_pass
{
    my ($self, $fh, $pass, $silf, $subbase) = @_;
    my (@orulemap, $dat, $actiondat, $numRanges, $c);
    my (@offsets, $res, $pbase);

    $pbase = $fh->tell();
    $fh->print(TTF_Pack("CCCCSSLLLLSSSS", $pass->{'flags'}, $pass->{'maxRuleLoop'}, $pass->{'maxRuleContext'},
                $pass->{'maxBackup'}, $pass->{'numRules'}, 24, 0, 0, 0, 0, $pass->{'numRows'},
                $pass->{'numTransitional'}, $pass->{'numSuccess'}, $pass->{'numColumns'}));
    ($numRanges, $dat) = chopranges($pass->{'colmap'});
    $fh->print(TTF_Pack("SSSS", TTF_bininfo($numRanges)));
    $fh->print($dat);
    $dat = "";
    $c = 0;
    foreach (@{$pass->{'rulemap'}})
    {
        push(@orulemap, $c);
        $dat .= pack("n*", @{$_});
        $c += @{$_};
    }
    push (@orulemap, $c);
    $fh->print(pack("n*", @orulemap));
    $fh->print($dat);
    $fh->print(TTF_Pack("CC", $pass->{'minRulePreContext'}, $pass->{'maxRulePreContext'}));
    $fh->print(pack("n*", @{$pass->{'startStates'}}));
    $fh->print(pack("n*", @{$pass->{'ruleSortKeys'}}));
    $fh->print(pack("C*", @{$pass->{'rulePreContexts'}}));
    $fh->print(TTF_Pack("CS", 0, $pass->{'passConstraintLen'}));
    my ($oconstraints, $dat) = packcode($pass->{'constraintCode'});
    my ($oactions, $actiondat) = packcode($pass->{'actionCode'});
    $fh->print(pack("n*", @{$oconstraints}));
    $fh->print(pack("n*", @{$oactions}));
    foreach (@{$pass->{'fsm'}})
    { $fh->print(pack("n*", @{$_})); }
    $fh->print(pack("C", 0));
    push(@offsets, $fh->tell() - $subbase);
    $fh->print($pass->{'passConstraintCode'});
    push(@offsets, $fh->tell() - $subbase);
    $fh->print($dat);
    push(@offsets, $fh->tell() - $subbase);
    $fh->print($actiondat);
    push(@offsets, 0);
    $res = $fh->tell();
    $fh->seek($pbase + 8, 0);
    $fh->print(pack("n*", @offsets));
    $fh->seek($res, 0);
}

=head2 out

Outputs a Silf data structure to a font file in binary format

=cut

sub out
{
    my ($self, $fh) = @_;
    my ($silf);

    return $self->SUPER::out($fh) unless ($self->{' read'});
    if ($self->{'Version'} >= 3)
    { $fh->print(TTF_Pack("vvSS", $self->{'Version'}, $self->{'Compiler'}, $#{$self->{'SILF'}} + 1, 0)); }
    else
    { $fh->print(TTF_Pack("vSS", $self->{'Version'}, $#{$self->{'SILF'}} + 1, 0)); }
    foreach $silf (@{$self->{'SILF'}})
    {
        my ($subbase) = $fh->tell();
        my ($numlin, $i, @opasses, $oPasses, $oPseudo, $ooPasses, $end);
        if ($self->{'Version'} > 3)
        { $fh->print(TTF_Pac("vSS", $silf->{'Version'}, $oPasses, $oPseudo)); }
        $fh->print(TTF_Pack("SssCCCCCCCCCCCCCC", 
             $silf->{'maxGlyphID'}, $silf->{'Ascent'}, $silf->{'Descent'},
             $silf->{'numPasses'}, $silf->{'substPass'}, $silf->{'posPass'}, $silf->{'justPass'}, $silf->{'bidiPass'},
             $silf->{'Flags'}, $silf->{'maxPreContext'}, $silf->{'maxPostContext'}, $silf->{'attrPseudo'},
             $silf->{'attrBreakWeight'}, $silf->{'attrDirectionality'}, 0, 0, $#{$silf->{'JUST'}} + 1));
        foreach (@{$silf->{'JUST'}})
        { $fh->print(TTF_Pack("CCCCCCCC", $_->{'attrStretch'}, $_->{'attrShrink'}, $_->{'attrStep'},
                        $_->{'attrWeight'}, $_->{'runto'}, 0, 0, 0)); }
        
        $fh->print(TTF_Pack("SCCCCCCCC", $silf->{'numLigComp'}, $silf->{'numUserAttr'}, $silf->{'maxCompPerLig'},
                        $silf->{'direction'}, 0, 0, 0, 0, $#{$silf->{'CRIT_FEATURE'}} + 1));
        $fh->print(pack("n*", @{$silf->{'CRIT_FEATURE'}}));
        $fh->print(TTF_Pack("CC", 0, $#{$silf->{'scripts'}} + 1));
        foreach (@{$self->{'scripts'}})
        { $fh->print(pack("a4", $_)); }
        $fh->print(TTF_Pack("S", $silf->{'lbGID'}));
        $ooPasses = $fh->tell();
        if ($silf->{'PASS'}) { $fh->print(pack("N*", (0) x @{$silf->{'PASS'}}));}
        my (@pskeys) = keys %{$silf->{'pseudos'}};
        $fh->print(TTF_Pack("SSSS", TTF_bininfo(scalar @pskeys)));
        $oPseudo = $fh->tell() - $subbase;
        foreach my $k (sort {$a <=> $b} @pskeys)
        { $fh->print(TTF_Pack("LS", $k, $silf->{'pseudos'}{$k})); }
        $numlin = -1;
        foreach (0 .. $#{$silf->{'classes'}})
        {
            if (scalar keys %{$silf->{'classes'}[$_]} > 8)  # binary search vs linear search crosses at 8 elements
            {
                $numlin = $_;
                last;
            }
        }
        $numlin = @{$silf->{'classes'}} if ($numlin < 0);
        $fh->print(TTF_Pack("SS", scalar @{$silf->{'classes'}}, $numlin));
        for ($i = 0; $i < $numlin; $i++)
        { $fh->print(pack("n*", sort {$silf->{'classes'}[$i]{$a} <=> $silf->{'classes'}[$i]{$b}} keys %{$silf->{'classes'}[$i]})); }
        for ($i = $numlin; $i < @{$silf->{'classes'}}; $i++)
        {
            foreach (sort {$a <=> $b} keys %{$silf->{'classes'}[$i]})
            { $fh->print(TTF_Pack("SS", $_, $silf->{'classes'}[$i]{$_})); }
        }
        $oPasses = $fh->tell() - $subbase;
        push (@opasses, $oPasses);
        foreach (@{$silf->{'PASS'}})
        { push(@opasses, $self->out_pass($fh, $_, $silf, $subbase) - $subbase); }
        $end = $fh->tell();
        $fh->seek($ooPasses, 0);
        $fh->print(pack("N*", @opasses));
        if ($self->{'Version'} >= 3)
        {
            $fh->seek($subbase + 4, 0);
            $fh->print(TTF_Pack("SS", $oPasses, $oPseudo));
        }
        $fh->seek($end, 0);
    }
}

sub XML_element
{
    my ($self, $context, $depth, $k, $val) = @_;
    my ($fh) = $context->{'fh'};
    my ($i);

    return $self if ($k eq 'LOC');

    if ($k eq 'classes')
    {
        $fh->print("$depth<classes>\n");
        foreach $i (0 .. @{$val})
        {
            $fh->printf("$depth    <class num='%d'>\n", $i);
            foreach (sort {$a <=> $b} keys %{$val->[$i]})
            { $fh->printf("%s        <glyph id='%d' index='%d'/>\n", $depth, $_, $val->[$i]{$_}); }
            $fh->print("$depth    </class>\n");
        }
        $fh->print("$depth</classes>\n");
    }
    elsif ($k eq 'fsm')
    {
        $fh->print("$depth<fsm>\n");
        foreach (@{$val})
        { $fh->print("$depth    <row>" . join(" ", @{$_}) . "</row>\n"); }
        $fh->print("$depth</fsm>\n");
    }
    elsif ($k eq 'colmap')
    {
        my ($i);
        $fh->print("$depth<colmap>");
        while (my ($k, $v) = each %{$val})
        {
            if ($i++ % 8 == 0)
            { $fh->print("\n$depth  "); }
            $fh->printf(" %d=%d", $k, $v);
        }
        $fh->print("\n$depth</colmap>\n");
    }
    else
    { return $self->SUPER::XML_element($context, $depth, $k, $val); }

    $self;
}

1;

