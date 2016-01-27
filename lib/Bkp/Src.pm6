unit class Bkp::Src;

has Proc $!proc;

method out () {
    $!proc //= run |self.build-cmd, :bin, :out;
    return $!proc.out;
}
