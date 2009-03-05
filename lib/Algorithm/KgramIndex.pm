package Algorithm::KgramIndex;
use strict;
use warnings;
use base qw/Class::Accessor::Lvalue::Fast/;

__PACKAGE__->mk_accessors(qw/index kgram bigram_count string_metrics_threshold lexicon df total_df/);

use Heap::Simple::XS;
use Params::Validate qw/validate_pos/;

use Text::Kgram;
# use Algorithm::Levenshtein qw/distance/;
use Text::JaroWinkler qw/distance/;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->index = {};
    $self->df    = {};
    # $self->lexicon      = {};
    # $self->bigram_count = {};
    $self->kgram  = Text::Kgram->new({ K => 2 });
    $self->string_metrics_threshold ||= 0;

    return $self;
}

sub add_term {
    my ($self, $term, $df) = validate_pos(@_, 1, 1, 1);
    my @tokens = $self->kgram->tokenize(lc $term);

    # if (not exists $self->bigram_count->{$id}) {
    #    $self->bigram_count->{$id} = scalar @tokens;
    # }

    $self->df->{$term} = $df;

    for (@tokens) {
        my $postings = $self->index->{$_} ||= [];
        push @$postings, $term;
    }
}

sub search {
    my ($self, $q) = @_;
    my @result;
    my @query_tokens = $self->kgram->tokenize(lc $q);

    my $number_of_bigrams_in_query = scalar @query_tokens;
    my $number_of_postings_hits    = 0;

    my %seen;
    for (@query_tokens) {
        if (my $postings = $self->index->{$_}) {
            my $got;

            ## intersection
            for my $term (@$postings) {
                # if (lc substr($q, 0, 1) ne lc substr($term, 0, 1)) {
                #     next;
                # }

                if ($q eq $term) {
                    next;
                }

                $seen{$term}++;

                ## query が 2 文字の場合は bigram が 1 つしかない
                ## その場合は共起は考えない
                if (@query_tokens == 1) {
                    if ($seen{$term} == 1) {
                        push @result, $term;
                        $got = 1;
                    }
                } else {
                    if ($seen{$term} == 2) {
                        push @result, $term;
                        $got = 1;
                    }
                }
            }

            if ($got) {
                $number_of_postings_hits++;
            }
        }
    }

    my $heap = Heap::Simple::XS->new(
        elements => "Any",
        # order    => "<",
        order    => ">",
    );

    # warn sprintf "[debug] num postings hits: %d\n", $number_of_postings_hits;
    # warn sprintf "[debug] num bigrams in query: %d\n", $number_of_bigrams_in_query;

    for (@result) {
        ## calc Jaccard coefficient (hmm)
        # my $jc = $number_of_postings_hits /
        #    ($self->bigram_count->{$_->[TERM]} + $number_of_bigrams_in_query - $number_of_postings_hits);

        my $res = {
            term     => $_,
            distance => distance(lc $q, lc $_),
        };

        if ( $res->{distance} >= $self->string_metrics_threshold ) {
            $res->{df}    = $self->df->{$_} + 1,
            $res->{idf}   = log($self->total_df/$res->{df}),
            $res->{score} = $res->{distance} * (1 / $res->{idf});

            $heap->key_insert($res->{score} , $res);
        }
    }

    return $heap;
}

1;
