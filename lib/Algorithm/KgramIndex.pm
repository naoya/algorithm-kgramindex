package Algorithm::KgramIndex;
use strict;
use warnings;
use base qw/Class::Accessor::Lvalue::Fast/;

__PACKAGE__->mk_accessors(qw/index kgram bigram_count edit_distance_threshold lexicon/);

use Heap::Simple::XS;
use Params::Validate qw/validate_pos/;

use Text::Kgram;
use Algorithm::Levenshtein qw/distance/;

use constant TERM          => 0;
use constant EDIT_DISTANCE => 1;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->index        = {};
    # $self->lexicon      = {};
    # $self->bigram_count = {};
    $self->kgram        = Text::Kgram->new({ K => 2 });
    $self->edit_distance_threshold ||= 5;

    return $self;
}

sub add_keyword {
    my ($self, $id, $keyword) = validate_pos(@_, 1, 1, 1);
    my @tokens = $self->kgram->tokenize(lc $keyword);
    for (@tokens) {
        my $postings = $self->index->{$_} ||= [];

        # if (not exists $self->bigram_count->{$id}) {
        #    $self->bigram_count->{$id} = scalar @tokens;
        # }

        push @$postings, $keyword;
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
                if (lc substr($q, 0, 1) ne lc substr($term, 0, 1)) {
                    next;
                }

                if ($q eq $term) {
                    next;
                }

                $seen{$term}++;

                if ($seen{$term} == 2) {
                    push @result, $term;
                    $got = 1;
                }
            }

            if ($got) {
                $number_of_postings_hits++;
            }
        }
    }

    my $heap = Heap::Simple::XS->new(
        elements => "Any",
        order    => "<",
    );

    # warn sprintf "[debug] num postings hits: %d\n", $number_of_postings_hits;
    # warn sprintf "[debug] num bigrams in query: %d\n", $number_of_bigrams_in_query;

    for (@result) {
        ## calc Jaccard coefficient (hmm)
        # my $jc = $number_of_postings_hits /
        #    ($self->bigram_count->{$_->[TERM]} + $number_of_bigrams_in_query - $number_of_postings_hits);

        ## Levenshtein distance
        my $res = {
            keyword       => $_,
            edit_distance => distance(lc $q, lc $_),
        };
        if ( $res->{edit_distance} <= $self->edit_distance_threshold ) {
            $heap->key_insert($res->{edit_distance}, $res);
        }
    }

    return $heap;
}

1;
