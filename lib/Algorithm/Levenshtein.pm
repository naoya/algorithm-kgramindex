package Algorithm::Levenshtein;
use strict;
use warnings;
use Exporter::Lite;

our @EXPORT_OK = qw/distance/;

use List::Util qw/min/;
use Params::Validate qw/validate_pos/;

sub distance {
    my ($s1, $s2) = validate_pos(@_, 1, 1);
    my $m = [];

    my @s1 = split //, $s1;
    my @s2 = split //, $s2;

    for (my $i = 0; $i <= @s1; $i++) {
        $m->[$i]->[0] = $i;
    }

    for (my $j = 0; $j <= @s2; $j++) {
        $m->[0]->[$j] = $j;
    }

    for (my $i = 1; $i <= @s1; $i++) {
        for (my $j = 1; $j <= @s2; $j++) {
            my $diff = ($s1[ $i - 1 ] eq $s2[ $j - 1]) ? 0 : 1;
            $m->[$i]->[$j] = min(
                $m->[$i - 1]->[$j - 1] + $diff,
                $m->[$i - 1]->[$j] + 1,
                $m->[$i]->[$j - 1] + 1
            );
        }
    }

    return $m->[-1]->[-1];
}

1;
