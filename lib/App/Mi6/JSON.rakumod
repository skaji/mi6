unit class App::Mi6::JSON;

method encode(::?CLASS:U: %hash, Int:D :$spacing = 2) {
    Rakudo::Internals::JSON.to-json: %hash, :$spacing, :pretty, :sorted-keys;
}

method decode(::?CLASS:U: $string) {
    Rakudo::Internals::JSON.from-json: $string;
}
