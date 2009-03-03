#!/usr/bin/env perl
use strict;
use warnings;
use FindBin::libs;

use Encode;
use Perl6::Say;

use utf8;
use Text::Kgram;
use Encode qw/decode_utf8/;

use Path::Class qw/file/;
use IO::Handle;

use Algorithm::KgramIndex;

my $index = Algorithm::KgramIndex->new({
    edit_distance_threshold => 5
});

while (<>) {
    chomp;
    my ($kid, $word) = split /\t/;
    $index->add_keyword($kid => decode_utf8 $word);
}

while (1) {
    print "> ";

    my $q = STDIN->getline;
    chomp $q;

    my $res = $index->search( decode_utf8 $q );
    for ($res->extract_all) {
        say sprintf "%s, ED:%d", $_->{keyword}, $_->{edit_distance};
    }

    $res->clear;
}
