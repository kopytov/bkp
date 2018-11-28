unit class Bkp::Middleware;

use NativeCall;

sub kill ( int32, int32 ) is native {*};

has $.src is required;
has Proc $!proc;
has $!null;

method suffix ()   { $!src.suffix }
method clean-up () { $!src.clean-up }

method KILL () {
    kill $!proc.pid, 15;
    $!src.KILL;
}

method out () {
    $!null = %*ENV<BKP_LOG> ?? $*ERR !! open '/dev/null', :w;
    $!proc //= run |self.build-cmd, :bin, :in($!src.out), :out, :err($!null);
    return $!proc.out;
}
