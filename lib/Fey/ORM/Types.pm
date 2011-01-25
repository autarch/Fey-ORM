package Fey::ORM::Types;

use strict;
use warnings;

use base 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    qw( MooseX::Types::Moose Fey::ORM::Types::Internal )
);

1;

# ABSTRACT: Types for use in Fey::ORM

__END__

=head1 DESCRIPTION

This module defines a whole bunch of types used by the Fey::ORM core
classes. None of these types are documented for external use at the present,
though that could change in the future.

=head1 BUGS

See L<Fey::ORM> for details on how to report bugs.

=cut
