use Bkp;
use Bkp::Src;

unit class Bkp::Src::Redis is Bkp::Src;

has Str $.suffix = 'rdb';
has FilePath $.dump is required;

method out () {
    open $!dump, :r;
}
