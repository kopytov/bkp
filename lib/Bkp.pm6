subset DirPath   of Str where *.IO.d;
subset FilePath  of Str where *.IO.f;
subset GzipLevel of Int where 0 < * < 10;
subset CTID      of Cool where { "/vz/private/$_".IO.d }
subset Cipher    of Str where * ~~ /^ <[a..z 0..9 -]>+ $/;

unit module Bkp;
