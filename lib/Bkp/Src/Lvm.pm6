use Bkp;
use Bkp::Src;
use XML;

unit class Bkp::Src::Lvm is Bkp::Src;

has Str $.suffix = 'raw';
has @.cmd = <dd >;

has Str     $.vm is required;
has Str     $.virsh = 'virsh';
has Str     $.device   = getdomdevice($!virsh, $!vm);
has Str     $!snapsuff = '_backup';
has Str     $!snapshot = $!vm ~ '_img' ~ $!snapsuff;
has Str     $!snapdev;
has Str     $!quiet    = %*ENV<BKP_LOG> ?? '' !! '--quiet';

sub getdomdevice($virsh, $vm) {
    my $proc = run «$virsh dumpxml $vm», :out;
    my $xml  = from-xml($proc.out.slurp-rest);
    my $devname = $vm ~ '_img';
    for $xml.elements(:RECURSE(Inf), :TAG<disk>) -> $device {
        next if $device.attribs<device> ne 'disk';
        my $file = $device.elements(:TAG<source>)[0].attribs<file>;
        next if not $file ~~ m/\/<$devname>$/;
        fail "LV $file not exists" if !$file.IO.e;
        return $file;
    }
}

method domfsfreeze () {
    try {
        my $null = %*ENV<BKP_LOG> ?? $*OUT !! open '/dev/null', :w;
        run «$!virsh $!quiet domfsfreeze $!vm», :out($null), :err($null);
        $null.close unless %*ENV<BKP_LOG>;
        CATCH {
            when X::Proc::Unsuccessful {
                $null.close unless %*ENV<BKP_LOG>;
                .throw if .proc.exitcode != 1;
                return;
            }
        }
    }
}

method domfsthaw () {
    try {
        my $null = %*ENV<BKP_LOG> ?? $*OUT !! open '/dev/null', :w;
        run «$!virsh $!quiet domfsthaw $!vm», :out($null), :err($null);
        $null.close unless %*ENV<BKP_LOG>;
        CATCH {
            when X::Proc::Unsuccessful {
                $null.close unless %*ENV<BKP_LOG>;
                .throw if .proc.exitcode != 1;
                return;
            }
        }
    }
}

method create-snapshot () {
    fail "device $!device$!snapsuff already exists"
      if !$!snapdev.defined && "$!device$!snapsuff".IO.e;
    $!snapdev = $!device ~ $!snapsuff;

    %*ENV<LVM_SUPPRESS_FD_WARNINGS> = 1;

    # set default snapshot size to fix case if script can't get real device size
    my $size = 5368709120;
    my $proc = run «lvs $!device --nosuffix --units b -o size --no-headings», :out;
    $proc.out.slurp-rest ~~ /( \d+ )/;
    if $0.defined {
        $size = ~$0 * 0.3;
    }
    $size = $size.Int ~ 'b';

    $.domfsfreeze;
    my $null = %*ENV<BKP_LOG> ?? $*OUT !! open '/dev/null', :w;
    run «lvcreate -s -L$size -n $!snapshot $!device», :out($null);
    $null.close unless %*ENV<BKP_LOG>;
    $.domfsthaw;
    return $!snapdev;
}

method clean-up () {
    my $null = %*ENV<BKP_LOG> ?? $*OUT !! open '/dev/null', :w;
    %*ENV<LVM_SUPPRESS_FD_WARNINGS> = 1;
    run «lvremove -y $!snapdev», :out($null);
    $null.close unless %*ENV<BKP_LOG>;
    return;
}

method build-cmd () {
    my @cmd = @!cmd.clone;
    @cmd.append: "if=" ~ $.create-snapshot;
    return @cmd;
}
