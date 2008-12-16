package Fey::Meta::HasMany;

use strict;
use warnings;

use Fey::Exceptions qw( param_error );

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;

extends 'Fey::Meta::FK';


has associated_method =>
    ( is         => 'rw',
      isa        => 'Moose::Meta::Method',
      writer     => '_set_associated_method',
      init_arg   => undef,
      lazy_build => 1,
    );

subtype 'Fey.ORM.Type.IteratorClass'
    => as 'ClassName'
    => where { $_[0]->isa('Fey::Object::Iterator') }
    => message { "$_[0] is a not a subclass of Fey::Object::Iterator" };

has 'iterator_class' =>
    ( is         => 'ro',
      isa        => 'Fey.ORM.Type.IteratorClass',
      lazy_build => 1,
    );


sub _build_iterator_class
{
    my $self = shift;

    return
        $self->is_cached()
        ? 'Fey::Object::Iterator::Caching'
        : 'Fey::Object::Iterator';
}

sub _build_is_cached { 0 }

sub _build_associated_method
{
    my $self = shift;

    my $iterator_maker = $self->_make_iterator_maker();

    my $iterator;
    my $method = sub { $iterator ||= $_[0]->$iterator_maker();
                       $iterator->reset();
                       return $iterator; };

    return
        $self->associated_class()->method_metaclass()
             ->wrap( name         => $self->name(),
                     package_name => $self->associated_class()->name(),
                     body         => $method,
                   );
}

sub _make_subref_for_sql
{
    my $self     = shift;
    my $select   = shift;
    my $bind_sub = shift;

    my $target_table = $self->foreign_table();

    my $iterator_class = $self->iterator_class();

    return
        sub { my $self = shift;

              my $class = $self->meta()->ClassForTable($target_table);

              my $dbh = $self->_dbh($select);

              return
                  $iterator_class->new( classes     => $class,
                                        dbh         => $dbh,
                                        select      => $select,
                                        bind_params => [ $self->$bind_sub() ],
                                      );
            };

}

sub attach_to_class
{
    my $self  = shift;
    my $class = shift;

    $self->_set_associated_class($class);

    $class->add_method( $self->name() => $self->associated_method() );
}

sub detach_from_class
{
    my $self  = shift;

    return unless $self->associated_class();

    $self->associated_class->remove_method( $self->name() );

    $self->_clear_associated_class();
}


no Moose;
no Moose::Util::TypeConstraints;

__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Fey::Meta::HasMany - A parent for has-many metaclasses

=head1 DESCRIPTION

This class exists to provide a common parent for the two has-many
metaclasses, L<Fey::Meta::HasMany::ViaFK> and
L<Fey::Meta::HasMany::ViaSelect>.

=head1 CONSTRUCTOR OPTIONS

This class accepts the following constructor options:

=over 4

=item * is_cached

Defaults to false for this class.

=item * iterator_class

This is the class used for iterators over the objects in this
relationship. By default, if this relationship is cached, it uses
L<Fey::Object::Iterator::Caching>, otherwise it uses
L<Fey::Object::Iterator>

=back

=head1 METHODS

This provides the following methods:

=head2 $hm->name()

Corresponds to the value passed to the constructor.

=head2 $hm->table()

Corresponds to the value passed to the constructor.

=head2 $hm->foreign_table()

Corresponds to the value passed to the constructor.

=head2 $ho->is_cached()

Corresponds to the value passed to the constructor, or the calculated
default.

=head2 $hm->iterator_class()

Corresponds to the value passed to the constructor, or the calculated
default.

=head2 $hm->attach_to_class($class)

This method takes a F<Fey::Meta::Class::Table> object and attaches the
relationship to the associated class. Doing so will create a new
method in the associated class.

=head2 $hm->associated_class()

The class associated with this object. This is undefined until C<<
$hm->attach_to_class() >> is called.

=head2 $hm->associated_method()

Returns the method associated with this object, if any.

=head2 $hm->detach_from_class()

If this object was attached to a class, it removes the method it made,
and unsets the C<associated_class>.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey::ORM> for details.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. The full text of the license
can be found in the LICENSE file included with this module.

=cut