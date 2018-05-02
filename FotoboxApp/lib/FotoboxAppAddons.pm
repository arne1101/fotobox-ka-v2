package FotoboxAppAddons;
use Dancer ':syntax';
use Fotobox;
use Net::Ping;
use List::MoreUtils 'first_index'; 

our $VERSION = '0.1';

# Enable Branding Option
# 1 = Branding enabled
# 0 = Branding disabled
my $OptionBranding = 1;

# Enable Pay for Print Option
# 1 = Pay for Print enabled
# 0 = Pay for Print disabled
my $OptionPayForPrint = 1;

my $fotobox = Fotobox->new();
my @fotos;
my $fotosRef = \@fotos;
my $upload;
my $mail;
my $print;
my $timer = 5;
my $skip = 1;
my $fotoStrip;
my $branding;


$| = 1;

get '/' => sub {
    set 'layout' => 'fotobox-main';
    template 'fotobox_addons';    
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



get '/print' => sub {
    undef $print;
    $print = params->{foto};
    $print =~ /(?:\d*\.)?\d+/g;
    
    my $message = 'Willst du das Foto wirklich drucken?';
    my $text = 'Klicke auf den Drucker um das Foto auszudrucken.';
    my $code = '<a href="print/confirm?foto='.$print.'"><img src="images/print.png" class="h64 w64 margin-30-right" ></a>';
    
   # if ($OptionPayForPrint == 1) {
   #     $message = 'Willst du das Foto kaufen?';
   #     $text = 'Melde dich mit der Fotonummer an der Kasse.';
   #     $code = '<p style="font-size:128px;">'.$&.'</p>';
   # } 

    set 'layout' => 'fotobox-main';
    template 'fotobox_print',
    {
        'message' => $message,
        'text' => $text,
        'foto_filename' => $print,
        'code' => $code
    }; 
    
    
};

get '/print/confirm' => sub {
    $print = params->{foto};
    my $template = 'fotobox_print';
    my $printer = 'fotoboxdrucker';

    my $rc;
    
    if ($OptionPayForPrint == 1) {
        #$template = 'fotobox_checkout';
        #$printer = 'Canon_Canon_CP910_ipp';
        $rc = $fotobox->copyToPrinter($print);
    } else {
        $rc = $fotobox->printPhoto($print, $printer);
    }
      
     set 'layout' => 'fotobox-main';
     template $template,
     {
         'message' => 'Dein Foto wird ausgedruckt',
         'text' => '',
         'foto_filename' => $print,
         'code' => ''
     }; 
    
    
};

# Showroom fŸr die zuletzt gemachten Fotos zum Verkauf
get '/showroom' => sub {
    
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
    
    $gal = '<ul class="small-block-grid-3">'."\n";
    my $i = 1;
    foreach (@galleryFoto) {
            $_ =~ /(?:\d*\.)?\d+/g;
             $gal = $gal.'<li><figure><a href="gallery/'.$_.'"><img src="'.$thDir.$_.'"></a><figcaption>Foto: '.$&.'</figcaption></figure></li>';
        if ($i == 6) {
            last;
        }
        $i++;
     }
        
        
    $gal = $gal.'</ul>'."\n";
     
    set 'layout' => 'fotobox-main';
    template 'fotobox_showroom',
    {
        'gallery' => $gal,
        'timer' => '60',
        'redirect' => 'showroom'
    };
};

# Kasse
get '/checkout' => sub {
    
    my $dir = $fotobox->getThumbnailPath();
    my $thDir = '/gallery/thumbs/';

    my @galleryFoto;
    my $gal;
    
    
    my $header = '<center><a href="checkout">neu laden</a></center>';
    
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
    
    $gal = '<ul class="small-block-grid-3">'."\n";
    my $i = 1;
    foreach (@galleryFoto) {
            $_ =~ /(?:\d*\.)?\d+/g;
             $gal = $gal.'<li><figure><a href="gallery/'.$_.'"><img src="'.$thDir.$_.'"></a><figcaption>Foto: '.$&.' <a href="print/confirm?foto='.$_.'">drucken</a></figcaption></figure></li>';
        if ($i == 20) {
            last;
        }
        $i++;
     }
        
    $gal = $gal.'</ul>'."\n";
     
    set 'layout' => 'fotobox-main';
    template 'fotobox_showroom',
    {
        'header' => $header,
        'gallery' => $gal,
        'timer' => '120',
        'redirect' => 'checkout'
    };
};



true;
