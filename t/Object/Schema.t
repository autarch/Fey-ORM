use strict;
use warnings;

use Test::More tests => 8;

use lib 't/lib';

use Fey::ORM::Test;
use Fey::Literal::String;
use Fey::Test;
use List::MoreUtils qw( uniq );


Fey::ORM::Test::insert_user_data();
Fey::ORM::Test::insert_message_data();
Fey::ORM::Test::define_live_classes();


{
    Schema->EnableObjectCaches();

    for my $class ( qw( User Message ) )
    {
        ok( $class->meta()->_object_cache_is_enabled(),
            "object cache is enabled in $class after Schema->EnableObjectCaches()" );
    }
}

{
    Schema->DisableObjectCaches();

    for my $class ( qw( User Message ) )
    {
        ok( ! $class->meta()->_object_cache_is_enabled(),
            "object cache is disabled in $class after Schema->DisableObjectCaches()" );
    }
}

{
    Schema->EnableObjectCaches();

    # seed the cache
    User->new( user_id => 1 );
    User->new( user_id => 42 );

    Message->new( message_id => 1 );
    Message->new( message_id => 2 );

    for my $class ( qw( User Message ) )
    {
        my $count = scalar uniq values %{ $class->meta()->_object_cache() };
        is( $count, 2,
            "$class has two unique objects in its cache" );
    }

    Schema->ClearObjectCaches();

    for my $class ( qw( User Message ) )
    {
        my $count = scalar uniq values %{ $class->meta()->_object_cache() };
        is( $count, 0,
            "$class has no objects in its cache after Schema->ClearObjectCaches()" );
    }
}
