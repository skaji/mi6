unit class App::Mi6::Badge;

has $.provider is required;
has $.user is required;
has $.repo is required;
has $.name;

my %markdown =
    "travis-ci.org" => -> :$user, :$repo, :$name {
        "[![Build Status](https://travis-ci.org/$user/$repo.svg?branch=master)]"
        ~ "(https://travis-ci.org/$user/$repo)";
    },
    "travis-ci.com" => -> :$user, :$repo, :$name {
        "[![Build Status](https://travis-ci.com/$user/$repo.svg?branch=master)]"
        ~ "(https://travis-ci.com/$user/$repo)";
    },
    "appveyor" => -> :$user, :$repo, :$name {
        "[![Windows Status](https://ci.appveyor.com/api/projects/status/github/$user/$repo?branch=master&passingText=Windows%20-%20OK&failingText=Windows%20-%20FAIL&pendingText=Windows%20-%20pending&svg=true)]"
        ~ "(https://ci.appveyor.com/project/$user/$repo/branch/master)";
    },
    "github-actions" => -> :$user, :$repo, :$name {
        "[![Actions Status](https://github.com/$user/$repo/workflows/$name/badge.svg)]"
        ~ "(https://github.com/$user/$repo/actions)";
    },
;

method markdown(--> Str) {
    my $markdown = %markdown{$!provider};
    die "invalid badge type $!provider" if !$markdown;
    $markdown(:$!user, :$!repo, :$!name);
}
