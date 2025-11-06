unit class App::Mi6::Fez;

use Fez::Util::Config;
use App::Mi6::Util;

method user() {
    config-value('un');
}

method groups() {
    my $groups = config-value('groups') || [];
    $groups.map({.<name> // .<group>})
}

method upload($tarball) {
    my @cmd = $*EXECUTABLE, "-e", "use Fez::CLI", "--file=$tarball", "upload";
    note "Executing {@cmd}";
    my $p = mi6run |@cmd;
    die "Failed" if !?$p;
}
