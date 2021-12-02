use App::Mi6::Badge;
use App::Mi6::INI;
use App::Mi6::JSON;
use App::Mi6::Release;
use App::Mi6::Template;
use App::Mi6::Util;
use CPAN::Uploader::Tiny;
use Shell::Command;
use TAP;

BEGIN { $*PERL.compiler.version >= v2020.05 or die "App::Mi6 needs rakudo v2020.05 or later" }

unit class App::Mi6;

# You can inspect App-Mi6 distribution by this dist() method. For example,
#
#   say App::Mi6.dist.meta<version>; # 1.1.5
#   say App::Mi6.dist.meta<auth>;    # cpan:SKAJI
#
method dist() { $?DISTRIBUTION }

my $MODULE-EXT = / '.' [ pm | pm6 | rakumod ] /;

has $!year   = Date.today.year;

my $normalize-path = -> $path {
    $*DISTRO.is-win ?? $path.subst('\\', '/', :g) !! $path;
};
my $to-module = -> $file {
    $normalize-path($file).subst('lib/', '').subst('/', '::', :g).subst(/$MODULE-EXT$/, '');
};
my $to-file = -> $module {
    'lib/' ~ $module.subst(rx{ '::' | '-' }, '/', :g) ~ '.rakumod';
};

my sub config($section, $key?, :$default = Any) {
    state $top = "dist.ini".IO.e ?? App::Mi6::INI::parsefile("dist.ini") !! {};
    my $config = $top{$section};
    return $config // $default if !$config || !$key;
    my $pair = @($config).grep({ $_.key eq $key }).first;
    $pair ?? $pair.value !! $default;
}

method !author() { mi6run(<git config --global user.name>,  :out).out.slurp(:close).chomp }

method !email()  { mi6run(<git config --global user.email>, :out).out.slurp(:close).chomp }

method !cpan-user() {
    $*HOME.add('.pause').e ?? CPAN::Uploader::Tiny.read-config($*HOME.add('.pause'))<user>.uc !! Nil;
}

method !zef-user() {
    try require ::("App::Mi6::Fez");
    if ::("App::Mi6::Fez") ~~ Failure {
        die "To create a distribution for Zef ecosystem, you need to install fez first";
    }
    if my $user = ::("App::Mi6::Fez").username {
        return $user;
    } else {
        die "To create a distribution for Zef ecosystem, you need to execute 'fez register' and 'fez login' first.";
    }
}

multi method cmd('new', $module is copy, :$zef) {
    $module ~~ s:g/ '-' /::/;
    my $main-dir = $module;
    $main-dir ~~ s:g/ '::' /-/;
    die "Already exists $main-dir" if $main-dir.IO ~~ :d;
    mkpath($main-dir);
    chdir($main-dir); # XXX temp $*CWD
    my $module-file = $to-file($module);
    my $module-dir = $module-file.IO.dirname.Str;
    mkpath($_) for $module-dir, "t", "bin", ".github/workflows";

    note "Loading author's name and email from git config --global user.name / user.email";
    my $author = self!author;
    my $email = self!email;

    my $auth;
    if $zef {
        note "Loading zef username from ~/.fez-config.json";
        my $user = self!zef-user;
        $auth = "zef:$user";
    } else {
        if my $user = self!cpan-user {
            note "Loading cpan username from ~/.pause";
            $auth = "cpan:$user";
        }
    }

    my %content = App::Mi6::Template::template(
        :$module, :$author, :$auth, :$email,
        :$module-file,
        year => Date.today.year,
        dist => $module.subst("::", "-", :g),
    );
    my %map = <<
        Changes       Changes
        dist.ini      dist
        $module-file  module
        t/01-basic.rakutest  test
        LICENSE       license
        .gitignore    gitignore
        .github/workflows/test.yml workflow
    >>;
    for %map.kv -> $f, $c {
        spurt($f, %content{$c});
    }
    my %meta =
        authors => [ $author ],
        version => "0.0.1",
        perl => "6.d",
    ;
    %meta<auth> = $auth if $auth;
    "META6.json".IO.spurt: App::Mi6::JSON.encode(%meta) ~ "\n";

    mi6run "git", "init", ".", :!out;
    mi6run "git", "add", ".";
    self.cmd("build");
    mi6run "git", "add", ".";
    note "Successfully created $main-dir";
}

multi method cmd('build') {
    my ($module, $module-file) = guess-main-module();
    self.regenerate-readme($module-file);
    self.regenerate-meta($module, $module-file);
    build();
}

multi method cmd('test', *@file, Bool :$verbose, Int :$jobs) {
    self.cmd('build');
    my $exitcode = test(@file, :$verbose, :$jobs);
    $exitcode;
}

multi method cmd('release', Bool :$keep, Str :$next-version, Bool :$yes) {
    self.cmd('build');
    my ($main-module, $main-module-file) = guess-main-module();
    my $dist = $main-module.subst("::", "-", :g);
    my $release-date = DateTime.now.truncated-to('second').Str;
    my $upload-class = config("UploadToZef").defined ?? "UploadToZef" !! "UploadToCPAN";

    my $expect-auth;
    if $upload-class eq "UploadToZef" {
        my $user = self!zef-user;
        $expect-auth = "zef:$user";
    } else {
        my $user = self!cpan-user;
        die "cannot determine CPAN user from ~/.pause" if !$user;
        $expect-auth = "cpan:$user";
    }

    my $release = App::Mi6::Release.new(:$upload-class);
    $release.run(
        dir => "lib",
        app => self,
        :$main-module, :$main-module-file,
        :$release-date, :$dist, :$keep,
        :$next-version, :$yes,
        :$expect-auth,
    );
}

multi method cmd('dist', Bool :$no-top-directory) {
    self.cmd('build');
    my ($module, $module-file) = guess-main-module();
    my $tarball = self.make-dist-tarball($module, :$no-top-directory);
    say "Created $tarball";
    return $tarball;
}

sub build() {
    my $meta-text = $*CWD.child('META6.json').slurp;
    my $meta = App::Mi6::JSON.decode($meta-text);
    if $meta<builder>:exists {
        my $builder = do if $meta<builder> eq "MakeFromJSON" {
            "Distribution::Builder::$meta<builder>"
        } else {
            $meta<builder>
        };
        with-rakulib "$*CWD/lib", { (require ::($builder)).new(:$meta).build; }
        return;
    }

    my ($build-file) = <Build.rakumod Build.pm6 Build.pm>.grep(*.IO.e);
    return if !$build-file;

    note "==> Execute $build-file";
    my $cmd = "require '{$build-file.IO.absolute}'; ::('Build').new.build('{~$*CWD}') ?? exit(0) !! exit(1);";
    my @cmd = $*EXECUTABLE, "-Ilib", "-I.", '-e', $cmd;
    note "==> @cmd[]";
    my $proc = mi6run |@cmd;
    my $code = $proc.exitcode;
    die "Failed with exitcode $code" if $code != 0;
}

multi list-testfiles(IO::Path $path where .d) {
    for $path.dir(:test(!*.starts-with('.'))).self -> $entry {
        list-testfiles($entry);
    }
}
multi list-testfiles(IO::Path $path where .f) {
    take ~$path if $path.extension eq any('t', 't6', 'rakutest');
}
multi list-testfiles(IO::Path $path) {
    die "Invalid input '$path'";
}

sub test(@file, Bool :$verbose, Int :$jobs) {
    my %args = handlers => TAP::Harness::SourceHandler::Raku.new(incdirs => ["lib"]);
    %args<jobs> = $jobs with $jobs;
    %args<volume> = TAP::Verbose with $verbose;
    if @file.elems == 0 {
        @file = <t xt>.grep({.IO.d});
    }
    my @sources = sort gather { list-testfiles($_.IO) for @file };
    my $run = TAP::Harness.new(|%args).run(@sources);
    die "Test failed" if $run.result.has-errors;
}

method readme-header() {
    my ($user, $repo) = guess-user-and-repo();
    return "" if !$user;
    my $badges = config("Badges", default => []);
    if @$badges == 0 && ".travis.yml".IO.e {
        push $badges, (provider =>"travis-ci.org");
    }
    return "" if @$badges == 0;

    my @markdown;
    for @$badges -> $badge {
        die "unknown key Badges.{$badge.key} in dist.ini" if $badge.key ne "provider";
        my $provider = $badge.value;
        my $name = "test";
        if $provider ~~ rx{ (.+) '/' (.+) } {
            $provider = $/[0];
            $name = $/[1];
        }
        my $b = App::Mi6::Badge.new(:$user, :$repo, :$provider, :$name);
        push @markdown, $b.markdown();
    }
    return @markdown.join(" ") ~ "\n\n";
}

method regenerate-readme($module-file) {
    my $section = "ReadmeFromPod";
    my $default = "";
    return if config($section, "enable", :$default) eq "false" or config($section, "disable", :$default) eq "true";
    my $file = config($section, "filename", :$default) || $module-file;

    my @cmd = $*EXECUTABLE, "--doc=Markdown", $file;
    my $p = with-rakulib "$*CWD/lib", { mi6run |@cmd, :out };
    LEAVE $p && $p.out.close;
    die "Failed @cmd[]" if $p.exitcode != 0;
    my $markdown = $p.out.slurp;
    my $header = self.readme-header();
    spurt "README.md", $header ~ $markdown;
}

method regenerate-meta($module, $module-file) {
    my $already = App::Mi6::JSON.decode("META6.json".IO.slurp);
    my %new-meta =
        name          => $module,
        depends       => $already<depends> || [],
        test-depends  => $already<test-depends> || [],
        build-depends => $already<build-depends> || [],
        description   => find-description($module-file) || $already<description> || "",
        provides      => self.find-provides(),
        source-url    => $already<source-url> || find-source-url(),
        resources     => $already<resources> || [],
        tags          => $already<tags> || [],
        license       => $already<license> || guess-license(),
    ;
    for $already.keys -> $k {
        %new-meta{$k} = $already{$k} unless %new-meta{$k}:exists;
    }
    "META6.json".IO.spurt: App::Mi6::JSON.encode(%new-meta) ~ "\n";
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
        * eq "appveyor.yml",
        * eq ".appveyor.yml",
        * eq "circle.yml",
        * ~~ rx/\.precomp/,
        * ~~ rx/\.github/,
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

method make-dist-tarball($main-module, Bool :$no-top-directory) {
    my $name = $main-module.subst("::", "-", :g);
    my $meta = App::Mi6::JSON.decode("META6.json".IO.slurp);
    my $version = $meta<version>;
    die "To make dist tarball, you must specify a concrete version (no '*' or '+') in META6.json first"
        if $version.contains('*') or $version.ends-with('+');
    $name ~= "-$version";
    rm_rf $name if $name.IO.d;
    unlink "$name.tar.gz" if "$name.tar.gz".IO.e;
    my @file = mi6run("git", "ls-files", :out).out.lines(:close);

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
    my $proc = do if $no-top-directory {
        mi6run "tar", "czf", "$name.tar.gz", $name, :!out, :err, :%env;
    } else {
        temp $*CWD = $name;
        my @entry = ".".IO.dir.map(*.Str);
        mi6run "tar", "czf", "../$name.tar.gz", @entry, :!out, :err, :%env;
    };
    LEAVE $proc && $proc.err.close;
    if $proc.exitcode != 0 {
        my $exitcode = $proc.exitcode;
        my $err = $proc.err.slurp;
        die $err ?? $err !! "can't create tarball, exitcode = $exitcode";
    }
    return "$name.tar.gz";
}

my $GIT-REMOTE-REGEXP = rx{^[
    # eg: ssh://git@github.com/skaji/mi6.git
    [ https? | ssh | git ] '://' [<-[/]>+'@']? $<host>=<-[/]>+ '/' $<user>=<-[/]>+ '/' $<repo>=.+? '.git'?
    |
    # eg: git@github.com:skaji/mi6.git
    <-[@]>+ '@' $<host>=<-[:]>+ ':' $<user>=<-[/]>+ '/' $<repo>=.+? '.git'?
]$};

sub find-source-url() {
    my @line = mi6run("git", "remote", "-v", :out, :!err).out.lines(:close);
    return "" unless @line;
    my $url = gather for @line -> $line {
        my ($name, $url) = $line.split(/\s+/);
        if $name eq "origin" and $url {
            take $url;
            last;
        }
    }
    return "" unless $url;
    $url .= Str;
    if $url ~~ $GIT-REMOTE-REGEXP {
        return "https://$<host>/$<user>/$<repo>.git";
    }
    $url;
}

sub guess-user-and-repo() {
    my $url = find-source-url();
    return if $url eq "";
    if $url ~~ $GIT-REMOTE-REGEXP {
        return $<user>, $<repo>;
    }
    return;
}

method find-provides() {
    my @no-index;
    my $config = config('MetaNoIndex');
    if $config {
        for @($config) {
            my ($k, $v) = $_.kv;
            if $k eq 'file' || $k eq 'filename' {
                @no-index.push: $v;
            } else {
                die "Unsupported key 'MetaNoIndex.$k' is found in dist.ini";
            }
        }
    }
    my @prune = self.prune-files;
    my %provides = mi6run("git", "ls-files", "lib", :out).out.lines(:close).grep(/$MODULE-EXT$/)\
        .grep(-> $file { !so @prune.grep({$_($file)}) })\
        .grep(-> $file { !so @no-index.grep({ $_ eq $file }) })\
        .map(-> $file {
            my $module = $to-module($file.Str);
            $module => $normalize-path($file.Str);
        }).sort;
    %provides;
}

sub guess-main-module() {
    die "Must run in the top directory" unless "lib".IO ~~ :d;
    if my $name = config("_", "name") {
        my $file = $to-file($name).subst(".rakumod", "");
        $file =  "$file.pm6".IO.e     ?? "$file.pm6"
              !! "$file.pm".IO.e      ?? "$file.pm"
              !! "$file.rakumod".IO.e ?? "$file.rakumod"
              !! "";
        return ($to-module($file), $file) if $file;
    }
    my @module-files = mi6run("git", "ls-files", "lib", :out).out.lines(:close).grep(/$MODULE-EXT$/);
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
            $dir ~~ s/^ (perl6|p6|raku) '-' //;
            my $module = $dir.split('-').join('/');
            my @found = @module-files.grep(-> $f { $f ~~ m:i/$module $MODULE-EXT$/});
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

App::Mi6 - minimal authoring tool for Raku

=head1 SYNOPSIS

=begin code :lang<console>

$ mi6 new Foo::Bar        # create Foo-Bar distribution for CPAN ecosystem
$ mi6 new --zef Foo::Bar  # create Foo-Bar distribution for Zef ecosystem

$ mi6 build    # build the distribution and re-generate README.md/META6.json
$ mi6 test     # run tests
$ mi6 release  # release your distribution to CPAN/Zef ecosystem (configured by dist.ini)

=end code

=head1 INSTALLATION

First make sure you have rakudo v2020.05 or later. If not, install rakudo from L<https://rakudo.org/downloads>.

Then:

=begin code :lang<console>

$ zef install App::Mi6

=end code

=head1 DESCRIPTION

App::Mi6 is a minimal authoring tool for Raku. Features are:

=item Create minimal distribution skeleton for Raku

=item Generate README.md from lib/Main/Module.rakumod's pod

=item Run tests by C<mi6 test>

=item Release your distribution to L<CPAN ecosystem|https://www.cpan.org/authors/id/> or L<Zef ecosystem|https://deathbyperl6.com/faq-zef-ecosystem/>

=head1 FAQ

=head2 Can I customize mi6 behavior?

Yes. Use C<dist.ini>:

=begin code :lang<ini>

; dist.ini
name = Your-Module-Name

[ReadmeFromPod]
; if you want to disable generating README.md from main module's pod, then:
; enable = false
;
; if you want to change a file that generates README.md, then:
; filename = lib/Your/Tutorial.pod

[UploadToCPAN]   ; Upload your distribution to CPAN ecosystem
; [UploadToZef]  ; You can also use UploadToZef instead, to upload your distribution to Zef ecosystem

[PruneFiles]
; if you want to prune files when packaging, then
; filename = utils/tool.pl
;
; you can use Raku regular expressions
; match = ^ 'xt/'

[MetaNoIndex]
; if you do not want to list some files in META6.json as "provides", then
; filename = lib/Should/Not/List/Provides.rakumod

[Badges]
; if you want to add badges to README.md, then
; provider = travis-ci.org
; provider = travis-ci.com
; provider = appveyor
; provider = github-actions/name

=end code

=head2 How can I manage depends, build-depends, test-depends?

Write them to META6.json directly :).

=head2 Where is the spec of META6.json?

https://design.raku.org/S22.html

See also L<The Meta spec, Distribution, and CompUnit::Repository explained-ish|https://perl6advent.wordpress.com/2016/12/16/day-16-the-meta-spec-distribution-and-compunitrepository-explained-ish/> by ugexe.

=head2 What is the format of the .pause file?

Mi6 uses the .pause file in your home directory to determine the username.
This is a flat text file, designed to be compatible with the .pause file used
by the Perl5 C<cpan-upload> module (L<<https://metacpan.org/pod/cpan-upload>>).
Note that this file only needs to contain the "user" and "password" directives.
Unknown directives are ignored.

An example file could consist of only two lines:

=begin code

user your_pause_username
password your_pause_password

=end code

Replace C<your_pause_username> with your PAUSE username, and replace
C<your_pause_password> with your PAUSE password.

This file can also be encrypted with GPG
if you do not want to leave your PAUSE credentials in plain text.

=head2 What existing files are modified by C<mi6>?

After the initial C<mi6> creation step, the following files are changed by C<mi6>
during each build or release operation:

=item C<README.md>
=item C<Changes>
=item C<META6.json>
=item modules in the lib directory

=head2 How is the version number specified?

When you are ready to release a module and enter at the CLI mi6
release, you will get a response presenting a proposed version number
which you can either accept or enter a new one (which must be greater
than the one offered by default).

During the release, C<mi6> updates the files mentioned above with the selected version number.

=head2 What is the required format of the C<Changes> file before a release?

Ensure your C<Changes> file looks like something like this B<before> you start a release operation

=begin code

{{$NEXT}}
    - Change entry line 1
    - Change entry line 2
    - Change entry line 3

=end code

Notes:

=item C<mi6 release> will replace the C<{{$NEXT}}> line with the new version number and its timestamp
=item You B<must> have at least one change entry line
=item The first change entry line B<must> start with a space or tab

=head2 What is the source of the author's email address?

The email is taken from the author's C<.gitconfig> file.
In general, that same email address should match any email address existing in a module's
C<META6.json> file.

=head2 How does one change an existing distribution created with C<mi6> to use Zef ecosystem instead of CPAN ecosystem?

First, the author must have an active account with L<fez|https://github.com/tony-o/raku-fez> which
will create a C<.fez-config.json> file in the author's home directory.

Then, starting with an existing module created with C<mi6>, do the following:

=begin item
Add the following line to your C<dist.ini> file:

C<[UploadToZef]>
=end item

=begin item
Change all instances of the C<auth<cpan:CPAN-USERNAME>> to
C<auth<zef:zef-username>>. Check files C<META6.json> and
the module's leading or main module file in
directory C<./lib>.
=end item

=begin item
Optional, but recommended: Add an entry in the module's C<Changes> file
mentioning the change.
=end item

=begin item
Run C<mi6 build; mi6 test>.
=end item

=begin item
Commit all changes.
=end item

=begin item
Run C<mi6 release> and accept (or increase)
the version number offered by C<mi6>.
=end item

=head1 TODO

documentation

=head1 SEE ALSO

L<<https://github.com/tokuhirom/Minilla>>

L<<https://github.com/rjbs/Dist-Zilla>>

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Shoichi Kaji

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
