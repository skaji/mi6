use App::Mi6::Util;
unit class App::Mi6::Release::BumpVersion;

use App::Mi6::Util;
use App::Mi6::JSON;

my $VERSION-REGEXP = rx/ [<[0..9]> | '.']+ /;

my $PACKAGE-LINE = rx/
    ^
    $<before>=(
        \s* 'unit'? \s*
        ['module'|'class'|'grammar'|'role'|'monitor']
        \s+
        [ <[a..zA..Z0..9_-]> | '::' ]+
        .*
        ':ver' ['('|'<']
        [\'|\"]?
    )
    $<version>=(
        $VERSION-REGEXP
    )
    $<after>=(
        [\'|\"]?
        [')'|'>']
        .*
    )
/;

has @.line;

method run(*%opt) {
    self.scan(%opt<dir>);
    my $current-version = self.current-version;

    my $next-version = %opt<next-version> || (self!exists-git-tag($current-version) ?? self.next-version !! $current-version);
    if %opt<yes> {
        say "Use next release version $next-version";
    } else {
        my $message = "Next release version? [$next-version]:";
        my $answer = prompt($message, default => $next-version);
        $next-version = $answer;
    }
    die "'$next-version' is not a supported version string.\n" if $next-version !~~ rx/^ $VERSION-REGEXP $/;
    self.bump($next-version);

    my %result = :$current-version, :$next-version;
    %result;
}

method !exists-git-tag($tag) {
    my @line = mi6run(<git tag -l>, $tag, :out).out.lines(:close);
    +@line > 0;
}

method scan($dir) {
    my $ext = / '.' [ pm | pm6 | rakumod ] /;
    my @file = mi6run("git", "ls-files", $dir, :out).out.lines(:close).grep(/$ext$/);
    @!line = gather for @file -> $file {
        for $file.IO.lines(:!chomp).kv -> $num, $line {
            next if $line ~~ /'# No BumpVersion'/;
            if $line ~~ $PACKAGE-LINE {
                take %(
                    version => $/<version>.Str,
                    before => $/<before>.Str,
                    after => $/<after>.Str,
                    file => $file.Str,
                    num => $num,
                );
            }
        }
    }
}

method current-version {
    App::Mi6::JSON.decode("META6.json".IO.slurp)<version>;
}

method next-version($version? is copy) {
    $version //= self.current-version;
    my @p = Version.new($version).parts;
    @p[*-1]++;
    @p.join(".");
}

method bump($version) {
    my %meta = App::Mi6::JSON.decode("META6.json".IO.slurp);
    %meta<version> = $version;
    "META6.json".IO.spurt: App::Mi6::JSON.encode(%meta) ~ "\n";

    for @!line -> %line {
        self!bump(|%line, version => $version);
    }
}

method !bump(:$after, :$before, :$file, :$num, :$version) {
    my @new = gather for $file.IO.lines(:!chomp).kv -> $n, $line {
        if $n == $num {
            take $before ~ $version ~ $after;
        } else {
            take $line;
        }
    }
    $file.IO.spurt(@new.join(""));
}
