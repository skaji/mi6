unit class App::Mi6::Release;


has $.upload-class = "UploadToCPAN";

method !ecosystem { $.upload-class eq "UploadToZef" ?? "Zef" !! "CPAN" }

method !classes() {
    my @klass =
        CheckAuth => "Make sure 'auth' in META6.json is '{self!ecosystem.lc}:xxx'",
        CheckChanges => "Make sure 'Changes' file has the next release description",
        CheckOrigin => "",
        CheckUntrackedFiles => "",
        BumpVersion => "Bump version for modules (eg: 0.0.1 -> 0.0.2)",
        RegenerateFiles => "",
        DistTest => "",
        MakeDist => "",
        $.upload-class => "",
        RewriteChanges => "",
        GitCommit => "Git commit, and push it to remote",
        CreateGitTag => "Create git tag, and push it to remote",
        CleanDist => "",
    ;
    return @klass;
}

method !desc {
    my @klass = self!classes;
    note "==> Release distribution to {self!ecosystem} ecosystem";
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

    my @klass = self!classes;
    for @klass.kv -> $i, $pair {
        my $klass = $pair.key;
        my $full-klass = $prefix ~ $klass;
        require ::($full-klass);
        my $instance = ::($full-klass).new;
        note &color("==> Step{sprintf '%2d', $i+1}. $klass");
        my $res = $instance.run(|%opt);
        %opt = |%opt, |%($res) if $res ~~ Associative;
    }
}
