#: PerlMaple.pm
#: implementation for the PerlMaple class
#: v0.02
#: Copyright (c) 2005 Agent Zhang
#: 2005-11-14 2005-12-17

package PerlMaple;

use strict;
use warnings;
use vars qw( $AUTOLOAD );
use Carp qw(carp croak);

our $VERSION = '0.02';
my $Started = 0;

require XSLoader;
XSLoader::load('PerlMaple', $VERSION);

sub new {
    my $class = shift;
    my %opts = @_;
    if (!exists $opts{PrintError}) {
        $opts{PrintError} = 1;
    }
    if ($Started or maple_start()) {
        $Started = 1;
        return bless \%opts, $class;
    }
    return undef;
}

sub eval_cmd {
    my ($self, $exp) = @_;
    $exp =~ s/[\s\n\r]+$//s;
    #if ($exp !~ /[;:]$/) {
    #    $exp .= ';';
    #}
    #warn $exp;
    maple_eval($exp);
    if (maple_success()) {
        return maple_result();
    }
    if ($self->{PrintError}) {
        carp "PerlMaple error: ", $self->error;
    }
    if ($self->{RaiseError}) {
        croak "PerlMaple error: ", $self->error;
    }
    return undef;
}

sub PrintError {
    my $self = shift;
    if (@_) {
        $self->{PrintError} = shift;
    } else {
        return $self->{PrintError};
    }
}

sub RaiseError {
    my $self = shift;
    if (@_) {
        $self->{RaiseError} = shift;
    } else {
        return $self->{RaiseError};
    }
}

sub error {
    if (!maple_success()) {
        return maple_error();
    }
    return undef;
}

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    #warn "$method";
    
    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    my $args = join(',', @_);
    $args =~ s/,\s*$//g;
    return $self->eval_cmd("$method($args);");
}

1;

__END__

=head1 NAME

PerlMaple - Perl binding for Waterloo's Maple software

=head1 SYNOPSIS

  use PerlMaple;

  $maple = PerlMaple->new or
      die $maple->error;
  $ans = $maple->eval_cmd('int(2*x^3,x);');
  defined $ans or die $maple->error;

  $maple->eval_cmd(<<'.');
  lc := proc( s, u, t, v )
           description "form a linear combination of the arguments";
           s * u + t * v
  end proc;
  .

  $maple = PerlMaple->new(
    PrintError => 0,
    RaiseError => 1,
  );

  print $maple->eval('solve(x^2+2*x+4, x)');
  print $maple->solve('x^2+2*x+4', 'x');
  print $maple->eval('int(2*x^3,x)', 'x=2');
  print $maple->int('2*x^3', 'x=0..2');

  $maple->PrintError(1);
  $maple->RaiseError(0);

  print $maple->diff('2*x^3', 'x');
  print $maple->ifactor('1000!');

=head1 VERSION

This document describes PerlMaple 0.02 released on December XXX, 2005.

=head1 DESCRIPTION

This is a very simple interface to Waterloo's Maple software via the OpenMaple
C interface.

=head1 INSTALLATION

Currently this software is only tested on Win32. To build this module
properly, you must first have Maple installed on your system and append
the paths of B<maplec.h> and B<maplec.lib> in your Maple installation to the
environments LIB and INC respectively. Because this module use Maple's
C interface via L<Inline::C>.

A typical path of maplec.h is "C:\Program Files\Maple 9\extern\include",
which should be appended to the INCLUDE environment. And a typical path
of maplec.lib is "C:\Program Files\Maple 9\bin.win", which should be
appended to the LIB environment. These paths may be different on your
machine but do depend on your Maple's version and location.

It may be similar on UNIX, but I haven't tried that.

=head2 EXPORT

None by default.

=head1 METHODS

PerlMaple uses AUTOLOAD mechanism so that any Maple functions are also valid
methods of your PerlMaple object, even those Maple procedures defined by 
yourself.

B<WARNING:> The -E<gt>eval method is now incompatible with that of the first
release (0.01). It is AUTOLOADed as the Maple counterpart. So you have to turn to
-E<gt>eval_cmd when Maple's eval function can't fit your needs. Sorry.

=over

=item -E<gt>new(RaiseError => .., PrintError => ..)

Class constructor. It starts a Maple session if it does not exist. It should
be noting that although you're able to create more than one PerlMaple objects,
all these maple objects share the same Maple session. So the context of each
PerlMaple objects may be corrupted intentionally. If any error occurs, this
method will return undef value, and set the internal error buffer which you can
read by the -E<gt>error() method.

This method also accepts two optional named arguments. When RaiseError is
set true, the constructor sets the RaiseError attribute of the new object
internally. And it is the same for the PrintError attribute.

=item -E<gt>PrintError

=item -E<gt>PrintError($new_value)

The PrintError attribute can be used to force errors to generate warnings 
(using Carp::carp) in addition to returning error codes in the normal way. When
set ``on'' (say, a true value), any method which results in an error 
occuring will cause the PerlMaple to effectively do a 
C<carp("PerlMaple error: ", $self->error)>.

By default, PerlMaple-E<gt>new PrintError ``on''.

If desired, the warnings can be caught and processed using a $SIG{__WARN__} 
handler or modules like CGI::Carp and CGI::ErrorWrap.

=item -E<gt>RaiseError

=item -E<gt>RaiseError($new_value)

The RaiseError attribute can be used to force errors to raise exceptions
rather than simply return error codes in the normal way. It is ``off''
(say, a false value in Perl) by default. When set ``on'', any method 
which results in an error will cause the PerlMaple to effectively do a
C<croak("PerlMaple error: ", $self->error)>.

If you turn RaiseError on then you'd normally turn PrintError off. 
If PrintError is also on, then the PrintError is done first (naturally).

=item -E<gt>eval_cmd($command)

This method may be the most important one for the implementation of this class.
It evaluates the
command stored in the argument, and returns a string containing the result.
If an error occurs, it will return undef, and set the internal error buffer
which you can read by the -E<gt>error() method.

Frankly speaking, most of the time you can use -E<gt>eval method instead of
invoking this method directly. However, this method is a bit faster, 
because any AUTOLOADed method is invoked this one internally. Moreover, there
exists something that can only be eval'ed properly bu -E<gt>eval_cmd. 
Here is a small example:

    $maple->eval_cmd(<<'.');
    lc := proc( s, u, t, v )
             description "form a linear combination of the arguments";
             s * u + t * v
    end proc;
    .

If you use -E<gt>eval instead, you will get the following error message:

    `:=` unexpected

That's because "eval" is a normal Maple function and hence you can't use
assignment statement as the argument.

=item -E<gt>error()

It returns the error message issued by the Maple kernel.

=back

=head1 INTERNAL FUNCTIONS

=over

=item maple_error

=item maple_eval

=item maple_result

=item maple_start

=item maple_success

=back

=head1 REPOSITORY

You can always get the latest version from the following SVN
repository:

    L<https://svn.berlios.de/svnroot/repos/win32maple>

If you want a committer bit, please let me know.

=head1 SEE ALSO

L<http://www.maplesoft.com>

=head1 AUTHOR

Agent Zhang, E<lt>agent2002@126.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Agent Zhang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
