unit class App::Mi6::Fez;

no precompilation;
use Fez::Util::Config;
use App::Mi6::Util;

method username() {
    config-value('un');
}

method upload($tarball) {
    mi6run "fez", "--file=$tarball", "upload";
}
