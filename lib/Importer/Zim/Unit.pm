
package Importer::Zim::Unit;

use 5.010001;

BEGIN {
    require Importer::Zim::Base;
    Importer::Zim::Base->VERSION('0.5.0');
    our @ISA = qw(Importer::Zim::Base);
}

use Devel::Hook  ();
use Sub::Replace ();

use constant DEBUG => $ENV{IMPORTER_ZIM_DEBUG} || 0;

sub import {
    my $class = shift;

    warn "$class->import(@_)\n" if DEBUG;
    my @exports = $class->_prepare_args(@_);

    my $caller = caller;
    my $old    = Sub::Replace::sub_replace(
        map { ; "${caller}::$_->{export}" => $_->{code} } @exports );

    # Clean it up after compilation
    Devel::Hook->unshift_UNITCHECK_hook(
        sub {
            warn qq{Restoring @{[map qq{"$_"}, sort keys %$old]}\n}
              if DEBUG;
            Sub::Replace::sub_replace($old);
        }
    ) if %$old;
}

1;

=encoding utf8

=head1 NAME

Importer::Zim::Unit - Import functions during compilation

=head1 SYNOPSIS

    use Importer::Zim::Unit 'Scalar::Util' => 'blessed';
    use Importer::Zim::Unit 'Scalar::Util' =>
      ( 'blessed' => { -as => 'typeof' } );

    use Importer::Zim::Unit 'Mango::BSON' => ':bson';

    use Importer::Zim::Unit 'Foo' => { -version => '3.0' } => 'foo';

    use Importer::Zim::Unit 'SpaceTime::Machine' => [qw(robot rubber_pig)];

=head1 DESCRIPTION

    "I'm gonna roll around on the floor for a while. KAY?"
      – GIR

This is a backend for L<Importer::Zim> which makes imported
symbols available during compilation.

Unlike L<Importer::Zim::Lexical>, it works for perls before 5.18.
Unlike L<Importer::Zim::Lexical> which plays with lexical subs,
this meddles with the symbol tables for a (hopefully short)
time interval.

=head1 HOW IT WORKS

The statement

    use Importer::Zim::Unit 'Foo' => 'foo';

works sort of

    use Sub::Replace;

    my $_OLD_SUBS;
    BEGIN {
        require Foo;
        $_OLD_SUBS = Sub::Replace::sub_replace('foo' => \&Foo::foo);
    }

    UNITCHECK {
        Sub::Replace::sub_replace($_OLD_SUBS);
    }

That means:

=over 4

=item *

Imported subroutines are installed at compile time.

=item *

Imported subroutines are cleaned up just after the unit which defined
them has been compiled.

=back

See L<< perlsub /BEGIN, UNITCHECK, CHECK, INIT and END >> for
the concept of "compilation unit" which is relevant here.

See L<Sub::Replace> for a few gotchas about why this is not simply done
with Perl statements such as

    *foo = \&Foo::foo;

=head1 DEBUGGING

You can set the C<IMPORTER_ZIM_DEBUG> environment variable
for get some diagnostics information printed to C<STDERR>.

    IMPORTER_ZIM_DEBUG=1

=head1 SEE ALSO

L<Importer::Zim>

L<< perlsub /BEGIN, UNITCHECK, CHECK, INIT and END >>

L<Importer::Zim::Lexical>

L<Importer::Zim::EndOfScope>

=cut
