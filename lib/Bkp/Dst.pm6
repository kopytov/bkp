unit class Bkp::Dst;

has $.prefix is required;
has $.src    is required;
has %.plan   is required;

has %!archives-of;
has $!archives-of-initialized = False;

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
    my @archives = self.enumerate.sort;
    for @archives -> $archive {
        next if $archive !~~ self.is-archive;
        my $period = ~$1;
        %!archives-of{$period} //= [];
        %!archives-of{$period}.push($archive);
    }
    return %!archives-of;
}

method all-archives () {
    self.archives.values.map( { |$_ } ).sort;
}

method next-archive () {
    my $today = DateTime.now.Date;

    # last archive
    if self.all-archives.elems > 0 {
        my $last-archive = self.all-archives[* - 1];
        if $last-archive ~~ self.is-archive {
            my $date = Date.new(~$0);
            return $last-archive if $date == $today;
        }
    }

    # next archive
    my %archives-of = self.archives;
    my %days-of     = y => 365, m => 30, w => 7, d => 1;
    my $next-period;
    for <y m w d> -> $period {
        next if !%!plan{$period};
        $next-period = $period;
        last if !%archives-of{$period};
        my $last-archive = %archives-of{$period}[* - 1];
        next if $last-archive !~~ self.is-archive($period);
        my $date = Date.new(~$0);
        last if $date <= $today.earlier( days => %days-of{$period} );
    }
    return "$!prefix-$today-$next-period\.{$!src.suffix}";
}

method SEND () {
    self.send;
    $!archives-of-initialized = False;
    %!archives-of             = ();
    self.rotate;
}

method rotate () {
    my %archives-of = self.archives;
    my %sum         = <y m w d>.map: -> $period {
        $period => %archives-of{$period}:exists
                ?? %archives-of{$period}.elems
                !! 0;
    };
    my %num_excess  = <y m w d>.map: -> $period {
        next if !%!plan{$period};
        next if !%sum{$period};
        my $num_excess = %sum{$period} - %!plan{$period};
        next if $num_excess <= 0;
        $period => $num_excess;
    }
    return if !%num_excess.elems;

    for %num_excess.kv -> $period, $num_excess {
        for %archives-of{$period}[ ^$num_excess ] -> $archive {
            self.delete($archive);
        }
    }
}
