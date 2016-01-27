use Bkp;
use Bkp::Src;

unit class Bkp::Src::Redis is Bkp::Src;

has Str $.suffix = 'rdb';
has @.cmd = 'cat';
has $.dump is required;

method build-cmd () {
    flat @!cmd, $!dump;
}
