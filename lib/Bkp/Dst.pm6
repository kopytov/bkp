unit class Bkp::Dst;

has $.prefix is required;
has $.src    is required;
has %.plan   is required;

has %!archives-of;
has $!archives-of-initialized = False;

has Proc $!proc;

method is-archive ( $period = /<[ymwd]>/ ) {
    my $prefix      = $!prefix;
    my $main-suffix = $!src.suffix.split('.')[0];
    return rx{
        ^ $prefix
        \- ( \d\d\d\d \- \d\d \- \d\d )
        \- ( $period )
        \. $main-suffix
    };
}

method archives () {
    return %!archives-of if $!archives-of-initialized;
    $!archives-of-initialized = True;
    my @archives = $.enumerate.sort;
    for @archives -> $archive {
        next if $archive{'file'} !~~ $.is-archive;
        my $period = ~$1;
        %!archives-of{$period} //= [];
        %!archives-of{$period}.push($archive);
    }
    return %!archives-of;
}

method all-archives () {
    $.archives.values.map( { |$_ } ).sort;
}

method clear-archives () {
    $!archives-of-initialized = False;
    %!archives-of             = ();
}

method next-archive () {
    my $today = DateTime.now.Date;

    # last archive
    if $.all-archives.elems > 0 {
        my $last-archive = $.all-archives.map( { $_{'file'} } ).[* - 1];
        if $last-archive ~~ $.is-archive {
            my $date = Date.new(~$0);
            if $date == $today {
                $.delete($last-archive);
                $.clear-archives;
                return $last-archive;
            }
        }
    }

    # next archive
    my %archives-of = $.archives;
    my %days-of     = y => 365, m => 30, w => 7, d => 1;
    my $next-period;
    for <y m w d> -> $period {
        next if !%!plan{$period};
        $next-period = $period;
        last if !%archives-of{$period};
        my $last-archive = %archives-of{$period}[* - 1];
        next if $last-archive !~~ $.is-archive($period);
        my $date = Date.new(~$0);
        last if $date <= $today.earlier( days => %days-of{$period} );
    }
    return "$!prefix-$today-$next-period\.{$!src.suffix}";
}

method SEND () {
    my $next-archive = $.next-archive;
    my $next-period  = ~$1 if $next-archive ~~ $.is-archive;
    $.rotate($next-period);
    $.send($next-archive);
    $.clear-archives;
}

method rotate ( Str $next-period? ) {
    my %archives-of = $.archives;
    my %sum         = <y m w d>.map: -> $period {
        $period => %archives-of{$period}:exists
                ?? %archives-of{$period}.elems
                !! 0;
    };
    %sum{$next-period}++ if $next-period && %sum{$next-period};
    my %num-excess  = <y m w d>.map: -> $period {
        next if !%!plan{$period};
        next if !%sum{$period};
        my $num-excess = %sum{$period} - %!plan{$period};
        next if $num-excess <= 0;
        $period => $num-excess;
    }
    return if !%num-excess.elems;

    for %num-excess.kv -> $period, $num-excess {
        for %archives-of{$period}[ ^$num-excess ] -> $archive {
            $.delete($archive{'file'});
        }
    }
}

method out ( Str $archive ) {
    $!proc //= run |self.build-receive-cmd($archive), :bin, :out, :err;
    return $!proc.out;
}

method mount  { }
method umount { }
