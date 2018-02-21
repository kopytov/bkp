unit class Bkp::Middleware;

has $.src is required;
has Proc $!proc;
has $!null;

method suffix ()   { $!src.suffix }
method clean-up () { $!src.clean-up }

method out () {
    $!null = %*ENV<BKP_LOG> ?? $*ERR !! open '/dev/null', :w;
    $!proc //= run |self.build-cmd, :bin, :in($!src.out), :out, :err($!null);
    return $!proc.out;
}
