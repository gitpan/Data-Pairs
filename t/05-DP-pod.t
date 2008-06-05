use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;

BEGIN { use_ok('Data::Pairs') };

SYNOPSIS_simple: {
 
=head1 SYNOPSIS

 use Data::Pairs;
 
 # Simple OO style
 
 my $pairs = Data::Pairs->new( [{a=>1},{b=>2},{c=>3},{b=>4}] );
 
 $pairs->set( a => 0 );
 $pairs->add( b2 => 2.5, 2 );  # insert at position 2 (between b and c)
 
 my $value  = $pairs->get_values( 'c' );    # 3
 my @keys   = $pairs->get_keys();           # (a, b, b2, c, b)
 my @values = $pairs->get_values();         # (0, 2, 2.5, 3, 4)
 my @subset = $pairs->get_values(qw(c b));  # (2, 3, 4) (values are data-ordered)
 
=cut

 my $pairs = Data::Pairs->new( [{a=>1},{b=>2},{c=>3},{b=>4}] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2},{'c' => 3},{'b' => 4}], 'Data::Pairs' )",
    "new()" );
 
 $pairs->set( a => 0 );

is( Dumper($pairs), "bless( [{'a' => 0},{'b' => 2},{'c' => 3},{'b' => 4}], 'Data::Pairs' )",
    "set( a => 0 )" );

 $pairs->add( b2 => 2.5, 2 );  # insert at position 2 (between b and c)
 
is( Dumper($pairs), "bless( [{'a' => 0},{'b' => 2},{'b2' => '2.5'},{'c' => 3},{'b' => 4}], 'Data::Pairs' )",
    "add( b2 => 2.5, 2 )" );

 my $value  = $pairs->get_values( 'c' );    # 3

is( $value, 3, "get_values( 'c' )" );

 my @keys   = $pairs->get_keys();           # (a, b, b2, c, b)

is( "@keys", "a b b2 c b", "get_keys()" );

 my @values = $pairs->get_values();         # (0, 2, 2.5, 3, 4)

is( "@values", "0 2 2.5 3 4", "get_values()" );

 my @subset = $pairs->get_values(qw(c b));  # (2, 3, 4) (values are data-ordered)

is( "@subset", "2 3 4", "get_values(qw(c b ))" );

}

SYNOPSIS_tied: {
 
=pod

 # Tied style
 
 my %pairs;
 # recommend saving an object reference, too.
 my $pairs = tie %pairs, 'Data::Pairs', [{a=>1},{b=>2},{c=>3},{b=>4}];
 
 $pairs{ a } = 0;
 $pairs->add( b2 => 2.5, 2 );  # there's no tied hash equivalent
 
 my $value  = $pairs{ c };
 my @slice  = @pairs{qw(c b)};  # (3, 2) (slice values are parameter-ordered)

 # re: keys %pairs;    # not supported, use $pairs->get_keys()
 # re: values %pairs;  # not supported, use $pairs->get_values()
 # re: each %pairs;    # not supported, use $pairs->get_keys()/get_values()
 
 # There are more methods/options, see below.

=cut
     # Tied style
 
 my %pairs;
 my $pairs = tie %pairs, 'Data::Pairs', [{a=>1},{b=>2},{c=>3},{b=>4}];
 
is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2},{'c' => 3},{'b' => 4}], 'Data::Pairs' )",
    "tie %pairs" );
 
 $pairs{ a } = 0;

is( Dumper($pairs), "bless( [{'a' => 0},{'b' => 2},{'c' => 3},{'b' => 4}], 'Data::Pairs' )",
    "$pairs{ a } = 0" );
 
 $pairs->add( b2 => 2.5, 2 );  # there's no tied hash equivalent
 
is( Dumper($pairs), "bless( [{'a' => 0},{'b' => 2},{'b2' => '2.5'},{'c' => 3},{'b' => 4}], 'Data::Pairs' )",
    "add( b2 => 2.5, 2 )" );

 my $value  = $pairs{ c };

is( $value, 3, "\$pairs{ c }" );

 my @slice  = @pairs{qw(c b)};  # (3, 2) (slice values are parameter-ordered)

is( "@slice", "3 2", "\@pairs{qw(c b)}" );

}


CLASS_new: {

=head2 Data::Pairs->new();

Constructs a new Data::Pairs object.

Accepts array ref containing single-key hash refs, e.g.,

 my $pairs = Data::Pairs->new( [ { a => 1 }, { b => 2 }, { c => 3 }, { b => 4 } ] );

When provided, this data will be loaded into the object.

Returns a reference to the Data::Pairs object.

=cut

 my $pairs = Data::Pairs->new( [ { a => 1 }, { b => 2 }, { c => 3 }, { b => 4 } ] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2},{'c' => 3},{'b' => 4}], 'Data::Pairs' )",
    "new()" );

}

CLASS_order: {

=head2 Data::Pairs->order();

When ordering is ON, new key/value pairs will be added in the
specified order.  When ordering is OFF (the default), new pairs
will be added to the end of the mapping.

When called with no parameters, C<order()> returns the current code
reference (if ordering is ON) or a false value (if ordering is OFF);
it does not change the ordering.

 Data::Pairs->order();         # leaves ordering as is

When called with the null string, C<''>, ordering is turned OFF.

 Data::Pairs->order( '' );     # turn ordering OFF (the default)

Otherwise, accepts the predefined orderings: 'na', 'nd', 'sa', 'sd',
'sna', and 'snd', or a custom code reference, e.g.

 Data::Pairs->order( 'na' );   # numeric ascending
 Data::Pairs->order( 'nd' );   # numeric ascending
 Data::Pairs->order( 'sa' );   # string  ascending
 Data::Pairs->order( 'sd' );   # string  descending
 Data::Pairs->order( 'sna' );  # string/numeric ascending
 Data::Pairs->order( 'snd' );  # string/numeric descending
 Data::Pairs->order( sub{ int($_[0]/100) < int($_[1]/100) } );  # code

The predefined orderings, 'na' and 'nd', compare keys as numbers.
The orderings, 'sa' and 'sd', compare keys as strings.  The
orderings, 'sna' and 'snd', compare keys as numbers when they are
both numbers, as strings otherwise.

When defining a custom ordering, the convention is to use the
operators C<< < >> or C<lt> between (functions of) C<$_[0]> and
C<$_[1]> for ascending and between C<$_[1]> and C<$_[0]> for
descending.

Returns the code reference if ordering is ON, a false value if OFF.

Note, when object-level ordering is implemented, it is expected that
the class-level option will still be available.  In that case, any
new objects will inherite the class-level ordering unless overridden
at the object level.

=cut

 Data::Pairs->order();         # leaves ordering as is

is( Data::Pairs->order(), undef, "order()" );

 Data::Pairs->order( '' );     # turn ordering OFF (the default)

is( Data::Pairs->order(), '', "order( '' )" );

 Data::Pairs->order( 'na' );   # numeric ascending

is( ref(Data::Pairs->order()), 'CODE', "order( 'na' )" );

 Data::Pairs->order( 'nd' );   # numeric ascending

is( ref(Data::Pairs->order()), 'CODE', "order( 'nd' )" );

 Data::Pairs->order( 'sa' );   # string  ascending

is( ref(Data::Pairs->order()), 'CODE', "order( 'sa' )" );

 Data::Pairs->order( 'sd' );   # string  descending

is( ref(Data::Pairs->order()), 'CODE', "order( 'sd' )" );

 Data::Pairs->order( 'sna' );  # string/numeric ascending

is( ref(Data::Pairs->order()), 'CODE', "order( 'sna' )" );

 Data::Pairs->order( 'snd' );  # string/numeric descending

is( ref(Data::Pairs->order()), 'CODE', "order( 'snd' )" );

 Data::Pairs->order( sub{ int($_[0]/100) < int($_[1]/100) } );  # code

is( ref(Data::Pairs->order()), 'CODE', "custom order()" );

}

OBJECT_set: {

=head2 $pairs->set( $key => $value[, $pos] );

Sets the value if C<$key> exists; adds a new key/value pair if not.

Accepts C<$key>, C<$value>, and optionally, C<$pos>.

If C<$pos> is given, and there is a key/value pair at that position,
it will be set to C<$key> and C<$value>, I<even if the key is
different>.  For example:

 my $pairs = Data::Pairs->new( [{a=>1},{b=>2}] );
 $pairs->set( c => 3, 0 );  # pairs is now [{c=>3},{b=>2}]

(As implied by the example, positions start at 0.)

If C<$pos> is given, and there isn't a pair there, a new pair is
added there (perhaps overriding a defined ordering).

If C<$pos> is not given, the key will be located and if found,
the value set. If the key is not found, a new pair is added to the
end or merged according to the defined C<order()>.

Returns C<$value> (as a nod toward $hash{$key}=$value, which
"returns" $value).

=cut

 my $pairs = Data::Pairs->new( [{a=>1},{b=>2}] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2}], 'Data::Pairs' )",
    "new()" );

 $pairs->set( c => 3, 0 );  # pairs is now [{c=>3},{b=>2}]

is( Dumper($pairs), "bless( [{'c' => 3},{'b' => 2}], 'Data::Pairs' )",
    "set()" );

}

OBJECT_get_values: {

=head2 $pairs->get_values( [$key[, @keys]] );

Get a value or values.

Regardless of parameters, if the object is empty, undef is returned in
scalar context, an empty list in list context.

If no paramaters, gets all the values.  In scalar context, gives
number of values in the object.

 my $pairs = Data::Pairs->new( [{a=>1},{b=>2},{c=>3},{b=>4},{b=>5}] );
 my @values  = $pairs->get_values();  # (1, 2, 3, 4, 5)
 my $howmany = $pairs->get_values();  # 5

If multiple keys given, their values are returned in the order found
in the object, not the order of the given keys.

In scalar context, gives the number of values found, e.g.,

 @values  = $pairs->get_values( 'c', 'b' );  # (2, 3, 4, 5)
 $howmany = $pairs->get_values( 'c', 'b' );  # 4

If only one key is given, I<first> value found for that key is
returned in scalar context, all the values in list context.

 @values   = $pairs->get_values( 'b' );  # (2, 4, 5)
 my $value = $pairs->get_values( 'b' );  # 2

Note, if you don't know if a key will have more than value, calling
C<get_values()> in list context will ensure you get them all.

=cut

 my $pairs = Data::Pairs->new( [{a=>1},{b=>2},{c=>3},{b=>4},{b=>5}] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2},{'c' => 3},{'b' => 4},{'b' => 5}], 'Data::Pairs' )",
    "new()" );

 my @values  = $pairs->get_values();  # (1, 2, 3, 4, 5)

is( "@values", "1 2 3 4 5",
    "get_values(), list" );

 my $howmany = $pairs->get_values();  # 5

is( $howmany, 5,
    "get_values(), scalar" );

 @values  = $pairs->get_values( 'c', 'b' );  # (2, 3, 4, 5)

is( "@values", "2 3 4 5",
    "get_values( 'c', 'b' ), list" );

 $howmany = $pairs->get_values( 'c', 'b' );  # 4

is( $howmany, 4,
    "get_values( 'c', 'b' ), scalar" );

 @values   = $pairs->get_values( 'b' );  # (2, 4, 5)

is( "@values", "2 4 5",
    "get_values( 'b' ), list" );

 my $value = $pairs->get_values( 'b' );  # 2

is( $value, 2,
    "get_values( 'b' ), scalar" );

}

OBJECT_add: {

=head2 $pairs->add( $key => $value[, $pos] );

Adds a key/value pair to the object.

Accepts C<$key>, C<$value>, and optionally, C<$pos>.

If C<$pos> is given, the key/value pair will be added (inserted)
there (possibly overriding a defined order), e.g.,

 my $pairs = Data::Pairs->new( [{a=>1},{b=>2}] );
 $pairs->add( c => 3, 1 );  # pairs is now [{a=>1},{c=>3},{b=>2}]

(Positions start at 0.)

If C<$pos> is not given, a new pair is added to the end or merged
according to the defined C<order()>.

Returns C<$value>.

=cut

 my $pairs = Data::Pairs->new( [{a=>1},{b=>2}] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2}], 'Data::Pairs' )",
    "new()" );

 $pairs->add( c => 3, 1 );  # pairs is now [{a=>1},{c=>3},{b=>2}]

is( Dumper($pairs), "bless( [{'a' => 1},{'c' => 3},{'b' => 2}], 'Data::Pairs' )",
    "add( c => 3, 1 )" );

}

OBJECT_get_pos: {

#---------------------------------------------------------------------

=head2 $pairs->get_pos( @keys );

Gets positions where keys are found.

Accepts one or more keys.

If one key is given, returns the position or undef (if key not
found), regardless of context, e.g.,

 my $pairs    = Data::Pairs->new( [{a=>1},{b=>2},{c=>3}] );
 my @pos = $pairs->get_pos( 'b' );  # (1)
 my $pos = $pairs->get_pos( 'b' );  # 1

If multiple keys, returns a list of hash refs in list context, the
number of keys found in scalar context.  The positions are listed in
the order that the keys were given (rather than in numerical order),
e.g.,

 @pos        = $pairs->get_pos( 'c', 'b' ); # @pos is ({c=>2},{b=>1})
 my $howmany = $pairs->get_pos( 'A', 'b', 'c' );  # $howmany is 2

Returns C<undef/()> if no keys given or object is empty.

=cut

 my $pairs    = Data::Pairs->new( [{a=>1},{b=>2},{c=>3}] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Pairs' )",
    "new()" );

 my @pos = $pairs->get_pos( 'b' );  # (1)

is( "@pos", 1,
    "get_pos( 'b' ), list" );

 my $pos = $pairs->get_pos( 'b' );  # 1

is( $pos, 1,
    "get_pos( 'b' ), scalar" );

 @pos        = $pairs->get_pos( 'c', 'b' ); # @pos is ({c=>2},{b=>1})

is( Dumper(\@pos), "[{'c' => 2},{'b' => 1}]",
    "get_pos( 'c', 'b' ), list" );

 my $howmany = $pairs->get_pos( 'A', 'b', 'c' );  # $howmany is 2

is( $howmany, 2,
    "get_pos( 'A', 'b', 'c' ), scalar" );

}

OBJECT_get_keys: {

=head2 $pairs->get_keys( @keys );

Gets keys.

Accepts zero or more keys.  If no keys are given, returns all the
keys in the object (list context) or the number of keys (scalar
context), e.g.,

 my $pairs    = Data::Pairs->new( [{a=>1},{b=>2},{c=>3},{b=>4},{b=>5}] );
 my @keys    = $pairs->get_keys();  # @keys is (a, b, c, b, b)
 my $howmany = $pairs->get_keys();  # $howmany is 5

If one or more keys are given, returns all the keys that are found
(list) or the number found (scalar).  Keys returned are listed in the
order found in the object, e.g.,

 @keys    = $pairs->get_keys( 'c', 'b', 'A' );  # @keys is (b, c, b, b)
 $howmany = $pairs->get_keys( 'c', 'b', 'A' );  # $howmany is 4

=cut

 my $pairs    = Data::Pairs->new( [{a=>1},{b=>2},{c=>3},{b=>4},{b=>5}] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2},{'c' => 3},{'b' => 4},{'b' => 5}], 'Data::Pairs' )",
    "new()" );

 my @keys    = $pairs->get_keys();  # @keys is (a, b, c, b, b)

is( "@keys", "a b c b b",
    "get_keys(), list" );

 my $howmany = $pairs->get_keys();  # $howmany is 5

is( $howmany, 5,
    "get_keys(), scalar" );

 @keys    = $pairs->get_keys( 'c', 'b', 'A' );  # @keys is (b, c, b, b)

is( "@keys", "b c b b",
    "get_keys( 'c', 'b', 'A' ), list" );

 $howmany = $pairs->get_keys( 'c', 'b', 'A' );  # $howmany is 4

is( $howmany, 4,
    "get_keys( 'c', 'b', 'A' ), scalar" );

}

OBJECT_get_array: {

=head2 $pairs->get_array( @keys );

Gets an array of key/value pairs.

Accepts zero or more keys.  If no keys are given, returns a list of
all the key/value pairs in the object (list context) or an array
reference to that list (scalar context), e.g.,

 my $pairs    = Data::Pairs->new( [{a=>1},{b=>2},{c=>3}] );
 my @array   = $pairs->get_array();  # @array is ({a=>1}, {b=>2}, {c=>3})
 my $aref    = $pairs->get_array();  # $aref  is [{a=>1}, {b=>2}, {c=>3}]

If one or more keys are given, returns a list of key/value pairs for
all the keys that are found (list) or an aref to that list (scalar).
Pairs returned are in the order found in the object, e.g.,

 @array = $pairs->get_array( 'c', 'b', 'A' );  # @array is ({b->2}, {c=>3})
 $aref  = $pairs->get_array( 'c', 'b', 'A' );  # @aref  is [{b->2}, {c=>3}]

Note, conceivably this method might be used to make a copy
(unblessed) of the object, but it would not be a deep copy (if values
are references, the references would be copied, not the referents).

=cut

 my $pairs    = Data::Pairs->new( [{a=>1},{b=>2},{c=>3}] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Pairs' )",
    "new()" );

 my @array   = $pairs->get_array();  # @array is ({a=>1}, {b=>2}, {c=>3})

is( Dumper(\@array), "[{'a' => 1},{'b' => 2},{'c' => 3}]",
    "get_array(), list" );

 my $aref    = $pairs->get_array();  # $aref  is [{a=>1}, {b=>2}, {c=>3}]

is( Dumper($aref), "[{'a' => 1},{'b' => 2},{'c' => 3}]",
    "get_array(), scalar" );

 @array = $pairs->get_array( 'c', 'b', 'A' );  # @array is ({b->2}, {c=>3})

is( Dumper(\@array), "[{'b' => 2},{'c' => 3}]",
    "get_array( 'c', 'b', 'A' ), list" );

 $aref  = $pairs->get_array( 'c', 'b', 'A' );  # @aref  is [{b->2}, {c=>3}]

is( Dumper($aref), "[{'b' => 2},{'c' => 3}]",
    "get_array( 'c', 'b', 'A' ), scalar" );

}

