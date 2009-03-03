#!/usr/bin/env perl
use strict;
use warnings;
use FindBin::libs;

use Perl6::Say;
use Encode qw/from_to/;

while (<>) {
    chomp;
    from_to($_, "euc-jp", "utf8");
    my ($kana, $word, $kid) = split /\t/;
    say sprintf "%d\t%s", $kid, $word;
}
