package FotoboxApp;
use Dancer2;
use List::MoreUtils 'first_index'; 

# Gallerie
get '/gallery' => sub {
    
    my $dir = $fotobox->getThumbnailPath();
    my $thDir = '/gallery/thumbs/';

    my @galleryFoto;
    my $gal;
    my $next;
    my $last;

    opendir DIR, $dir or die $!;
        while(my $entry = readdir DIR ){
            if ($OptionBranding == 1) {
                if ($entry =~ m/branding_/) {
                    push (@galleryFoto, $entry);
                }
            } else {
                if ($entry =~ m/foto_/ or $entry =~ m/strip_/) {
                   push (@galleryFoto, $entry);
                }
            }
        }
    closedir DIR;
    

        
    # Schwarzsche Transformation zum sortieren nach Zeit
    # name -> [mdate,name] -> sort() -> name
    @galleryFoto=map{$_->[1]}sort{$a->[0] <=> $b->[0]}map{[-M "$dir/$_",$_]}@galleryFoto;
    
    
        $gal = '<div class="galleryWide">'."\n";
        my $i = 1;
        foreach (@galleryFoto) { 
                $gal = $gal.'<a class="th margin-10-top margin-30-right" href="single?foto='.$_.'"><img class="gallery-thumb" src="'.$thDir.$_.'"></a>';
            if ($i == 50) {
                last;
            }
            $i++;
            
         }
        
        $gal = $gal.'</div>'."\n";
     
    set 'layout' => 'fotobox-main';
    template 'fotobox_gallery',
    {
        'gallery' => $gal
    };
};

# Zufallsbild
get '/random' => sub {
    
    my $dir = $fotobox->getPhotoPath();
    my $thDir = '/gallery/thumbs/';
    my @gallery;
        
    opendir DIR, $dir or die $!;
    while(my $entry = readdir DIR ){
        if ($OptionBranding == 1) {
            if ($entry =~ m/branding_/) {
                push (@gallery, $entry);
            }
        } else {
            if ($entry =~ m/foto_/ or $entry =~ m/strip_/) {
               push (@gallery, $entry);
            }
        }
    }
    closedir DIR;
    
      
        my $randomelement = $gallery[rand @gallery];
       
     
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
    
    my $dir = $fotobox->getThumbnailPath();
    my $thDir = '/gallery/thumbs/';
    my @galleryFoto;
    my $gal;
    
    opendir DIR, $dir or die $!;
        while(my $entry = readdir DIR ){
            if ($OptionBranding == 1) {
                if ($entry =~ m/branding_/) {
                    push (@galleryFoto, $entry);
                }
            } else {
                if ($entry =~ m/foto_/ or $entry =~ m/strip_/) {
                   push (@galleryFoto, $entry);
                }
            }
        }
    closedir DIR;
    
    # Schwarzsche Transformation zum sortieren nach Zeit
    # name -> [mdate,name] -> sort() -> name
    @galleryFoto=map{$_->[1]}sort{$a->[0] <=> $b->[0]}map{[-M "$dir/$_",$_]}@galleryFoto;
    
    # Suche Foto und gib index zurueck
    my $i = first_index { /$foto/ } @galleryFoto;
    
    # Pruefe ob naechstes Foto (=index +1) vorhanden
    if (defined $galleryFoto[$i+1]) {
        # true = setze $next auf naechstes Foto
        $next = $galleryFoto[$i+1];
    } else {
        # false - $next = aktuelles foto
        $next = $foto;
    }
    
    #gleiches mit vorherigem foto
    if ($i == 0) {
        #wenn 1. Foto, dann kein Vorgaenger
        $last = $foto;
    } elsif (defined $galleryFoto[$i-1]) {
        $last = $galleryFoto[$i-1];
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