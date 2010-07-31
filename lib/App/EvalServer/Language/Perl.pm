package App::EvalServer::Language::Perl;

use strict;
use warnings;

=pod

# TODO: attempt to load the utf8/unicode libraries.
use utf8;
use charnames qw(:full);
BEGIN {
    eval "\$\343\201\257 = 42";
    uc "\x{666}";
}

=cut

sub evaluate {
    my ($package, $code) = @_;

    local $@   = undef;
    local @INC = undef;
    local $_   = undef;

    $code = "no strict; no warnings; package main; $code";
    my $ret = eval $code;

    print STDERR $@ if length($@);
    return $ret;
}

1;

=encoding utf8

=head1 NAME

App::EvalServer::Language::Perl - Evaluate Perl code

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
