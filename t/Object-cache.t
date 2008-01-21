use strict;
use warnings;

use Test::More;

use lib 't/lib';

use Fey::Class::Test;
use Fey::Test;


Fey::Class::Test::insert_user_data();
Fey::Class::Test::define_live_classes();

plan tests => 3;


{
    User->EnableObjectCache();

    my $user1 = User->new( user_id => 1 );
    my $user2 = User->new( user_id => 1 );

    is( $user1, $user2,
        'two objects for the same id are identical when the object cache is enabled' );
}

{
    User->DisableObjectCache();

    my $user1 = User->new( user_id => 1 );
    my $user2 = User->new( user_id => 1 );

    isnt( $user1, $user2,
          'two objects for the same id are not identical when the object cache is disabled' );
}

{
    User->EnableObjectCache();

    my $user1 = User->new( user_id => 1 );

    User->ClearObjectCache();

    my $user2 = User->new( user_id => 1 );

    isnt( $user1, $user2,
          'two objects for the same id are not identical when the object cache is enabled but cleared between calls to new()' );
}