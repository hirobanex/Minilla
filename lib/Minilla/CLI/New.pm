package Minilla::CLI::New;
use strict;
use warnings;
use utf8;
use File::pushd;

use Minilla::Skelton;


sub run {
    my ($self, @args) = @_;

    my $username;
    my $email;
    my $mb = 0;
    $self->parse_options(
        \@args,
        username => \$username,
        email    => \$email,
        mb       => \$mb, # use MB
    );
    my $module = shift @args or $self->error("Missing module name\n");
    $username ||= `git config user.name`;
    $username =~ s/\n$//;
    $email ||= `git config user.email`;
    $email =~ s/\n$//;

    my $version = '0.0.1';

    unless ($username) {
        $self->error("Please set user.name in git, or use `--username` option.");
    }

    # $module = "Foo::Bar"
    # $suffix = "Bar"
    # $dist   = "Foo-Bar"
    # $path   = "Foo/Bar.pm"
    my @pkg    = split /::/, $module;
    my $suffix = $pkg[ @pkg - 1 ];
    my $dist   = join "-", @pkg;
    my $path   = join( "/", @pkg ) . ".pm";
    ( my $dir = $dist ) =~ s/^App-//;

    if (-d $dist) {
        $self->error("There is $dist/\n");
    }

    my $author = $username;

    my $skelton = Minilla::Skelton->new(
        dist    => $dist,
        path    => $path,
        author  => $username,
        module  => $module,
        version => $version,
        email   => $email,
        mb      => $mb,
        c       => $self,
    );
    $skelton->generate();

    # init git repo
    $self->infof("Initializing psgi $module\n");
    {
        my $guard = pushd($dist);
        $self->cmd('git', 'init');
    }

    # generate metafile after initialize git repo
    $skelton->generate_metafile();

    # and commit all things
    {
        my $guard = pushd($dist);
        $self->cmd('git', 'add', '.');
        $self->cmd('git', 'commit', '-m', 'initial import');
    }

    $self->infof("Finished to create $module\n");
}

1;
__END__

=head1 NAME

Minilla::CLI::New - Generate new module skelton

=head1 SYNOPSIS

    # Create new app using Module::Build::Tiny(default)
    % minil new MyApp

    # Create new app using Module::Build
    % minil new MyApp --mb

=head1 DESCRIPTION

This module creates module skelton to current directory.

=head1 OPTIONS

=over 4

=item --mb

Generate skelton using L<Module::Build>
(Default Build.PL uses L<Module::Build::Tiny>)

It's useful for XS modules.

=back
