use Bkp;
use Bkp::Src;
use XML;

unit class Bkp::Src::Lvm is Bkp::Src;

has Str $.suffix = 'raw';
has @.cmd = <dd>;

has Str $.vm;
has Str $.virsh    = 'virsh';
has Str $.device   = getdomdevice( $!virsh, $!vm );
has Str $!snapsuff = '_bkp';
has Str $!snapname = $!device.IO.basename ~ $!snapsuff;
has Str $!snapdev  = $!device ~ $!snapsuff;
has Str $!snapsize;
has Str $!quiet    = %*ENV<BKP_LOG> ?? '' !! '--quiet';

sub getdomdevice( $virsh, $vm ) {
    fail 'vm should be defined if no device provided' unless $vm.defined;
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
    return unless $!vm.defined;
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
    return unless $!vm.defined;
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

method snapsize {
    return $!snapsize if $!snapsize.defined;

    # set default snapshot size to fix case if script can't get real device size
    my $default_size = '5368709120b';
    my $proc;

    # get volume group name
    $proc = run «lvs $!device -o vgname --no-headings», :out;
    $proc.out.slurp-rest ~~ /( \w+ )/;
    return $default_size unless $0.defined;
    my $vgname = ~$0;

    # get free space in volume group
    $proc = run «vgs $vgname --nosuffix --units b -o free --no-headings», :out;   
    $proc.out.slurp-rest ~~ /( \d+ )/;
    return $default_size unless $0.defined;
    my $vgfree = ~$0;

    # get size of logical volume
    $proc = run «lvs $!device --nosuffix --units b -o size --no-headings», :out;
    $proc.out.slurp-rest ~~ /( \d+ )/;
    return $default_size unless $0.defined;
    my $lvsize = ~$0;

    # our wishful snapshot size is 30 % of lv size
    my $snapsize = $lvsize * 0.3;
    $snapsize = $vgfree if $snapsize > $vgfree;

    $!snapsize = $snapsize.Int ~ 'b';
    return $!snapsize;
}

method create-snapshot () {
    fail "snapshot device $!snapdev already exists" if $!snapdev.IO.e;
    %*ENV<LVM_SUPPRESS_FD_WARNINGS> = 1;
    $.domfsfreeze;
    my $null = %*ENV<BKP_LOG> ?? $*OUT !! open '/dev/null', :w;
    run «lvcreate -s -L $.snapsize -n $!snapname $!device», :out($null);
    $null.close unless %*ENV<BKP_LOG>;
    $.domfsthaw;
    return $!snapdev;
}

method clean-up () {
    return unless $!snapdev.defined;
    my $null = %*ENV<BKP_LOG> ?? $*OUT !! open '/dev/null', :w;
    if $!snapdev.IO.e {
        %*ENV<LVM_SUPPRESS_FD_WARNINGS> = 1;
        run «lvremove -y $!snapdev», :out($null);
    }
    $null.close unless %*ENV<BKP_LOG>;
    return;
}

method build-cmd () {
    my @cmd = @!cmd.clone;
    @cmd.append: "if=" ~ $.create-snapshot;
    return @cmd;
}
