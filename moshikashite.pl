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
    string_metrics_threshold => 0.8,
    total_df                 => 12_382_045,
});

while (<>) {
    chomp;
    my ($term, $df) = split /\t/;
    $index->add_term(decode_utf8($term), $df);
}

while (1) {
    print "> ";

    my $q = STDIN->getline;
    chomp $q;

    my $res = $index->search( decode_utf8 $q );
    for (my $i = 0; $i < 30; $i++) {
        my $p = $res->extract_first or last;

        say sprintf(
            "%s, dist:%f, df: %d, idf: %f, score: %f",
            $p->{term},
            $p->{distance},
            $p->{df},
            $p->{idf},
            $p->{score}
        );
    }

    $res->clear;
}
