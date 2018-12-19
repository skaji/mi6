use v6.c;
unit class App::Mi6::Release::UploadToCPAN;
use CPAN::Uploader::Tiny;
use App::Mi6::Util;

method run(*%opt) {
    if %*ENV<FAKE_RELEASE> {
        note "Skip UploadToCPAN because FAKE_RELEASE is set.";
        return;
    }
    my $config = $*HOME.add: ".pause";
    die "To upload tarball to CPAN, you need to prepare $config first\n" unless $config.IO.e;
    my $client = CPAN::Uploader::Tiny.new-from-config($config);
    my $tarball = %opt<tarball>;
    loop {
        my $answer = prompt("Are you sure you want to upload $tarball to CPAN? (y/N)");
        if $answer ~~ rx:i/^y(es)?$/ {
            last;
        } elsif $answer ~~ rx:i/^n(o)?$/ {
            die "Abort.\n";
        } else {
            say "Please type Yes or No.";
        }
    };
    $client.upload($tarball, subdirectory => "Perl6");
    say "Successfully uploaded $tarball to CPAN.";
}
