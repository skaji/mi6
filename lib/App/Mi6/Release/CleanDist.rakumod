unit class App::Mi6::Release::CleanDist;

use Shell::Command;

method run(*%opt) {
    return if %opt<keep>;
    my $name = %opt<main-module>.subst("::", "-", :g);
    $name ~= "-" ~ %opt<next-version>;
    rm_rf $name if $name.IO.d;
    unlink "$name.tar.gz" if "$name.tar.gz".IO.e;
}
