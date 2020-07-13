use App::Mi6::Util;
unit class App::Mi6::Release::CreateGitTag;

method run(*%opt) {
    if %*ENV<FAKE_RELEASE> {
        note "Skip CreateGitTag because FAKE_RELEASE is set.";
        return;
    }

    my $tag = %opt<next-version>;
    my $proc;
    $proc = mi6run <git tag>, $tag;
    die if $proc.exitcode != 0;
    $proc = mi6run <git push origin tag>, $tag;
    die if $proc.exitcode != 0;
}
