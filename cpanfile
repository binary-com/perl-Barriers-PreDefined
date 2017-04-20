requires 'Moo';
requires 'POSIX';
requires 'List::Util';
requires 'List::MoreUtils';
requires 'Math::CDF';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
};


on test => sub {
    requires 'Test::More';
    requires 'Test::Deep';
    requires 'Test::FailWarnings';
};

