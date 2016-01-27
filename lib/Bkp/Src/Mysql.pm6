use Bkp;
use Bkp::Src;

unit class Bkp::Src::Mysql is Bkp::Src;

has Str $.suffix = 'sql';
has @.cmd = <mysqldump -ER --single-transaction>;
has $.dbs;
has FilePath $.defaults-file;

method build-cmd () {
    my @cmd = @!cmd.clone;
    @cmd.append( "--defaults-file=$!defaults-file" ) if $.defaults-file;
    $!dbs.defined ?? @cmd.append: $!dbs.list !! @cmd.push: '--all-databases';
    return @cmd;
}
