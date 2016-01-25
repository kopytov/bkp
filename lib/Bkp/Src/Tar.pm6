use Bkp;

unit class Bkp::Src::Tar;

has Str $.suffix = 'tar';
has @.cmd = <tar --numeric-owner -cf ->;
has $.files is required;
has $.exclude;
has DirPath $.cwd;
has Proc $!proc;

method build-cmd () {
    my @cmd = @!cmd.clone;
    @cmd.append( «-C $.cwd» ) if $.cwd;
    @cmd.append: $!exclude.list.grep( {.defined} ).map( {"--exclude=$_"} );
    @cmd.append: $!files.list;
    return @cmd;
}

method out () {
    $!proc //= run |self.build-cmd, :bin, :out;
    return $!proc.out;
}
