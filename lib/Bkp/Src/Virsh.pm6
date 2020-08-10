use Bkp;
use Bkp::Src;
use XML;

unit class Bkp::Src::Virsh is Bkp::Src;

has @.cmd = <dd>;

has Str  $.vm       is required;
has Str  $.device   is required;
has Str  $.virsh    = 'virsh';
has Hash $.devices  = getdomdevices( $!virsh, $!vm );
has Str  $.suffix   = $!devices{$!device}<driver>;
has Str  $!snapsuff = '_bkp';
has Str  $!snapshot = 'bkp';
has Str  $!snapfile = $!device ~ $!snapsuff;
has Str  $!quiet    = %*ENV<BKP_LOG> ?? '' !! '--quiet';

sub getdomdevices( $virsh, $vm ) {
    fail 'vm should be defined' unless $vm.defined;
    my $proc = run «$virsh dumpxml $vm», :out;
    my $xml  = from-xml($proc.out.slurp-rest);
    my %devices;
    for $xml.elements(:RECURSE(Inf), :TAG<disk>) -> $device {
        next if $device.attribs<device> ne 'disk';
        my $type   = $device.attribs<type>;
        my $attr   = $type eq 'block' ?? 'dev' !! 'file';
        my $driver = $device.elements(:TAG<driver>)[0].attribs<type>;
        my $file   = $device.elements(:TAG<source>)[0].attribs{$attr};
        my $target = $device.elements(:TAG<target>)[0].attribs<dev>;
        fail "$file not exists" unless $file.IO.e;
        my $name   = IO::Path.new($file).basename;

        %devices{$file}<target>    = $target;
        %devices{$file}<driver>    = $driver;
        %devices{$file}<type>      = $type;
        %devices{$file}<snapshot>  = $file ~ '_bkp';
        %devices{$file}<snapshot>  = '/var/lib/libvirt/images/' ~ $name ~ '_bkp' if $type eq 'block';
    }
    return %devices;
}

method create-snapshot () {
    my $disks = q{};
    for $!devices.values -> $v {
        $disks ~= ' ' if $disks.chars;
        $disks ~= '--diskspec ' ~ $v<target> ~ ',file=' ~ $v<snapshot>;
    }
    my $null  = %*ENV<BKP_LOG> ?? $*OUT !! open '/dev/null', :w;
    run «$!virsh snapshot-create-as --domain $!vm $!snapshot $disks --disk-only --atomic», :out($null);
    for $!devices.keys -> $file {
        next if $file eq $!device;
        my $v      = $!devices{$file};
        my $target = $v<target>:v;
        run «$!virsh blockcommit $!vm $target --active --verbose --pivot», :out($null);
        $v<snapshot>.IO.unlink;
    }
    $null.close unless %*ENV<BKP_LOG>;
    return $!device;
}

method clean-up () {
    my $null = %*ENV<BKP_LOG> ?? $*OUT !! open '/dev/null', :w;
    my $target = $!devices{$!device}<target>;
    if $!snapfile.IO.e {
        run «$!virsh blockcommit $!vm $target --active --verbose --pivot», :out($null);
        $!snapfile.IO.unlink;
    }
    run «$!virsh snapshot-delete $!vm $!snapshot --metadata», :out($null);
    $null.close unless %*ENV<BKP_LOG>;
    return;
}

method build-cmd () {
    my @cmd = @!cmd.clone;
    @cmd.append: "if=" ~ $.create-snapshot;
    return @cmd;
}
