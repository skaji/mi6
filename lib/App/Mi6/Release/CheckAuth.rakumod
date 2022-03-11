unit class App::Mi6::Release::CheckAuth;

use App::Mi6::JSON;
use App::Mi6::Util;

method run(*%opt) {
    my $expect-auth = %opt<expect-auth>.any;
    my $expect-str = %opt<expect-auth>.map({"'$_'"}).join(" or ");
    my $module = %opt<main-module>;

    my $meta-auth = App::Mi6::JSON.decode("META6.json".IO.slurp)<auth>;
    my $module-auth = do {
        my @cmd = $*EXECUTABLE, "-M$module", "-e", "$module.^auth.Str.say";
        my $p = with-rakulib "$*CWD/lib", { mi6run |@cmd, :out, :!err };
        $p.out.slurp(:close).chomp || Nil;
    };

    if %opt<auth-kind> eq 'zef' {
        if !$meta-auth {
            die "To upload distribution to Zef ecosystem, you need to set 'auth' in META6.json first";
        }
        if $meta-auth ne $expect-auth {
            die "auth '$meta-auth' in META6.json does not match auth $expect-str in ~/.fez-config.json";
        }
        if $module-auth && $module-auth ne $expect-auth {
            die "auth<$module-auth> in $module does not match auth $expect-str in ~/.fez-config.json";
        }
    } else {
        if $meta-auth && $meta-auth ne $expect-auth {
            die "auth '$meta-auth' in META6.json does not match auth $expect-str in ~/.pause";
        }
        if $module-auth && $module-auth ne $expect-auth {
            die "auth<$module-auth> in $module does not match auth $expect-str in ~/.pause";
        }
    }
    return;
}
