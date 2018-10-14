use v6.c;
unit class App::Mi6::Release;

=begin pod

To prevent the following warnings, we explicitly use release-modules
instaed of dynamic requires :/

    WARNING: unhandled Failure detected in DESTROY. If you meant to ignore it, you can mark it as handled by calling .Bool, .so, .not, or .defined methods. The Failure was:
    No such symbol 'App::Mi6::Release::CheckChanges'
     in method run at /Users/skaji/src/github.com/skaji/mi6/lib/App/Mi6/Release.pm6 (App::Mi6::Release) line 21
     in method cmd at /Users/skaji/src/github.com/skaji/mi6/lib/App/Mi6.pm6 (App::Mi6) line 82
     in sub MAIN at bin/mi6 line 16
     in block <unit> at bin/mi6 line 27

=end pod

use App::Mi6::Release::CheckChanges;
use App::Mi6::Release::CheckOrigin;
use App::Mi6::Release::CheckUntrackedFiles;
use App::Mi6::Release::BumpVersion;
use App::Mi6::Release::RegenerateFiles;
use App::Mi6::Release::DistTest;
use App::Mi6::Release::MakeDist;
use App::Mi6::Release::RewriteChanges;
use App::Mi6::Release::UploadToCPAN;
use App::Mi6::Release::GitCommit;
use App::Mi6::Release::CreateGitTag;
use App::Mi6::Release::CleanDist;

my @klass =
    CheckChanges => "Make sure 'Changes' file has the next release description",
    CheckOrigin => "",
    CheckUntrackedFiles => "",
    BumpVersion => "Bump version for modules (eg: 0.0.1 -> 0.0.2)",
    RegenerateFiles => "",
    DistTest => "",
    MakeDist => "",
    UploadToCPAN => "Upload tarball to CPAN!",
    RewriteChanges => "",
    GitCommit => "Git commit, and push it to remote",
    CreateGitTag => "Create git tag, and push it to remote",
    CleanDist => "",
;

method !desc {
    note "==> Release distribution to CPAN";
    note "";
    note "  There are {+@klass} steps:";
    for @klass.kv -> $i, $pair {
        my ($klass, $desc) = $pair.kv;
        note "   * Step{sprintf '%2d', $i+1}. $klass" ~ ($desc ?? " - $desc" !! "");
    }
    note "";
}

method run(*%opt is copy) {
    self!desc;
    my &color = $*DISTRO.is-win || %*ENV<NO_COLOR> ?? ({$_}) !! ({"\e[32;1m$_\e[m"});
    my $prefix = "App::Mi6::Release::";
    for @klass.kv -> $i, $pair {
        my $klass = $pair.key;
        my $instance = ::($prefix ~ $klass).new;
        note &color("==> Step{sprintf '%2d', $i+1}. $klass");
        my $res = $instance.run(|%opt);
        %opt = |%opt, |%($res) if $res ~~ Associative;
    }
}
