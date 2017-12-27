use Bkp;
use Bkp::Src;

unit class Bkp::Src::Cmd is Bkp::Src;

has Str $.suffix is required;
has $.cmd is required;

method build-cmd () {
    return $!cmd.clone.list;
}
