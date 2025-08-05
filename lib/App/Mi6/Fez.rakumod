unit class App::Mi6::Fez;

use Fez::Util::Config:ver<55>:auth<zef:tony-o>;
use App::Mi6::Util;

method user() {
    config-value('un');
}

method groups() {
    my $groups = config-value('groups') || [];
    $groups.map({.<group>});
}

method upload($tarball) {
    my @cmd = $*EXECUTABLE, "-e", "use Fez::CLI", "--file=$tarball", "upload";
    note "Executing {@cmd}";
    my $p = mi6run |@cmd;
    die "Failed" if !?$p;
}
