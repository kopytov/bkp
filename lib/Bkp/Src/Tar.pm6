use Bkp;
use Bkp::Src;

unit class Bkp::Src::Tar is Bkp::Src;

has Str $.suffix = 'tar';
has @.cmd = <tar --numeric-owner -cf ->;
has $.files is required;
has $.exclude;
has DirPath $.cwd;

method build-cmd () {
    my @cmd = @!cmd.clone;
    @cmd.append( «-C $.cwd» ) if $.cwd;
    @cmd.append: $!exclude.list.grep( {.defined} ).map( {"--exclude=$_"} );
    @cmd.append: $!files.list;
    return @cmd;
}
