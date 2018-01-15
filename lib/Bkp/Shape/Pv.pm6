use Bkp;
use Bkp::Middleware;

unit class Bkp::Shape::Pv is Bkp::Middleware;

has Str @.cmd = <pv -q>;
has Str $.rate-limit = '1m';

method build-cmd () {
    my @cmd = @!cmd.clone;
    @cmd.append: «-L $!rate-limit»;
    return @cmd;
}
