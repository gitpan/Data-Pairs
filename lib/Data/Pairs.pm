#---------------------------------------------------------------------
  package Data::Pairs;
#---------------------------------------------------------------------

=head1 NAME

Data::Pairs - Perl module to implement ordered mappings with possibly
duplicate keys.

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

=head1 DESCRIPTION

This module implements the Data::Pairs class.  Objects in this class
are ordered mappings, i.e., they are hashes in which the key/value
pairs are in order. This is defined in shorthand as C<!!pairs> in the
YAML tag repository:  http://yaml.org/type/pairs.html.

The keys in Data::Pairs objects are not necessarily unique, unlike
regular hashes.

A closely related class, Data::Omap, which Data::Pairs inherits,
implements the YAML C<!!omap> data type, http://yaml.org/type/omap.html.
Data::Omap objects are also ordered sequences of key:value pairs but
they do not allow duplicate keys.

While ordered mappings are in order, they are not necessarily in a
I<particular> order, i.e., they are not necessarily sorted in any
way.  They simply have a predictable set order (unlike regular hashes
whose key/value pairs are in no set order).

By default, Data::Pairs will add new key/value pairs at the end of the
mapping, but you may request that they be merged in a particular
order with the C<order()> class method.

However, even though Data::Pairs will honor the requested order, it
will not attempt to I<keep> the mapping in that order.  By passing
position values to the C<set()> and C<add()> methods, you may insert
new pairs anywhere in the mapping and Data::Pairs will not complain.

=head1 IMPLEMENTATION

Normally, the underlying structure of an OO object is encapsulated
and not directly accessible (when you play nice). One key
implementation detail of Data::Pairs is the desire that the underlying
ordered mapping data structure (an array of single-key hashes) be
publically maintained as such and directly accessible, if desired.

To that end, no attributes but the data itself are stored in the
objects.  In the current version, that is why C<order()> is a class
method rather than an object method.  In the future, inside-out
techniques may be used to enable object-level ordering.

This data structure is inefficient in several ways as compared to
regular hashes: rather than one hash, it contains a separate hash per
key/value pair; because it's an array, key lookups (in the current
version) have to loop through it.

The advantage if using this structure is simply that it "natively"
matches the structure defined in YAML.  So if the (unblessed)
structure is dumped using YAML (or perhaps JSON), it may be read as
is by another program, perhaps in another language.  It is true that
this could be accomplished by passing the object through a formatting
routine, but I wanted to see first how this implementation might work.

=head1 VERSION

Data::Pairs version 0.02

=cut

use strict;
use warnings;

our $VERSION = '0.02';

use Scalar::Util qw( reftype looks_like_number );
use Carp;

my $order;    # package global, see order() accessor
our $errstr;  # error message

#---------------------------------------------------------------------

=head1 CLASS METHODS

=head2 Data::Pairs->new();

Constructs a new Data::Pairs object.

Accepts array ref containing single-key hash refs, e.g.,

 my $pairs = Data::Pairs->new( [ { a => 1 }, { b => 2 }, { c => 3 }, { b => 4 } ] );

When provided, this data will be loaded into the object.

Returns a reference to the Data::Pairs object.

=cut

sub new {
    my( $class, $aref ) = @_;
    return bless [], $class unless $aref;

    croak _errstr() unless _is_valid_pairs( $aref );
    bless $aref, $class;
}

sub _is_valid_pairs {
    my( $aref ) = @_;
    unless( $aref and ref( $aref ) and reftype( $aref ) eq 'ARRAY' ) {
        $errstr = "Invalid pairs: Not an array reference";
        return;
    }
    for my $href ( @$aref ) {
        unless( ref( $href ) eq 'HASH' ) {
            $errstr = "Invalid pairs: Not a hash reference";
            return;
        }
        my @keys = keys %$href;
        if( @keys > 1 ) {
            $errstr = "Invalid pairs: Not a single-key hash";
            return;
        }
    }
    return 1;  # is valid
}

sub _errstr {
    my $msg = $errstr;
    $errstr = "";
    $msg;  # returned
}

#---------------------------------------------------------------------

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

sub order {
    my( $class, $spec ) = @_;  # class not actually used ...
    return $order unless defined $spec;

    if( ref( $spec ) eq 'CODE' ) {
        $order = $spec;
    }
    else {
        $order = {
            ''  => '',                     # turn off ordering
            na  => sub{ $_[0] < $_[1] },   # number ascending
            nd  => sub{ $_[1] < $_[0] },   # number descending
            sa  => sub{ $_[0] lt $_[1] },  # string ascending
            sd  => sub{ $_[1] lt $_[0] },  # string descending
            sna => sub{                    # either ascending
                looks_like_number($_[0])&&looks_like_number($_[1])?
                $_[0] < $_[1]: $_[0] lt $_[1] },
            snd => sub{                    # either descending
                looks_like_number($_[0])&&looks_like_number($_[1])?
                $_[1] < $_[0]: $_[1] lt $_[0] },
            }->{ $spec };
        croak "\$spec($spec) not recognized" unless defined $order;
    }
    return $order;
}

#---------------------------------------------------------------------

=head1 OBJECT METHODS

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

sub set {
    my( $self, $key, $value, $pos ) = @_;
    return unless defined $key;

    # you can give a $pos to change a member including changing its key

    # pos   found    action
    # ----- -----    ------
    # def   def   -> set key/value at pos
    # def   undef -> set key/value at pos
    # undef def   -> set key/value at found
    # undef undef -> add key/value (according to order)

    my $found = $self->get_pos( $key );
    my $elem = { $key => $value };

    if( defined $pos and defined $found )
                            { $self->[ $pos ]   = $elem }
    elsif( defined $pos )   { $self->[ $pos ]   = $elem }
    elsif( defined $found ) { $self->[ $found ] = $elem }
    else                    { $self->_add_ordered( $key, $value ) }

    $value;  # returned
}

#---------------------------------------------------------------------

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

sub get_values {
    my( $self, @keys ) = @_;
    return unless @$self;

    if( @keys == 1 ) {  # most common case
        my $wantkey = $keys[0];
        my @ret;
        for my $href ( @$self ) {
            my ( $key ) = keys %$href;
            if( $key eq $wantkey ) {
                my ( $value ) = values %$href;
                push @ret, $value;
            }
        }
        return @ret if wantarray;
        return $ret[0] if @ret;
        return;  # key not found
    }

    elsif( @keys ) {
        my ( %ret, @ret );
        for my $href ( @$self ) {
            my ( $key ) = keys %$href;
            for ( @keys ) {
                if( $key eq $_ ) {
                    my ( $value ) = values %$href;
                    push @ret, $value;
                    last;
                }
            }
        }
        return @ret;
    }

    else {
        my @ret;
        for my $href ( @$self ) {
            my ( $value ) = values %$href;
            push @ret, $value;
        }
        return @ret;
    }
}

#---------------------------------------------------------------------

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

sub add {
    my( $self, $key, $value, $pos ) = @_;
    return unless defined $key;

    my $elem = { $key => $value };
    if( defined $pos ) { splice @$self, $pos, 0, $elem }
    else               { $self->_add_ordered( $key, $value ) }

    $value;  # returned
}

#---------------------------------------------------------------------

=head2 $pairs->_add_ordered( $key => $value );

Private routine used by C<set()> and C<add()>.

Accepts C<$key> and C<$value>.

Adds a new key/value pair to the end or merged according to the
defined C<order()>.

This routine should not be called directly, because it does not
check for duplicates.

Has no defined return value.

=cut

sub _add_ordered {
    my( $self, $key, $value ) = @_;
    my $elem = { $key => $value };

    unless( $order ) { push @$self, $elem; return }

    # optimization for when members are added in order
    if( @$self ) {
        my ( $key2 ) = keys %{$self->[-1]};  # at the end
        unless( $order->( $key, $key2 ) ) {
            push @$self, $elem;
            return;
        }
    }

    # else start comparing at the beginning
    for my $i ( 0 .. $#$self ) {
        my ( $key2 ) = keys %{$self->[ $i ]};
        if( $order->( $key, $key2 ) ) {  # XXX can we memoize $key in $order->()?
            splice @$self, $i, 0, $elem;
            return;
        }
    }

    push @$self, $elem;
}

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

sub get_pos {
    my( $self, @keys ) = @_;
    return unless @keys;
    return unless @$self;
    if( @keys == 1 ) {
        my $wantkey = $keys[0];
        for my $i ( 0 .. $#$self ) {
            my ( $key ) = keys %{$self->[ $i ]};
            if( $key eq $wantkey ) {
                return $i;
            }
        }
        return;  # key not found
    }
    else {
        my( %ret, @ret );
        for my $i ( 0 .. $#$self ) {
            my ( $key ) = keys %{$self->[ $i ]};
            for ( @keys ) {
                if( $key eq $_ ) {
                    $ret{ $key } = { $key => $i };
                    last;
                }
            }
        }
        @ret = grep defined, @ret{ @keys };  # keys-order
        return @ret;
    }
}

#---------------------------------------------------------------------

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

sub get_keys {
    my( $self, @keys ) = @_;
    return unless @$self;
    my @ret;
    if( @keys ) {
        for my $href ( @$self ) {
            my ( $key ) = keys %$href;
            for ( @keys ) {
                if( $key eq $_ ) {
                    push @ret, $key;
                    last;
                }
            }
        }
    }
    else {
        for my $href ( @$self ) {
            my ( $key ) = keys %$href;
            push @ret, $key;
        }
    }
    @ret;  # returned
}

#---------------------------------------------------------------------

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

sub get_array {
    my( $self, @keys ) = @_;
    return unless @$self;
    my @ret;
    if( @keys ) {
        for my $href ( @$self ) {
            my ( $key ) = keys %$href;
            for ( @keys ) {
                if( $key eq $_ ) {
                    push @ret, { %$href };
                    last;
                }
            }
        }
    }
    else {
        for my $href ( @$self ) {
            my ( $key ) = keys %$href;
            push @ret, { %$href };
        }
    }
    return wantarray? @ret: [ @ret ];
}

#---------------------------------------------------------------------

=head2 $pairs->firstkey();

This routine would support the tied hash FIRSTKEY method.  However,
since there isn't a way for C<nextkey()> to reliably get the next key
(because of duplicates), the tied implementation does not support
operations that rely on FIRSTKEY/NEXTKEY.

=cut

sub firstkey {
    croak "This operation is not supported.  Try using the corresponding OO method.";
}

#---------------------------------------------------------------------

=head2 $pairs->nextkey( $lastkey );

This routine would support the tied hash NEXTKEY method.  However,
because of duplicates, there isn't a way to reliably get the next key
based solely on the value of C<$lastkey>.  Therefore, the tied
implementation does not support operations that rely on
FIRSTKEY/NEXTKEY.

=cut

sub nextkey {
    croak "This operation is not supported.  Try using the corresponding OO method.";
}

#---------------------------------------------------------------------

=head2 $pairs->exists( $key );

Accepts one key.

Returns true if key is found in object, false if not.

This routine supports the tied hash EXISTS method, but may reasonably
be called directly, too.

=cut

sub exists {
    my( $self, $key ) = @_;
    return unless @$self;
    return defined $self->get_pos( $key );
}

#---------------------------------------------------------------------

=head2 $pairs->delete( $key );

Accepts one key.  If key is found, removes the I<first> matching
key/value pair from the object.  Must be repeated in a loop to delete
all occurrences of the key from the object.

Returns the value from the deleted pair.

This routine supports the tied hash DELETE method, but may be called
directly, too.

=cut

sub delete {
    my( $self, $key ) = @_;
    return unless defined $key;
    return unless @$self;

    my $found = $self->get_pos( $key );
    return unless defined $found;

    my $value = $self->[ $found ]->{ $key };
    splice @$self, $found, 1;  # delete it

    $value;  # returned
}

#---------------------------------------------------------------------

=head2 $pairs->clear();

Expects no parameters.  Removes all key/value pairs from the object.

Returns an empty list.

This routine supports the tied hash CLEAR method, but may be called
directly, too.

=cut

sub clear {
    my( $self ) = @_;
    @$self = ();
}

#---------------------------------------------------------------------
# perltie methods
#---------------------------------------------------------------------

# TIEHASH classname, LIST
# This is the constructor for the class. That means it is expected to
# return a blessed reference through which the new object (probably but
# not necessarily an anonymous hash) will be accessed.

sub TIEHASH {
    my $class = shift;
    $class->new( @_ );
}

#---------------------------------------------------------------------
# FETCH this, key
# This method will be triggered every time an element in the tied hash
# is accessed (read). 

sub FETCH {
    my $self = shift;
    $self->get_values( @_ );
}

#---------------------------------------------------------------------
# STORE this, key, value
# This method will be triggered every time an element in the tied hash
# is set (written). 

sub STORE {
    my $self = shift;
    $self->set( @_ );
}

#---------------------------------------------------------------------
# DELETE this, key
# This method is triggered when we remove an element from the hash,
# typically by using the delete() function.
# If you want to emulate the normal behavior of delete(), you should
# return whatever FETCH would have returned for this key. 

sub DELETE {
    my $self = shift;
    $self->delete( @_ );
}

#---------------------------------------------------------------------
# CLEAR this
# This method is triggered when the whole hash is to be cleared,
# usually by assigning the empty list to it.

sub CLEAR {
    my $self = shift;
    $self->clear();
}

#---------------------------------------------------------------------
# EXISTS this, key
# This method is triggered when the user uses the exists() function
# on a particular hash.

sub EXISTS {
    my $self = shift;
    $self->exists( @_ );
}

#---------------------------------------------------------------------
# FIRSTKEY this
# This method will be triggered when the user is going to iterate
# through the hash, such as via a keys() or each() call.

sub FIRSTKEY {
    my $self = shift;
    $self->firstkey();  # note, will croak
}

#---------------------------------------------------------------------
# NEXTKEY this, lastkey
# This method gets triggered during a keys() or each() iteration.
# It has a second argument which is the last key that had been accessed.

sub NEXTKEY {
    my $self = shift;
    $self->nextkey( @_ );  # note, will croak
}

#---------------------------------------------------------------------
# SCALAR this
# This is called when the hash is evaluated in scalar context.
# In order to mimic the behaviour of untied hashes, this method should
# return a false value when the tied hash is considered empty.

sub SCALAR {
    my $self = shift;
    $self->get_keys();  # number of keys or undef (scalar context)
}

#---------------------------------------------------------------------
# UNTIE this
# This is called when untie occurs. See "The untie Gotcha".

# sub UNTIE {
# }

#---------------------------------------------------------------------
# DESTROY this
# This method is triggered when a tied hash is about to go out of scope.

# sub DESTROY {
# }

#---------------------------------------------------------------------

1;  # 'use module' return value

__END__

