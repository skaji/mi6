unit class App::Mi6::JSON;

method encode(::?CLASS:U: %hash) {
    Rakudo::Internals::JSON.to-json: %hash, :pretty, :sorted-keys;
}

method decode(::?CLASS:U: $string) {
    Rakudo::Internals::JSON.from-json: $string;
}
