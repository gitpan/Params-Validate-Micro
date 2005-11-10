package Params::Validate::Micro;

use strict;
use warnings;
use Params::Validate qw(:all);
use Scalar::Util qw(reftype);
use Carp qw(croak);

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = (
  all => [qw(micro_validate micro_translate)],
);
our @EXPORT_OK = (@{ $EXPORT_TAGS{all} });

=head1 NAME

Params::Validate::Micro - Validate parameters concisely

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use Params::Validate::Micro qw(:all);
  use Params::Validate::Micro qw(micro_validate micro_translate);

=head1 DESCRIPTION

Params::Validate::Micro allows you to concisely represent a
list of arguments, their types, and whether or not they are
required.

Nothing is exported by default.  Use C<< :all >> or the
specific function name you want.

=head1 FORMAT

Micro argument strings are made up of lists of parameter
names.  Each name may have an optional sigil (one of C<< $@%
>>), which translate directly to the Params::Validate
constrations of SCALAR, ARRAYREF, and HASHREF, respectively.

There may be one semicolon (C<< ; >>) in your argument
string.  If present, any parameters listed after the
semicolon are marked as optional.

Examples:

=over 4

=item Single scalar argument

  $text

=item Hashref and optional scalar

  %opt; $verbose

=item Two arrayrefs and an untyped argument

  @addrs @lines message

=back

=head1 FUNCTIONS

=head3 C<< micro_translate >>

  my %spec = micro_translate($string);

Turns C<< $string >> into a Params::Validate spec as
described in L</FORMAT>.

This returns a list, which just happens to be a set of key
=> value pairs.  This matters because it means that if you
wanted to you could treat it as an array for long enough to
figure out what order the parameters were specified in.

In the future, this will probably lead to some kind of dual
named / positional validation.

=head3 C<< micro_validate >>

  my $arg = micro_validate(\@_, $string, $extra);

First, uses C<< micro_translate >> on C<< $string >>, then
merges the resultant spec and the optional C<< $extra >>
hashref, and passes the whole thing to Params::Validate.

Returns a hashref of the validated arguments.

=cut

my $BARE_VAR  = qr/[a-z_]\w+/i;

my $SIGIL_VAR = qr/[%\$\@]?$BARE_VAR/i;

my $EXTRACT_VARS = qr/\A 
                      (
                        $SIGIL_VAR
                        (?: 
                          (?: \s* ;)? 
                          \s+ $SIGIL_VAR
                        )*
                      )
                      /x;

my %PVSPEC = (
  '%' => {
    type => HASHREF,
  },
  '@' => {
    type => ARRAYREF,
  },
  '$' => {
    type => SCALAR,
  },
);

my ($SIGIL) = map { qr/$_/ } '[' . join("", keys %PVSPEC) . ']';

sub micro_translate {
  my ($string) = @_;
  my @vspecs = map {
    # make sure that semicolons are their own 'word'
    s/;/ ; /g;
    split /\s+/;
  } $string =~ $EXTRACT_VARS;
  croak "'$string' does not appear to be a micro-spec"
    unless @vspecs;

  my $optional;
  my %spec;
  for my $vspec (@vspecs) {
    if ($vspec eq ';') {
      if ($optional++) {
        croak "micro-spec '$string' contains multiple semicolons";
      }
      next;
    }
    my $vname = $vspec;
    my $spart = {};
    while ($vname =~ s/^($SIGIL)//) {
      my $sigil = $1;
      $spart = { %$spart, %{$PVSPEC{$sigil} || {}} };
    }
    unless ($vname =~ /\A$BARE_VAR\z/) {
      croak "illegal parameter name: '$vname'";
    }
    if ($optional) {
      $spart->{optional} = 1;
    }
    $spec{$vname} = $spart;
  }

  return %spec;
}

sub micro_validate {
  my ($args, $string, $extra) = @_;
  unless ($args and reftype($args) eq 'ARRAY') {
    croak "first argument to micro_validate must be arrayref";
  }
  $string ||= "";
  $extra  ||= {};
  my $spec = { micro_translate($string) };
  return {
    validate_with(
      params => $args,
      spec   => {
        %$spec,
        %$extra,
      },
    )
  };
}

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-params-validate-micro@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Validate-Micro>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Params::Validate::Micro
