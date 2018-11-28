unit class Bkp::Src;

use NativeCall;

sub kill ( int32, int32 ) is native {*};

has Proc $!proc;
has $!null;

method KILL () {
    kill $!proc.pid, 15;
}

method out () {
    $!null = %*ENV<BKP_LOG> ?? $*ERR !! open '/dev/null', :w;
    $!proc //= run |self.build-cmd, :bin, :out, :err($!null);
    return $!proc.out;
}

method clean-up () { }
