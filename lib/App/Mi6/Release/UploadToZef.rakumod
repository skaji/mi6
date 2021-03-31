unit class App::Mi6::Release::UploadToZef;

use App::Mi6::Util;
use App::Mi6::Fez;

method run(*%opt) {
    if %*ENV<FAKE_RELEASE> {
        note "Skip UploadToZef because FAKE_RELEASE is set.";
        return;
    }
    my $tarball = %opt<tarball>;
    if !%opt<yes> {
        loop {
            my $answer = prompt("Are you sure you want to upload $tarball to Zef ecosystem? (y/N)");
            if $answer ~~ rx:i/^y(es)?$/ {
                last;
            } elsif $answer ~~ rx:i/^n(o)?$/ {
                die "Abort.\n";
            } else {
                say "Please type Yes or No.";
            }
        };
    }
    note "===> Uploading $tarball to Zef ecosystem";
    App::Mi6::Fez.upload($tarball);
}
