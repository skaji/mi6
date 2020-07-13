unit class App::Mi6::Release::MakeDist;
use Shell::Command;
use App::Mi6::JSON;
use App::Mi6::Util;

method run(*%opt) {
    my $name = %opt<main-module>.subst("::", "-", :g);
    my $meta = App::Mi6::JSON.decode("META6.json".IO.slurp);
    $name ~= "-" ~ %opt<next-version>;
    rm_rf $name if $name.IO.d;
    unlink "$name.tar.gz" if "$name.tar.gz".IO.e;
    my @file = mi6run("git", "ls-files", :out).out.lines(:close);

    my @prune = %opt<app>.prune-files;
    for @file -> $file {
        next if @prune.grep({$_($file)});
        my $target = "$name/$file";
        my $dir = $target.IO.dirname;
        mkpath $dir unless $dir.IO.d;
        $file.IO.copy($target);
        if $file eq "Changes" {
            rewrite-change(
                $target,
                release-date => %opt<release-date>,
                next-version => %opt<next-version>,
            );
        }
    }
    my %env = %*ENV;
    %env<$_> = 1 for <COPY_EXTENDED_ATTRIBUTES_DISABLE COPYFILE_DISABLE>;
    my $proc = mi6run "tar", "czf", "$name.tar.gz", $name, :!out, :err, :%env;
    LEAVE $proc && $proc.err.close;
    if $proc.exitcode != 0 {
        my $exitcode = $proc.exitcode;
        my $err = $proc.err.slurp;
        die $err ?? $err !! "can't create tarball, exitcode = $exitcode";
    }
    tarball => "$name.tar.gz";
}

my sub rewrite-change($file, :$release-date, :$next-version) {
    my $content = $file.IO.slurp(:close);
    my $next = "$next-version  $release-date";
    $content .= subst(/^^ '{{$NEXT}}' /, $next);
    $file.IO.spurt($content);
}
