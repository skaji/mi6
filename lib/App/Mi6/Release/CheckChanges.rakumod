use App::Mi6::Util;
unit class App::Mi6::Release::CheckChanges;

method run(*%opt) {
    if not "Changes".IO.e {
        my $dist = %opt<dist>;
        note "mi6 now requires Changes file. Creating a skeleton Changes file.";
        note "Please check Changes file, and try `mi6 release` again.";
        my $content = qq:to/EOF/,
        Revision history for $dist

        \{\{\$NEXT\}\}
            - Initial version
        EOF
        "Changes".IO.spurt($content);
        mi6run <git add Changes>;
        die;
    }

    my $content = "Changes".IO.slurp(:close);

    die 'Changes file does not have {{$NEXT}} notation.' ~ "\n" if $content !~~ /'{{$NEXT}}'/;

    if $content !~~ /^^ '{{$NEXT}}' \n+ <[\ \t]>+ \S/ {
        die "Changes file does not have the next release description.\n";
    }
    return;
}
