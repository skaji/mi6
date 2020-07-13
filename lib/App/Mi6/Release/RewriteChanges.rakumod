unit class App::Mi6::Release::RewriteChanges;

method run(:$next-version, :$release-date) {
    my $content = "Changes".IO.slurp(:close);

    my $next = "$next-version  $release-date";

    $content .= subst(
        /^^ '{{$NEXT}}' /,
        '{{$NEXT}}' ~ "\n\n$next",
    );
    "Changes".IO.spurt($content);
}
