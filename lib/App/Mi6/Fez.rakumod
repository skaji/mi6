unit class App::Mi6::Fez;

no precompilation;
use Fez::Util::Config;
use App::Mi6::Util;

method username() {
    config-value('un');
}
method groups() {
    with config-value('groups') -> @groups {
        @groups.map: *<group>
    }
}

method upload($tarball) {
    my @cmd = "fez", "--file=$tarball", "upload";
    note "Executing {@cmd}";
    my $p = mi6run |@cmd;
    die "Failed" if !?$p;
}
