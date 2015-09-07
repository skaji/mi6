use v6;
use App::Mi6::Template;
use File::Find;
use Pod::To::Markdown;
use Shell::Command;

use JSON::Fast;
unless ({}, :pretty) ~~ &to-json.signature {
    die "!!! Your JSON::Fast is so old that it does not accepts :pretty argument.\n"
      ~ "!!! Please upgrade it: panda install JSON::Fast\n";
}
unit class App::Mi6;

has $!author;
has $!email;
has $!year;
has $!module;

my $to-module = -> $file {
    $file.subst('lib/', '').subst('/', '::', :g).subst(/\.pm6?$/, '');
};
my $to-file = -> $module {
    'lib/' ~ $module.subst('::', '/', :g) ~ '.pm6';
};

submethod BUILD(
    $!author = qx{git config --global user.name}.chomp,
    $!email  = qx{git config --global user.email}.chomp,
    $!year   = Date.today.year
) {}

multi method cmd('new', $module is copy) {
    $module ~~ s:g/ '-' /::/;
    my $main-dir = $module;
    $main-dir ~~ s:g/ '::' /-/;
    die "Already exists $main-dir" if $main-dir.IO ~~ :d;
    mkpath($main-dir);
    chdir($main-dir); # XXX temp $*CWD
    my $module-file = $to-file($module);
    my $module-dir = $module-file.IO.dirname.Str;
    mkpath($_) for $module-dir, "t", "bin";
    my %content = App::Mi6::Template::template(:$module, :$!author, :$!email, :$!year);
    my %map = <<
        $module-file module
        t/01-basic.t test
        LICENSE      license
        .gitignore   gitignore
        .travis.yml  travis
    >>;
    for %map.kv -> $f, $c {
        spurt($f, %content{$c});
    }
    self.cmd("build");
    run "git", "init", ".";
    run "git", "add", ".";
    note "Successfully created $main-dir";
}

multi method cmd('build') {
    my ($module, $module-file) = guess-main-module();
    regenerate-readme($module-file);
    self.regenerate-meta-info($module);
}

multi method cmd('test', :$verbose) {
    self.cmd('build');
    my $exitcode = test(:$verbose);
    exit $exitcode;
}

sub withp6lib(&code) {
    # copy from Panda::Common::withp6lib
    my $old = %*ENV<PERL6LIB>;
    LEAVE {
        if $old.defined {
            %*ENV<PERL6LIB> = $old;
        } else {
            %*ENV<PERL6LIB>:delete;
        }
    }
    %*ENV<PERL6LIB> = "$*CWD/lib";
    &code();
}

sub test(Bool :$verbose) {
    withp6lib {
        my $option = $verbose ?? "-rv" !! "-r";
        my $proc = run "prove", "-e", $*EXECUTABLE, $option, "t/";
        $proc.exitcode;
    };
}

sub regenerate-readme($module-file) {
    my @cmd = $*EXECUTABLE, "--doc=Markdown", $module-file;
    my $p = withp6lib { run |@cmd, :out };
    die "Failed @cmd[]" if $p.exitcode != 0;
    my $markdown = $p.out.slurp-rest;
    my ($user, $repo) = guess-user-and-repo();
    my $header = do if $user and ".travis.yml".IO.e {
        "[![Build Status](https://travis-ci.org/$user/$repo.svg?branch=master)]"
            ~ "(https://travis-ci.org/$user/$repo)"
            ~ "\n\n";
    } else {
        "";
    }

    spurt "README.md", $header ~ $markdown;
}

method regenerate-meta-info($module) {
    my $already = do if "META.info".IO.e {
        from-json "META.info".IO.slurp;
    } else {
        {};
    }

    my %new-meta =
        name        => $module,
        author      => $already<author> || $!author,
        depends     => $already<depends> || [],
        description => $already<description> || "",
        provides    => find-provides(),
        source-url  => $already<source-url> || find-source-url(),
        version     => $already<version> || "*",
    ;
    "META.info".IO.spurt: to-json(%new-meta) ~ "\n";
}

sub find-source-url() {
    try my @line = qx/git remote -v/;
    return "" unless @line;
    my $url = gather for @line -> $line {
        $line.chomp;
        my ($, $url) = $line.split(/\s+/);
        if $url {
            take $url;
            last;
        }
    }
    return "" unless $url;
    if $url ~~ m/'git@' $<host>=[.+] ':' $<repo>=[<-[:]>+] $/ {
        $url = "git://$<host>/$<repo>";
    } elsif $url ~~ m/'ssh://git@' $<rest>=[.+] / {
        $url = "git://$<rest>";
    }
    $url;
}

sub guess-user-and-repo() {
    my $url = find-source-url();
    return if $url eq "";
    if $url ~~ m{ 'git://'
        [<-[/]>+] '/'
        $<user>=[<-[/]>+] '/'
        $<repo>=[.+?] [\.git]?
    $} {
        return $/<user>, $/<repo>;
    } else {
        return;
    }
}

sub find-provides() {
    my %provides = find(dir => "lib", name => /\.pm6$/).list.map(-> $file {
        my $module = $to-module($file.Str);
        $module => $file.Str;
    });
    %provides;
}

sub guess-main-module() {
    die "Must run in the top directory" unless "lib".IO ~~ :d;
    my @module-files = find(dir => "lib", name => /.pm6$/).list;
    my $num = @module-files.elems;
    given $num {
        when 0 {
            die "Could not determine main module file";
        }
        when 1 {
            my $f = @module-files[0];
            return ($to-module($f), $f);
        }
        default {
            my $dir = $*CWD.basename;
            $dir ~~ s/^ (perl6|p6) '-' //;
            my $module = $dir.split('-').join('/');
            my @found = @module-files.grep(-> $f { $f ~~ m:i/$module . pm6?$/});
            my $f = do if @found == 0 {
                my @f = @module-files.sort: { $^a.chars <=> $^b.chars };
                @f.shift.Str;
            } elsif @found == 1 {
                @found[0].Str;
            } else {
                my @f = @found.sort: { $^a.chars <=> $^b.chars };
                @f.shift.Str;
            }
            return ($to-module($f), $f);
        }
    }
}

=begin pod

=head1 NAME

App::Mi6 - minimal authoring tool for Perl6

=head1 SYNOPSIS

  > mi6 new Foo::Bar

  > find Foo-Bar -type f -not -iwholename '*.git*'
  Foo-Bar/.travis.yml
  Foo-Bar/lib/Foo/Bar.pm6
  Foo-Bar/LICENSE
  Foo-Bar/META.info
  Foo-Bar/README.md
  Foo-Bar/t/01-basic.t

  > cd Foo-Bar
  > mi6 build  # regenerate README.md
  > mi6 test   # run tests

=head1 INSTALLATION

  > panda install git://github.com/shoichikaji/mi6.git

=head1 DESCRIPTION

App::Mi6 is a minimal authoring tool for Perl6. Features are:

=item Create minimal distribution skelton for Perl6

=item Auto generate README.md from lib/Main/Module.pm6's pod

=item Run tests by C<mi6 test>

=head1 FAQ

=item How can I manage depends, description, ...?

  Write them to META.info directly :)

=item Where is Changes file?

  TODO

=item Where is the spec of META.info or META6.json?

  Maybe https://github.com/perl6/ecosystem/blob/master/spec.pod

=item How do I remove travis badge?

  Remove .travis.yml

=head1 SEE ALSO

L<<https://github.com/tokuhirom/Minilla>>

L<<https://github.com/rjbs/Dist-Zilla>>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
