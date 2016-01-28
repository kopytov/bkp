use Bkp;

unit class Bkp::Src::Redis;

has Str $.suffix = 'rdb';
has FilePath $.dump is required;

method out () {
    open $!dump, :r;
}
