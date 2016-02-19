use Bkp;
use Bkp::Middleware;

unit class Bkp::Compress::Gzip is Bkp::Middleware;

has Str @.cmd = <gzip -c>;
has Str $.add-suffix = 'gz';
has GzipLevel $.level;

method suffix () {
    "{$.src.suffix}.$!add-suffix";
}

method build-cmd () {
    my @cmd = @!cmd.clone;
    @cmd.push("-$!level") if $!level;
    return @cmd;
}
