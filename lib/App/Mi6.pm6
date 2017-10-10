use v6;
use App::Mi6::Template;
use App::Mi6::JSON;
use App::Mi6::INI;
use File::Find;
use Shell::Command;
use CPAN::Uploader::Tiny;

unit class App::Mi6:ver<0.0.7>;

has $!author = run(<git config --global user.name>,  :out).out.slurp(:close).chomp;
has $!email  = run(<git config --global user.email>, :out).out.slurp(:close).chomp;
has $!year   = Date.today.year;

my $normalize-path = -> $path {
    $*DISTRO.is-win ?? $path.subst('\\', '/', :g) !! $path;
};
my $to-module = -> $file {
    $normalize-path($file).subst('lib/', '').subst('/', '::', :g).subst(/\.pm6?$/, '');
};
my $to-file = -> $module {
    'lib/' ~ $module.subst(rx{ '::' | '-' }, '/', :g) ~ '.pm6';
};

my sub config($section, $key?, :$default = Any) {
    my $top = "dist.ini".IO.e ?? App::Mi6::INI::parsefile("dist.ini") !! {};
    my $config = $top{$section};
    return $config || $default if !$config || !$key;
    my $pair = @($config).grep({ $_.key eq $key }).first;
    $pair ?? $pair.value !! $default;
}

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
    my %content = App::Mi6::Template::template(
        :$module, :$!author, :$!email, :$!year,
        :$module-file,
        dist => $module.subst("::", "-", :g),
    );
    my %map = <<
        dist.ini     dist
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
    run "git", "init", ".", :!out;
    run "git", "add", ".";
    note "Successfully created $main-dir";
}

multi method cmd('build') {
    my ($module, $module-file) = guess-main-module();
    self.regenerate-readme($module-file);
    self.regenerate-meta-info($module, $module-file);
    build();
}

multi method cmd('test', @file, Bool :$verbose, Int :$jobs) {
    self.cmd('build');
    my $exitcode = test(@file, :$verbose, :$jobs);
    exit $exitcode;
}

multi method cmd('release') {
    self.cmd('build');
    my ($module, $module-file) = guess-main-module();
    my ($user, $repo) = guess-user-and-repo();
    die "Cannot find user and repository setting" unless $repo;
    my $meta-file = <META6.json META.info>.grep({.IO ~~ :f & :!l})[0];
    print "\n" ~ qq:to/EOF/ ~ "\n";
      Are you ready to release your module? Congrats!
      For this, follow these steps:

      1. Fork https://github.com/perl6/ecosystem repository.
      2. Add https://raw.githubusercontent.com/$user/$repo/master/$meta-file to META.list.
      3. And raise a pull request!

      Once your pull request is merged, we can install your module by:
      \$ zef install $module
    EOF
}

multi method cmd('dist') {
    self.cmd('build');
    my ($module, $module-file) = guess-main-module();
    my $tarball = self.make-dist-tarball($module);
    say "Created $tarball";
    return $tarball;
}

multi method cmd('upload') {
    my $tarball = self.cmd('dist');
    my @line = run("git", "status", "-s", :out).out.lines(:close);
    if @line.elems != 0 {
        note "You need to commit the following files before uploading $tarball";
        note "";
        note " * $_" for @line.map({s/\s*\S+\s+//; $_});
        note "";
        note "If you want to ignore these files, then list them in .gitignore or MANIFEST.SKIP";
        note "";
        die;
    }
    my $config = $*HOME.add: ".pause";
    die "To upload tarball to CPAN, you need to prepare $config first\n" unless $config.IO.e;
    my $client = CPAN::Uploader::Tiny.new-from-config($config);
    $*OUT.print("Are you sure to upload $tarball to CPAN? (y/N) ");
    $*OUT.flush;
    my $line = $*IN.get;
    if $line !~~ rx:i/^y/ {
        $*OUT.print("Abort.\n");
        return;
    }
    $client.upload($tarball, subdirectory => "Perl6");
    say "Successfully uploaded $tarball to CPAN.";
}

sub withp6lib(&code) {
    temp %*ENV;
    %*ENV<PERL6LIB> = %*ENV<PERL6LIB>:exists ?? "$*CWD/lib," ~ %*ENV<PERL6LIB> !! "$*CWD/lib";
    &code();
}

sub build() {
    return unless "Build.pm".IO.e;
    note '==> Execute Build.pm';
    my @cmd = $*EXECUTABLE, '-Ilib', '-I.', '-MBuild', '-e', "Build.new.build('{~$*CWD}')";
    my $proc = run |@cmd;
    my $code = $proc.exitcode;
    die "Failed with exitcode $code" if $code != 0;
}

sub test(@file, Bool :$verbose, Int :$jobs) {
    withp6lib {
        my @option = "-r";
        @option.push("-v") if $verbose;
        @option.push("-j", $jobs) if $jobs;
        if @file.elems == 0 {
            @file = <t xt>.grep({.IO.d});
        }
        my @command = "prove", "-e", $*EXECUTABLE, |@option, |@file;
        note "==> Set PERL6LIB=%*ENV<PERL6LIB>";
        note "==> @command[]";
        my $proc = run |@command;
        $proc.exitcode;
    };
}

method regenerate-readme($module-file) {
    my $section = "ReadmeFromPod";
    my $default = "";
    return if config($section, "enable", :$default) eq "false" or config($section, "disable", :$default) eq "true";
    my $file = config($section, "filename", :$default) || $module-file;

    my @cmd = $*EXECUTABLE, "--doc=Markdown", $file;
    my $p = withp6lib { run |@cmd, :out };
    LEAVE $p && $p.out.close;
    die "Failed @cmd[]" if $p.exitcode != 0;
    my $markdown = $p.out.slurp;
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

method regenerate-meta-info($module, $module-file) {
    my $meta-file = <META6.json META.info>.grep({.IO ~~ :f & :!l})[0];
    my $already = $meta-file.defined ?? App::Mi6::JSON.decode($meta-file.IO.slurp) !! {};

    my $authors = do if $already<authors> {
        $already<authors>;
    } elsif $already<author> {
        [$already<author>:delete];
    } else {
        [ $!author ];
    };

    my $perl = $already<perl> || "6.c";
    $perl = "6.c" if $perl eq "v6";
    $perl ~~ s/^v//;

    my @cmd = $*EXECUTABLE, "-M$module", "-e", "$module.^ver.Str.say";
    my $p = withp6lib { run |@cmd, :out, :!err };
    my $version = $p.out.slurp(:close).chomp || $already<version>;
    $version = "0.0.1" if $version eq "*";

    my %new-meta =
        name          => $module,
        perl          => $perl,
        authors       => $authors,
        depends       => $already<depends> || [],
        test-depends  => $already<test-depends> || [],
        build-depends => $already<build-depends> || [],
        description   => find-description($module-file) || $already<description> || "",
        provides      => find-provides(),
        source-url    => $already<source-url> || find-source-url(),
        version       => $version,
        resources     => $already<resources> || [],
        tags          => $already<tags> || [],
        license       => $already<license> || guess-license(),
    ;
    for $already.keys -> $k {
        %new-meta{$k} = $already{$k} unless %new-meta{$k}:exists;
    }
    ($meta-file || "META6.json").IO.spurt: App::Mi6::JSON.encode(%new-meta) ~ "\n";
}

sub guess-license() {
    my $file = "LICENSE".IO;
    return 'NOASSERTION' unless $file.e;
    my @line = $file.lines;
    if @line.elems == 201 && @line[0].index('The Artistic License 2.0') {
        return 'Artistic-2.0';
    } else {
        return 'NOASSERTION';
    }
}

sub find-description($module-file) {
    my $content = $module-file.IO.slurp;
    if $content ~~ /^^
        '=' head. \s+ NAME
        \s+
        \S+ \s+ '-' \s+ (\S<-[\n]>*)
    / {
        return $/[0].Str;
    } else {
        return "";
    }
}

method prune-files {
    my @prune = (
        * eq ".travis.yml",
        * eq ".gitignore",
        * eq "approvar.yml",
        * eq ".approvar.yml",
        * eq "circle.yml",
        * ~~ rx/\.precomp/,
    );
    if "MANIFEST.SKIP".IO.e {
        my @skip = "MANIFEST.SKIP".IO.lines.map: -> $skip { * eq $skip };
        @prune.push: |@skip;
    }
    if my $config = config("PruneFiles") {
        for @($config) {
            my ($k, $v) = $_.kv;
            if $k eq "filename" {
                @prune.push: * eq $v;
            } elsif $k eq "match" {
                @prune.push: * ~~ rx/<{$v}>/;
            } else {
                die "Invalid entry PruneFiles.$k in dist.ini";
            }
        }
    }
    return |@prune;

}

method make-dist-tarball($main-module) {
    my $name = $main-module.subst("::", "-", :g);
    my $meta = App::Mi6::JSON.decode("META6.json".IO.slurp);
    my $version = $meta<version>;
    die "To make dist tarball, you must specify version (not '*') in META6.json first"
        if $version eq '*';
    $name ~= "-$version";
    rm_rf $name if $name.IO.d;
    unlink "$name.tar.gz" if "$name.tar.gz".IO.e;
    my @file = run("git", "ls-files", :out).out.lines(:close);

    my @prune = self.prune-files;
    for @file -> $file {
        next if @prune.grep({$_($file)});
        my $target = "$name/$file";
        my $dir = $target.IO.dirname;
        mkpath $dir unless $dir.IO.d;
        $file.IO.copy($target);
    }
    my %env = %*ENV;
    %env<$_> = 1 for <COPY_EXTENDED_ATTRIBUTES_DISABLE COPYFILE_DISABLE>;
    my $proc = run "tar", "czf", "$name.tar.gz", $name, :!out, :err, :%env;
    LEAVE $proc && $proc.err.close;
    if $proc.exitcode != 0 {
        my $exitcode = $proc.exitcode;
        my $err = $proc.err.slurp;
        die $err ?? $err !! "can't create tarball, exitcode = $exitcode";
    }
    return "$name.tar.gz";
}

sub find-source-url() {
    my @line = run("git", "remote", "-v", :out, :!err).out.lines(:close);
    return "" unless @line;
    my $url = gather for @line -> $line {
        my ($, $url) = $line.split(/\s+/);
        if $url {
            take $url;
            last;
        }
    }
    return "" unless $url;
    $url .= Str;
    $url .= subst(/^ 'git:' /, 'https:');
    if $url ~~ m/'git@' $<host>=[.+] ':' $<repo>=[<-[:]>+] $/ {
        $url = "https://$<host>/$<repo>";
    } elsif $url ~~ m/'ssh://git@' $<rest>=[.+] / {
        $url = "https://$<rest>";
    }
    $url;
}

sub guess-user-and-repo() {
    my $url = find-source-url();
    return if $url eq "";
    if $url ~~ m{ (git|https?) '://'
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
    my %provides = find(dir => "lib", name => /\.pm6?$/).list.map(-> $file {
        my $module = $to-module($file.Str);
        $module => $normalize-path($file.Str);
    }).sort;
    %provides;
}

sub guess-main-module() {
    die "Must run in the top directory" unless "lib".IO ~~ :d;
    if my $name = config("_", "name") {
        my $file = $to-file($name).subst(".pm6", "");
        $file = "$file.pm6".IO.e ?? "$file.pm6" !! "$file.pm".IO.e ?? "$file.pm" !! "";
        return ($to-module($file), $file) if $file;
    }
    my @module-files = find(dir => "lib", name => /.pm6?$/).list;
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

  > mi6 new Foo::Bar # create Foo-Bar distribution
  > mi6 build        # build the distribution and re-generate README.md/META6.json
  > mi6 test         # run tests
  > mi6 upload       # upload distribution tarball to CPAN

=head1 INSTALLATION

  > zef install App::Mi6

=head1 DESCRIPTION

App::Mi6 is a minimal authoring tool for Perl6. Features are:

=item Create minimal distribution skeleton for Perl6

=item Generate README.md from lib/Main/Module.pm6's pod

=item Run tests by C<mi6 test>

=head1 FAQ

=head2 Can I customize mi6 behavior?

Use C<dist.ini>:

    ; dist.ini
    name = Your-Module-Name

    [ReadmeFromPod]
    ; if you want to disable generating README.md from main module's pod, then:
    ; disable = true
    ;
    ; if you want to change a file that generates README.md, then:
    ; filename = lib/Your/Tutorial.pod

    [PruneFiles]
    ; if you want to prune files when packaging, then
    ; filename = utils/tool.pl
    ;
    ; you can use Perl6 regular expressions
    ; match = ^ 'xt/'

=head2 How can I manage depends, build-depends, test-depends?

Write them to META6.json directly :)

=head2 Where is Changes file?

TODO

=head2 Where is the spec of META6.json?

http://design.perl6.org/S22.html

=head1 SEE ALSO

L<<https://github.com/tokuhirom/Minilla>>

L<<https://github.com/rjbs/Dist-Zilla>>

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Shoichi Kaji

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
