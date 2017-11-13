use Bkp;
use Bkp::Compress::Gzip;

unit class Bkp::Compress::Pigz is Bkp::Compress::Gzip;

has Str @.cmd = <pigz -c>;
has Int $.procs;

method build-cmd () {
    my @cmd = @!cmd.clone;
    @cmd.push("-$.level") if $.level;
    @cmd.append(«-p $!procs») if $!procs;
    return @cmd;
}
