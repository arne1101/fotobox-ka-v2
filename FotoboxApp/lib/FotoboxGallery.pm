package FotoboxApp;
use Dancer2;
use List::MoreUtils 'first_index';

my $photo_path = '/var/www/FotoboxApp/public/gallery/';
my $thumbnail_path = $photo_path.'thumbs/';

# Gallerie
get '/gallery' => sub {

    my $dir = $thumbnail_path;
    my $thumbnail_dir = '/gallery/thumbs/';

    my @gallery_foto;
    my $gallery_html;
    my $next;
    my $last;

    opendir DIR, $dir or die $!;
        while(my $entry = readdir DIR ){
            if ($OptionBranding == 1) {
                if ($entry =~ m/branding_/) {
                    push (@gallery_foto, $entry);
                }
            } else {
                if ($entry =~ m/foto_/ or $entry =~ m/strip_/) {
                   push (@gallery_foto, $entry);
                }
            }
        }
    closedir DIR;



    # Schwarzsche Transformation zum sortieren nach Zeit
    # name -> [mdate,name] -> sort() -> name
    @gallery_foto=map{$_->[1]}sort{$a->[0] <=> $b->[0]}map{[-M "$dir/$_",$_]}@gallery_foto;


        $gallery_html = '<div class="galleryWide">'."\n";
        my $i = 1;
        foreach (@gallery_foto) {
                $gallery_html = $gallery_html.'<a class="th margin-10-top margin-30-right" href="single?foto='.$_.'"><img class="gallery-thumb" src="'.$thumbnail_dir.$_.'"></a>';
            if ($i == 50) {
                last;
            }
            $i++;

         }

        $gallery_html = $gallery_html.'</div>'."\n";

    set 'layout' => 'fotobox-main';
    template 'fotobox_gallery',
    {
        'gallery' => $gallery_html
    };
};

# Zufallsbild
get '/random' => sub {

    my $dir = $thumbnail_path;
    my $thumbnail_dir = '/gallery/thumbs/';

    my @gallery;

    opendir DIR, $dir or die $!;
    while(my $entry = readdir DIR ){
            if ($entry =~ m/foto_/ or $entry =~ m/strip_/) {
               push (@gallery, $entry);
            }
    }
    closedir DIR;


        my $randomelement = $gallery_htmllery[rand @gallery];


    set 'layout' => 'fotobox-main';
    template 'fotobox_random',
    {
        'foto_filename' => $randomelement
    };
};


get '/single' => sub {

    my $foto = params->{foto};
    my $next;
    my $last;

    my $dir = $thumbnail_path;
    my $thumbnail_dir = '/gallery/thumbs/';

    my @gallery_foto;
    my $gallery_html;

    opendir DIR, $dir or die $!;
        while(my $entry = readdir DIR ){
            if ($OptionBranding == 1) {
                if ($entry =~ m/branding_/) {
                    push (@gallery_foto, $entry);
                }
            } else {
                if ($entry =~ m/foto_/ or $entry =~ m/strip_/) {
                   push (@gallery_foto, $entry);
                }
            }
        }
    closedir DIR;

    # Schwarzsche Transformation zum sortieren nach Zeit
    # name -> [mdate,name] -> sort() -> name
    @gallery_foto=map{$_->[1]}sort{$a->[0] <=> $b->[0]}map{[-M "$dir/$_",$_]}@gallery_foto;

    # Suche Foto und gib index zurueck
    my $i = first_index { /$foto/ } @gallery_foto;

    # Pruefe ob naechstes Foto (=index +1) vorhanden
    if (defined $gallery_htmlleryFoto[$i+1]) {
        # true = setze $next auf naechstes Foto
        $next = $gallery_htmlleryFoto[$i+1];
    } else {
        # false - $next = aktuelles foto
        $next = $foto;
    }

    #gleiches mit vorherigem foto
    if ($i == 0) {
        #wenn 1. Foto, dann kein Vorgaenger
        $last = $foto;
    } elsif (defined $gallery_htmlleryFoto[$i-1]) {
        $last = $gallery_htmlleryFoto[$i-1];
    } else {
        $last = $foto;
    }

    set 'layout' => 'fotobox-main-gallery';
    template 'fotobox_fotostrip',
    {
        'foto_filename' => $foto,
        'next' => $next,
        'last' => $last

    };
};

1;
