use v6;
unit class App::Mi6::JSON;
need JSON::Pretty;

my class SortedHash does Associative {
    has %.hash;
    method new(%hash) {
        self.bless(
            hash => %(%hash.kv.map(-> $k, $v {
                $k => $v ~~ Associative ?? self.new(%($v)) !! $v;
            })),
        );
    }
    method map(&cb) {
        do for %.hash.keys.sort({~$^a cmp ~$^b}) -> $k {
            &cb($k => %.hash{$k});
        }
    }
}

method encode(::?CLASS:U: %hash) {
    JSON::Pretty::EXPORT::DEFAULT::to-json SortedHash.new(%hash);
}
method decode(::?CLASS:U: $string) {
    JSON::Pretty::EXPORT::DEFAULT::from-json $string;
}
