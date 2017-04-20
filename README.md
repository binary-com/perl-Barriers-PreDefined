# NAME

[![Build Status](https://travis-ci.org/binary-com/perl-Barriers-PreDefined.svg?branch=master)](https://travis-ci.org/binary-com/perl-Barriers-PreDefined)
[![codecov](https://codecov.io/gh/binary-com/perl-Barriers-PreDefined/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Barriers-PreDefined)


Barriers::PreDefined - A class to calculate a series of predefined barriers for a particular contract.

# SYNOPSIS

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

# DESCRIPTION

This is a class to calculate a series of predefined barriers for a particular contract.

There are two available methods:

Method 1: (Unrounded version)

Steps:

1) Calculate the boundary barriers associated with a call at 5% and 95% probability.

2) Take the distance between the boundary barriers divide into 90 pieces which acts as the minimum\_barrier\_interval labeled as 'm'.

3) Build the barriers array from a central barrier\[ which is the spot at the start of the window\]. Barriers array are computed at a set number of barrier interval from the central spot:
   Example: If the barrier\_interval are \[95, 85, 75, 62, 50, 38, 25, 15, 5\], the barriers\_array will be build as follow:

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
1) Calculate  minimum\_barrier\_interval labeled as 'm', depending on magnitude of central\_spot in base 10

2) Round the central\_spot to nearest minimum\_interval\_barrier which will be named as rounded\_central\_spot

3) Calculate the boundary barriers associated with a call at 5% and 95% probability.

4) Build the barriers array from rounded\_central\_spot. Barriers array are computed at a set number of barrier interval from the rounded\_central\_spot.

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

5) Build the new barriers array with ensuring the minimum\_barrier\_interval is hold.

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

# INPUT PARAMETERS

## config

A configuration hashref that contains the selected barrier level for a contract type

## contract\_type

The contract type.

## duration

The contract duration in seconds

## central\_spot

The spot at the start of the contract

## display\_decimal

The number of the display decimal point. Example 2 mean 0.01

## method

The method for the barrier calculation, method\_1 or method\_2

## base\_min\_barrier\_interval

The base of the minimum barrier interval. The suggested base is 0.0005

## \_contract\_barrier\_levels

A set of barrier level that intended to obtain for a contract type

For example:
   - Single\_barrier\_european\_option: \[95, 78, 68, 57, 50, 43, 32, 22, 5\]
   - Single\_barrier\_american\_option: \[95, 78, 68, 57, 43, 32, 22, 5\]
   - Double\_barrier\_european\_option: \[68, 95, 57, 78, 50, 68, 43, 57, 32, 50, 22, 43, 5, 32\],
   - Double\_barrier\_american\_option: \[32, 68, 22, 78, 5, 95\]

The barrier level 78 is 28 \* min\_barrier\_interval from the central spot, while 22 is -28 \* min\_barrier\_interval from the central spot.

## BUILD

We unwrap the config to map the barrier\_level correspond to the contract type

# METHODS

## calculate\_available\_barriers

A function to calculate available barriers for a contract type
Input\_parameters: $contract\_type, $duration, $central\_spot, $display\_decimal, $method, $base\_min\_barrier\_interval

## calculate\_method\_1

A function to build barriers array based on method 1
Input\_parameters: $duration, $central\_spot, $display\_decimal, $barriers\_levels

## calculate\_method\_2

A function to build barriers array based on method 2
Input\_parameters: $duration, $central\_spot, $display\_decimal, $barriers\_levels, $base\_min\_barrier\_interval

## \_get\_barrier\_from\_call\_bs\_price
To get the barrier that associated with a given call bs price.
