unit class App::Mi6::Fez;

no precompilation;
use Fez::Util::Config;
use App::Mi6::Util;

method username() {
    config-value('un');
}

method groups() {
    (.map({ .<group> }) with config-value('groups'))
}

method upload($tarball) {
    my @cmd = $*EXECUTABLE, "-e", "use Fez::CLI", "--file=$tarball", "upload";
    note "Executing {@cmd}";
    my $p = mi6run |@cmd;
    die "Failed" if !?$p;
}
