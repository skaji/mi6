use App::Mi6::Util;
unit class App::Mi6::Release::GitCommit;

method run(*%opt) {
    if %*ENV<FAKE_RELEASE> {
        note "Skip GitCommit because FAKE_RELEASE is set.";
        return;
    }

    my $message = %opt<next-version>;
    my $proc;
    $proc = mi6run <git commit -a -m>, $message;
    die if $proc.exitcode != 0;

    my $branch = self!git-branch;
    $proc = mi6run <git push origin>, $branch;
    die if $proc.exitcode != 0;
}

method !git-branch {
    my $content = ".git/HEAD".IO.slurp(:close);
    if $content ~~ rx{ 'ref: refs/heads/' (\S+) } {
        return $/[0]
    } else {
        "master";
    }
}
