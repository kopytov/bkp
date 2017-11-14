use Bkp;
use Bkp::Dst;

unit class Bkp::Dst::Local is Bkp::Dst;

has DirPath $.dir is required;
has         %.mount;

method enumerate () {
    $!dir.IO.dir.map: { .basename };
}

method send ( Str $archive ) {
    my $filename = "$!dir/$archive";
    my $fh       = open $filename, :bin, :w;
    run 'cat', :in($.src.out), :out($fh);
    $fh.close;
}

method delete ( Str $archive ) {
    my $filename = "$!dir/$archive";
    $filename.IO.unlink;
}

method build-receive-cmd ( Str $archive ) {
    my $filename = "$!dir/$archive";
    return «cat $filename»;
}

method mount {
    return unless %!mount.elems;
    fail 'mount.point should be defined' unless %!mount<point>:exists;
    my Proc $proc;
    my DirPath $mountpoint = %!mount<point>;
    $proc = run <<is_mountpoint -q $mountpoint>>;
    return if $proc.exitcode == 0;

    my @mount = %!mount<cmd>:exists ?? |%!mount<cmd> !! <<mount $mountpoint>>;
    $proc = run |@mount;
    fail 'mount command returned non-zero code' if $proc.exitcode;
}

method umount {
    return unless %!mount<umount>;
    fail 'mount.point should be defined' unless %!mount<point>:exists;
    my Proc $proc;
    my DirPath $mountpoint = %!mount<point>;
    $proc = run <<is_mountpoint -q $mountpoint>>;
    return if $proc.exitcode;

    $proc = run <<umount $mountpoint>>;
    fail 'umount command returned non-zero code' if $proc.exitcode;
}
