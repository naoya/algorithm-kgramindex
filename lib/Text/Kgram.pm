package Text::Kgram;
use strict;
use warnings;
use base qw/Class::Accessor::Lvalue::Fast/;

use Params::Validate qw/validate_pos/;

__PACKAGE__->mk_accessors(qw/K/);

sub new {
    my ($class, $args) = validate_pos(@_, 1, { default => {} });
    my $self = $class->SUPER::new;
    $self->K = $args->{K} || 2;
    return $self;
}

sub tokenize {
    my $self = shift;
    my $str  = shift or return;
    my @chars = split //, $str;
    my @kgrams;
    for (0..@chars - $self->K) {
        my $token = '';
        for (my $i = 0; $i < $self->K; $i++) {
            $token .= $chars[$_ + $i]
        }
        push @kgrams, $token;
    }
    return @kgrams;
}

1;
