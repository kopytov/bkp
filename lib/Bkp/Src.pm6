unit class Bkp::Src;

has Proc $!proc;
has $!null;

method out () {
    $!null = %*ENV<BKP_LOG> ?? $*ERR !! open '/dev/null', :w;
    $!proc //= run |self.build-cmd, :bin, :out, :err($!null);
    return $!proc.out;
}

method clean-up () { }
