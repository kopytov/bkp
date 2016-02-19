unit class Bkp::Middleware;

has $.src is required;
has Proc $!proc;

method suffix ()   { $!src.suffix }
method clean-up () { $!src.clean-up }

method out () {
    $!proc //= run |$.build-cmd, :bin, :in($!src.out), :out;
    return $!proc.out;
}
