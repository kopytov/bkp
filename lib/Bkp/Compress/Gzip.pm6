use Bkp::Types;

unit class Bkp::Compress::Gzip;

has $.src is required;
has Str @.cmd = <gzip -c>;
has Str $.add-suffix = 'gz';
has GzipLevel $.level;
has Proc $!proc;

method suffix () {
    "{$.src.suffix}.$!add-suffix";
}

method build-cmd () {
    my @cmd = @!cmd.clone;
    @cmd.push("-$!level") if $!level;
    return @cmd;
}

method out () {
    $!proc //= run |self.build-cmd, :bin, :in($!src.out), :out;
    return $!proc.out;
}
