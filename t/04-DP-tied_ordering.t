use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;

BEGIN { use_ok('Data::Pairs') };

my( $pairs, %pairs, @keys, @values, $bool, $key, $value, @a );

$pairs = tie %pairs, 'Data::Pairs';

Data::Pairs->order( 'sa' );  # string ascending

$pairs{ z } = 26;
$pairs{ y } = 25;
$pairs{ x } = 24;
is( Dumper($pairs), "bless( [{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Pairs' )",
    "hash{key}=value, ordering 'sa'" );

$pairs{ a } = 1;
is( Dumper($pairs), "bless( [{'a' => 1},{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Pairs' )",
    "hash{key}=value, ordering 'sa'" );

Data::Pairs->order( '' );  # turn ordering off

$pairs{ b } = 2;
is( Dumper($pairs), "bless( [{'a' => 1},{'x' => 24},{'y' => 25},{'z' => 26},{'b' => 2}], 'Data::Pairs' )",
    "hash{key}=value, no ordering" );

%pairs = ();
Data::Pairs->order( 'sa' );  # string ascending turned on again

$pairs{ 100 } = 'hundred';
$pairs{ 10  } = 'ten';
$pairs{ 2   } = 'two';
is( Dumper($pairs), "bless( [{'10' => 'ten'},{'100' => 'hundred'},{'2' => 'two'}], 'Data::Pairs' )",
    "hash{key}=value, ordering 'sa'" );

$pairs{ 1 } = 'one';
is( Dumper($pairs), "bless( [{'1' => 'one'},{'10' => 'ten'},{'100' => 'hundred'},{'2' => 'two'}], 'Data::Pairs' )",
    "hash{key}=value, ordering 'sa'" );

%pairs = ();
Data::Pairs->order( 'na' );  # number ascending

$pairs{ 100 } = 'hundred';
$pairs{ 10  } = 'ten';
$pairs{ 2   } = 'two';
is( Dumper($pairs), "bless( [{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'}], 'Data::Pairs' )",
    "hash{key}=value, ordering 'na'" );

$pairs{ 1 } = 'one';
is( Dumper($pairs), "bless( [{'1' => 'one'},{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'}], 'Data::Pairs' )",
    "hash{key}=value, ordering 'na'" );

%pairs = ();
Data::Pairs->order( 'sd' );  # string descending

$pairs{ x } = 24;
$pairs{ y } = 25;
$pairs{ z } = 26;
is( Dumper($pairs), "bless( [{'z' => 26},{'y' => 25},{'x' => 24}], 'Data::Pairs' )",
    "hash{key}=value, ordering 'sd'" );

$pairs{ a } = 1;
is( Dumper($pairs), "bless( [{'z' => 26},{'y' => 25},{'x' => 24},{'a' => 1}], 'Data::Pairs' )",
    "hash{key}=value, ordering 'sd'" );

%pairs = ();

$pairs{ 2   } = 'two';  # order still 'sd'
$pairs{ 10  } = 'ten';
$pairs{ 100 } = 'hundred';
is( Dumper($pairs), "bless( [{'2' => 'two'},{'100' => 'hundred'},{'10' => 'ten'}], 'Data::Pairs' )",
    "hash{key}=value, ordering 'sd'" );

$pairs{ 1 } = 'one';
is( Dumper($pairs), "bless( [{'2' => 'two'},{'100' => 'hundred'},{'10' => 'ten'},{'1' => 'one'}], 'Data::Pairs' )",
    "hash{key}=value, ordering 'sd'" );

%pairs = ();
Data::Pairs->order( 'nd' );  # number descending

$pairs{ 2   } = 'two';
$pairs{ 10  } = 'ten';
$pairs{ 100 } = 'hundred';
is( Dumper($pairs), "bless( [{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'}], 'Data::Pairs' )",
    "hash{key}=value, ordering 'nd'" );

$pairs{ 1 } = 'one';
is( Dumper($pairs), "bless( [{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'},{'1' => 'one'}], 'Data::Pairs' )",
    "hash{key}=value, ordering 'nd'" );

%pairs = ();
Data::Pairs->order( 'sna' );  # string/number ascending
$pairs{ z } = 26;
$pairs{ y } = 25;
$pairs{ x } = 24;  # set and add are the same for new key/value members
$pairs{ 100 } = 'hundred';
$pairs{ 10  } = 'ten';
$pairs{ 2   } = 'two';
is( Dumper($pairs), "bless( [{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'},{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Pairs' )",
    "hash{key}=value, ordering 'sna'" );

%pairs = ();
Data::Pairs->order( 'snd' );  # string/number descending
$pairs{ x } = 24;  # set and add are the same for new key/value members
$pairs{ y } = 25;
$pairs{ z } = 26;
$pairs{ 2   } = 'two';
$pairs{ 10  } = 'ten';
$pairs{ 100 } = 'hundred';
is( Dumper($pairs), "bless( [{'z' => 26},{'y' => 25},{'x' => 24},{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'}], 'Data::Pairs' )",
    "hash{key}=value, ordering 'snd'" );

%pairs = ();
Data::Pairs->order( sub{ int($_[0]/100) < int($_[1]/100) } );  # custom ordering
$pairs{ 550 } = "note";
$pairs{ 500 } = "note";
$pairs{ 510 } = "note";
$pairs{ 650 } = "subj";
$pairs{ 600 } = "subj";
$pairs{ 610 } = "subj";
$pairs{ 245 } = "title";
$pairs{ 100 } = "author";
is( Dumper($pairs), "bless( [{'100' => 'author'},{'245' => 'title'},{'550' => 'note'},{'500' => 'note'},{'510' => 'note'},{'650' => 'subj'},{'600' => 'subj'},{'610' => 'subj'}], 'Data::Pairs' )",
    "hash{key}=value, custom ordering" );

