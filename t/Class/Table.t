use strict;
use warnings;

use Test::More tests => 22;

use lib 't/lib';

use Fey::Class::Test qw( schema );

my $Schema = schema();


{
    package Email;

    sub new
    {
        return bless \$_[1], $_[0];
    }

    sub as_string
    {
        return ${ $_[0] };
    }

    package User;

    use Fey::Class::Table;

    has_table $Schema->table('User');

    transform 'email'
        => inflate { return Email->new( $_[1] ) }
        => deflate { return $_[1]->as_string() };
}

{
    ok( User->isa('Fey::Object'),
        q{User->isa('Fey::Object')} );
    can_ok( User->meta(), 'table' );
    is( User->meta()->table()->name(), 'User',
        'User->meta()->table() returns User table' );

    is( Fey::Meta::Class::Table->TableForClass('User')->name(), 'User',
        q{Fey::Meta::Class::Table->TableForClass('User') returns User table} );

    for my $column ( $Schema->table('User')->columns() )
    {
        can_ok( 'User', $column->name() );
    }

    can_ok( 'User', 'email_raw' );

    is ( User->meta()->get_attribute('user_id')->type_constraint()->name(),
         'Int',
         'type for user_id is Int' );

    is ( User->meta()->get_attribute('username')->type_constraint()->name(),
         'Str',
         'type for username is Str' );

    is ( User->meta()->get_attribute('email')->type_constraint()->name(),
         'Str | Undef',
         'type for email is Str | Undef' );

    ok( User->meta()->has_inflator('email'), 'User has an inflator coderef for email' );
    ok( User->meta()->has_deflator('email'), 'User has a deflator coderef for email' );

    my $user = User->new( user_id => 1, email => 'test@example.com' );

    ok( ! ref $user->email_raw(),
        'email_raw() returns a plain string' );
    is( $user->email_raw(), 'test@example.com',
        'email_raw = test@example.com' );

    my $email = $user->email();
    isa_ok( $email, 'Email' );
    is( $email, $user->email(), 'inflated values are cached' );
}

{
    package Message;

    use Fey::Class::Table;

    has_table $Schema->table('Message');

    has_one $Schema->table('User');

    # Testing passing >1 attribute to transform
    transform qw( message quality )
        => inflate { $_[0] }
        => deflate { $_[0] };

    eval
    {
        transform 'message'
            => inflate { $_[0] }
    };

    ::like( $@, qr/more than one inflator/,
            'cannot provide more than one inflator for a column' );

    eval
    {
        transform 'message'
            => deflate { $_[0] }
    };

    ::like( $@, qr/more than one deflator/,
            'cannot provide more than one deflator for a column' );
}

{
    can_ok( 'Message', 'user' );

    ok( Message->meta()->has_deflator('message'), 'Message has a deflator coderef for message' );
    ok( Message->meta()->has_deflator('quality'), 'Message has a deflator coderef for quality' );
}