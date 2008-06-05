use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;

BEGIN { use_ok('Data::Pairs') };

my( $pairs, %pairs, @keys, @values, $bool, $key, $value, @a );

Data::Pairs->order( '' );  # ordering is class-level, turn off for now

$pairs = tie %pairs, 'Data::Pairs';

is( Dumper($pairs), "bless( [], 'Data::Pairs' )",
    "empty tied object" );

# empty %pairs

eval { @keys = keys %pairs; };  # via FIRSTKEY/NEXTKEY
like( $@, qr/This operation is not supported/,
    "keys %hash, expected to croak, FIRSTKEY/NEXTKEY not supported" );

eval { @values = values %pairs; };  # via FIRSTKEY/NEXTKEY
like( $@, qr/This operation is not supported/,
    "values %hash, expected to croak, FIRSTKEY/NEXTKEY not supported" );

$bool = %pairs;   # SCALAR
is( $bool, undef,
    "scalar %hash on empty object" );

$bool = exists $pairs{ a };  # EXISTS
is( $bool, '',
    "exists hash{key} on empty object" );

$value = $pairs{ a };  # FETCH
is( $value, undef,
    "hash{key} (FETCH) on empty object" );

delete $pairs{ a };  # DELETE
is( Dumper($pairs), "bless( [], 'Data::Pairs' )",
    "delete hash{key} on empty object" );

%pairs = ();  # CLEAR
is( Dumper($pairs), "bless( [], 'Data::Pairs' )",
    "%hash = () to clear empty object" );

# non-empty %pairs

$pairs{ z } = 26;  # STORE
$pairs{ y } = 25;
is( Dumper($pairs), "bless( [{'z' => 26},{'y' => 25}], 'Data::Pairs' )",
    "hash{key}=value" );

$bool = exists $pairs{ z };
is( $bool, 1,
    "exists hash{key}" );

$value = $pairs{ z };
is( $value, 26,
    "value=hash{key}" );

@values = @pairs{ 'y', 'z' };
is( "@values", "25 26",
    "values=\@hash{key,key} (get slice)" );

@pairs{ 'y', 'z' } = ( "Why", "Zee" );
is( Dumper($pairs), "bless( [{'z' => 'Zee'},{'y' => 'Why'}], 'Data::Pairs' )",
    "\@hash{key,key}=values (set slice)" );

delete $pairs{ z };
is( Dumper($pairs), "bless( [{'y' => 'Why'}], 'Data::Pairs' )",
    "delete hash{key}" );

eval { ( $key, $value ) = each %pairs; };
like( $@, qr/This operation is not supported/,
    "each %hash, expected to croak, FIRSTKEY/NEXTKEY not supported" );

@pairs{ 'a', 'b', 'c' } = ( 1, 2, 3 );
$bool = %pairs;
is( $bool, 4,
    "scalar %hash" );

%pairs = ();  # CLEAR
is( Dumper($pairs), "bless( [], 'Data::Pairs' )",
    "%hash = () to clear hash" );

my $warning;
local $SIG{ __WARN__ } = sub{ ($warning) = @_ };
untie %pairs;
like( $warning, qr/untie attempted while 1 inner references still exist/,
    "expected untie warning (object still in scope)" );
is( Dumper($pairs), "bless( [], 'Data::Pairs' )",
    "(empty) object is still visible" );

