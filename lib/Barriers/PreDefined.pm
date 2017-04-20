package Barriers::PreDefined;

use strict;
use warnings;
use Moo;
use POSIX ();
use List::Util qw(min max first);
use List::MoreUtils qw(uniq);
use Math::CDF qw(qnorm);

our $VERSION = '0.10';

=head1 NAME

Barriers::PreDefined - A class to calculate a series of predefined barriers for a particular contract.


=head1 SYNOPSIS

    use Barriers::PreDefined;
    my $config = [{
            types         => [qw/CALLE PUT/],
            barrier_level => [95, 85, 75, 62, 50, 38, 25, 15, 5],
        },
        {
            types         => [qw/ONETOUCH NOTOUCH/],
            barrier_level => [95, 85, 75, 62, 38, 25, 15, 5],
        },
        {
            types         => [qw/EXPIRYMISS EXPIRYRANGEE/],
            barrier_level => [75, 95, 62, 85, 50, 75, 38, 62, 25, 50, 15, 38, 5, 25],

        },
        {
            types         => [qw/RANGE UPORDOWN/],
            barrier_level => [25, 75, 15, 85, 5, 95,]
        },
    ];
    my $barrier_class = Barriers::PreDefined->new(config => $config);
    my $available_barriers = $barrier_class->calculate_available_barriers({
         contract_type=>'CALLE',
         duration=> 8100,
         central_spot=>100.5,
         display_decimal=>2,
         method=>2,
         base_min_barrier_interval => 0.0005
    });

=head1 DESCRIPTION

This is a class to calculate a series of predefined barriers for a particular contract.

There are two available methods:

Method 1: (Unrounded version)

Steps:

1) Calculate the boundary barriers associated with a call at 5% and 95% probability.

2) Take the distance between the boundary barriers divide into 90 pieces which acts as the minimum_barrier_interval labeled as 'm'.

3) Build the barriers array from a central barrier[ which is the spot at the start of the window]. Barriers array are computed at a set number of barrier interval from the central spot:
   Example: If the barrier_interval are [95, 85, 75, 62, 50, 38, 25, 15, 5], the barriers_array will be build as follow:

   Barrier_1 (labeled as 95) : central_spot + 45 * m

   Barrier_2 (labeled as 85) : central_spot + 35 * m

   Barrier_3 (labeled as 75) : central_spot + 25 * m

   Barrier_4 (labeled as 62) : central_spot + 12 * m

   Barrier_5 (labeled as 50) :  central_spot

   Barrier_6 (labeled as 38) : central_spot - 12 * m

   Barrier_7 (labeled as 25) : central_spot - 25 * m

   Barrier_8 (labeled as 15) : central_spot - 35 * m

   Barrier_9 (labeled as 5) : central_spot - 45 * m

Method 2: (Rounded version)

Steps:
1) Calculate  minimum_barrier_interval labeled as 'm', depending on magnitude of central_spot in base 10

2) Round the central_spot to nearest minimum_interval_barrier which will be named as rounded_central_spot

3) Calculate the boundary barriers associated with a call at 5% and 95% probability.

4) Build the barriers array from rounded_central_spot. Barriers array are computed at a set number of barrier interval from the rounded_central_spot.

   Example: If the barrier_interval are [45, 28, 18, 7], the barriers_array will be build as follow:

   Barrier_1 : rounded_central_spot + 45 * m

   Barrier_2 : rounded_central_spot + 28 * m

   Barrier_3 : rounded_central_spot + 18 * m

   Barrier_4 : rounded_central_spot + 7 * m

   Barrier_5 : rounded_central_spot

   Barrier_6 : rounded_central_spot - 7 * m

   Barrier_7 : rounded_central_spot - 18 * m

   Barrier_8 : rounded_central_spot - 28 * m

   Barrier_9 : rounded_central_spot - 45 * m

5) Build the new barriers array with ensuring the minimum_barrier_interval is hold.

   Example: If the barrier_interval are [45, 28, 18, 7], the new_barrier will be build as follow:

   New_barrier_1 (labeled as 95) : max( round(barrier_1/m) * m, new_barrier_2 + m )

   New_barrier_2 (labeled as 78) : max( round(barrier_2/m) * m, new_barrier_3 + m )

   New_barrier_3 (labeled as 68) : max( round(barrier_3/m) * m, new_barrier_4 + m )

   New_barrier_4 (labeled as 57) : max( round(barrier_4/m) * m, new_barrier_5 + m )

   New_barrier_5 (labeled as 50) : rounded_central_spot

   New_barrier_6 (labeled as 43) : min( round(barrier_6/m) * m, new_barrier_5 - m )

   New_barrier_7 (labeled as 32) : min( round(barrier_7/m) * m, new_barrier_6 - m )

   New_barrier_8 (labeled as 22) : min( round(barrier_8/m) * m, new_barrier_7 - m )

   New_barrier_9 (labeled as 5)  : min( round(barrier_9/m) * m, new_barrier_8 - m )

6) Apply the barriers for each contract types as defined in config file:

   Example of config file:

   - Single_barrier_european_option: [95, 78, 68, 57, 50, 43, 32, 22, 5]

   - Single_barrier_american_option: [95, 78, 68, 57, 43, 32, 22, 5]

   - Double_barrier_european_option: [68, 95, 57, 78, 50, 68, 43, 57, 32, 50, 22, 43, 5, 32],

   - Double_barrier_american_option: [32, 68, 22, 78, 5, 95]

=cut

=head1 INPUT PARAMETERS

=head2 config

A configuration hashref that contains the selected barrier level for a contract type

=head2 contract_type

The contract type.

=head2 duration

The contract duration in seconds

=head2 central_spot

The spot at the start of the contract

=head2 display_decimal

The number of the display decimal point. Example 2 mean 0.01

=head2 method

The method for the barrier calculation, method_1 or method_2

=head2 base_min_barrier_interval

The base of the minimum barrier interval. The suggested base is 0.0005

=cut

=head2 _contract_barrier_levels

A set of barrier level that intended to obtain for a contract type

For example:
   - Single_barrier_european_option: [95, 78, 68, 57, 50, 43, 32, 22, 5]
   - Single_barrier_american_option: [95, 78, 68, 57, 43, 32, 22, 5]
   - Double_barrier_european_option: [68, 95, 57, 78, 50, 68, 43, 57, 32, 50, 22, 43, 5, 32],
   - Double_barrier_american_option: [32, 68, 22, 78, 5, 95]

The barrier level 78 is 28 * min_barrier_interval from the central spot, while 22 is -28 * min_barrier_interval from the central spot.

=cut

has _contract_barrier_levels => (
    is => 'rw',
);

has calculate_method_1 => (
    is         => 'rw',
    lazy_build => 1,
);

has calculate_method_2 => (
    is         => 'rw',
    lazy_build => 1,
);

=head2 BUILD

We unwrap the config to map the barrier_level correspond to the contract type

=cut

sub BUILD {
    my $self   = shift;
    my $args   = shift;
    my $config = $args->{config};
    my $contract_barrier_levels;
    for my $set (@$config) {
        for my $type (@{$set->{types}}) {
            $contract_barrier_levels->{$type} = $set->{barrier_level};
        }
    }

    $self->_contract_barrier_levels($contract_barrier_levels);
    return;
}

=head1 METHODS

=cut

=head2 calculate_available_barriers

A function to calculate available barriers for a contract type
Input_parameters: $contract_type, $duration, $central_spot, $display_decimal, $method, $base_min_barrier_interval

=cut

sub calculate_available_barriers {
    my $self = shift;
    my $args = shift;

    my ($contract_type, $duration, $central_spot, $display_decimal, $method, $base_min_barrier_interval) =
        @{$args}{qw(contract_type duration central_spot display_decimal method base_min_barrier_interval)};
    my $barriers_levels = $self->_contract_barrier_levels->{$contract_type};

    my $method_barrier_levels = $method eq '1' ? $barriers_levels : $self->_contract_barrier_levels->{'CALLE'};


    my $format           = '%.' . $display_decimal . 'f';
    my $calculate_method = $method eq '1' ? \&_calculate_method_1 : \&_calculate_method_2;
    my $barriers_list    = $calculate_method->($central_spot, $format, $duration, $method_barrier_levels, $base_min_barrier_interval);

    my $available_barriers = [map { sprintf $format, $barriers_list->{$_} } @{$barriers_levels}];

    return $available_barriers;
}

=head2 calculate_method_1

A function to build barriers array based on method 1
Input_parameters: $duration, $central_spot, $display_decimal, $barriers_levels

=cut

sub _calculate_method_1 {
    my ($central_spot, $format, $duration, $barriers_levels) = @_;

    my $tiy = $duration / (365 * 86400);
    my @initial_barriers            = map { _get_barrier_from_call_bs_price($_, $tiy, $central_spot, 0.1) } (0.05, 0.95);
    my $distance_between_boundaries = abs($initial_barriers[0] - $initial_barriers[1]);
    my $minimum_step                = sprintf($format, $distance_between_boundaries / 90);

    my %new_barriers = map { $_ => $central_spot + ($_ - 50) * $minimum_step } @$barriers_levels;

    return \%new_barriers;

}

=head2 calculate_method_2

A function to build barriers array based on method 2
Input_parameters: $duration, $central_spot, $display_decimal, $barriers_levels, $base_min_barrier_interval

=cut

sub _calculate_method_2 {

    my ($central_spot, $format, $duration, $barriers_levels, $base_min_barrier_interval) = @_;
    my $tiy = $duration / (365 * 86400);
    my @initial_barriers            = map { _get_barrier_from_call_bs_price($_, $tiy, $central_spot, 0.1) } (0.05, 0.95);
    my $distance_between_boundaries = abs($initial_barriers[0] - $initial_barriers[1]);
    my $minimum_step                = sprintf($format, $distance_between_boundaries / 90);
    my $rounding_to_integer         = '%0.f';

    my $minimum_barrier_interval = $base_min_barrier_interval * (10**(sprintf($rounding_to_integer, POSIX::log10($central_spot))));
    my $rounded_central_spot = sprintf($rounding_to_integer, ($central_spot / $minimum_barrier_interval)) * $minimum_barrier_interval;

    my @barriers_steps = @$barriers_levels;
    my @barriers_value = map { $rounded_central_spot + ($_ - 50) * $minimum_step } @barriers_steps;

    my $last_element = $#barriers_steps;
    my $central_point_index = first { $barriers_steps[$_] == 50 } 0 .. $last_element;

    my %new_barriers;
    $new_barriers{50} = $rounded_central_spot;

    # For the upper barrier, we are taking the max of rounded barrier(to the nearest min barrier interval) and the next new_barrier plus min barrier interval
    for (my $i = $central_point_index - 1; $i >= 0; $i--) {
        $new_barriers{$barriers_steps[$i]} =
            max((sprintf($rounding_to_integer, $barriers_value[$i] / $minimum_barrier_interval)) * $minimum_barrier_interval,
            $new_barriers{$barriers_steps[$i + 1]} + $minimum_barrier_interval);
    }

    # For the lower barrier, we are taking the min of rounded barrier(to the nearest min barrier interval) and the previous new_barrier minus min barrier interval
    for ($central_point_index + 1 .. $last_element) {
        $new_barriers{$barriers_steps[$_]} =
            min((sprintf($rounding_to_integer, $barriers_value[$_] / $minimum_barrier_interval)) * $minimum_barrier_interval,
            $new_barriers{$barriers_steps[$_ - 1]} - $minimum_barrier_interval);
    }

    return \%new_barriers;

}

=head2 _get_barrier_from_call_bs_price
To get the barrier that associated with a given call bs price.
=cut

sub _get_barrier_from_call_bs_price {
    my ($call_price, $T, $spot, $vol) = @_;

    my $q  = 0;
    my $r  = 0;
    my $d2 = qnorm($call_price * exp($r * $T));
    my $d1 = $d2 + $vol * sqrt($T);

    my $strike = $spot / exp($d1 * $vol * sqrt($T) - ($r - $q + ($vol * $vol) / 2) * $T);
    return $strike;
}

1;

