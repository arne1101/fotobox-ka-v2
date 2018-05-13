package FotoboxApp;
use Dancer2 ':syntax';
use Fotobox;
use Net::Ping;
use List::MoreUtils 'first_index'; 

# Enable Branding Option
# 1 = Branding enabled
# 0 = Branding disabled
my $OptionBranding = 0;


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
my $secondLogo;
my $collage = 0;
my $x1 = 1;
my $x2 = 1;
my $x3 = 1;
my $x4 = 1;
my $xGal = 1;
my $xBrand = 1;

$| = 1;

get '/' => sub {
    
    undef $collage;
    $collage = 0;
    undef $upload;
    undef @fotos ;
    $fotosRef = \@fotos;
    undef $fotoStrip;
    undef $branding;
    undef $secondLogo;
    $skip = 0;
    undef $timer;
    $timer = 5;
    undef $x1;
    undef $x2;
    undef $x3;
    undef $x4;
    $x1 = 1;
    $x2 = 1;
    $x3 = 1;
    $x4 = 1;
    $xGal = 1;
    $xBrand = 1;
    
    
    set 'layout' => 'fotobox-main';
    if ($OptionBranding == 1) {
        template 'fotobox_branding';
    } else {
        template 'fotobox_index';    
    }
    
};

get '/new' => sub {
    undef $collage;
    $collage = 0;
    undef $upload;
    undef @fotos ;
    $fotosRef = \@fotos;
    undef $fotoStrip;
    undef $branding;
    undef $secondLogo;
    $skip = 0;
    undef $timer;
    $timer = 5;
    undef $x1;
    undef $x2;
    undef $x3;
    undef $x4;
    $x1 = 1;
    $x2 = 1;
    $x3 = 1;
    $x4 = 1;
    $xGal = 1;
    $xBrand = 1;
    
    my $strip = params->{strip};
    
    if ($strip == 1) {
         redirect '/strip';
    } else {
         redirect '/start';
    }
    
};

get '/start' => sub {
    set 'layout' => 'fotobox-main';
    template 'fotobox_start',
    {
        'redirect_uri' => "foto4",
    };
};

get '/chooseLogo' => sub {
    set 'layout' => 'fotobox-main';
    template 'fotobox_logo',
    {
        'redirect_uri' => "setLogo",
    };
};

get '/setLogo' => sub {
    set 'layout' => 'fotobox-main';
    $secondLogo = params->{logo};
    redirect '/start';
};

get '/screensaver' => sub {
    set 'layout' => 'fotobox-main';
    template 'fotobox_screensaver';
};

get '/strip' => sub {
    $collage = 1;
    set 'layout' => 'fotobox-main';
        template 'fotobox_start',
    {
        'redirect_uri' => "foto1",
    };
};

get '/foto1' => sub {
    my $foto;
    if ($x1 == 1) {
        $foto = $fotobox->takePicture();
        $fotosRef->[0]=$foto;
        $x1 = 0;
    }
    
    if ($fotosRef->[0] =~ m/error/) {
             redirect '/single?foto='.$fotosRef->[0];
    }
    
    set 'layout' => 'fotobox-main';
    template 'fotobox_foto',
    {
        'foto_filename' => $fotosRef->[0],
        'redirect_uri' => "foto2",
        'timer' => $timer,
        'number' => '1_4'
    };
};

get '/foto2' => sub {
    
    my $foto;
    if ($x2 == 1) {
        $foto = $fotobox->takePicture();
        $fotosRef->[1]=$foto;
        $x2 = 0;
    }
    if ($fotosRef->[1] =~ m/error/) {
             redirect '/single?foto='.$fotosRef->[1];
    }
   
    
    set 'layout' => 'fotobox-main';
    template 'fotobox_foto',
    {
        'foto_filename' => $fotosRef->[1],
        'redirect_uri' => "foto3",
        'timer' => $timer,
        'number' => '2_4'
    };
};

get '/foto3' => sub {

    my $foto;
    if ($x3 == 1) {
        $foto = $fotobox->takePicture();
        $fotosRef->[2]=$foto;
        $x3 = 0;
    }
    if ($fotosRef->[2] =~ m/error/) {
             redirect '/single?foto='.$fotosRef->[2];
    }

    
    set 'layout' => 'fotobox-main';
    template 'fotobox_foto',
    {
        'foto_filename' => $fotosRef->[2],
        'redirect_uri' => "foto4",
        'timer' => $timer,
        'number' => '3_4'
    };
};

get '/foto4' => sub {
    my $foto;
    
    if ($x4 == 1) {
         $foto = $fotobox->takePicture();
         $fotosRef->[3]=$foto;
         $x4 = 0;
    }

    $timer = 0;
    
    set 'layout' => 'fotobox-main';
    if ($collage == 0) {
       
        # Wenn Einzelfoto, dann gehe zu direkt zu Fotoanzeige
        if ($OptionBranding == 1) {
            template 'fotobox_foto',
            {
                'foto_filename' => $fotosRef->[3],
                'redirect_uri' => "branding",
                'timer' => $timer,
                'number' => 'blank'
            };
        } else
        {
            template 'fotobox_foto',
            {
                'foto_filename' => $fotosRef->[3],
                'redirect_uri' => "fotostrip",
                'timer' => $timer,
                'number' => 'blank'
            };
        }
    } else {
        # Wenn 4er Foto, dann gehe zu Fake-Anzeige vor Generierung der Collage
        template 'fotobox_foto',
        {
            'foto_filename' => $fotosRef->[3],
            'redirect_uri' => "fotostrip",
            'timer' => $timer,
            'number' => '4_4'
        };
        
    }
};

# Branding Foto Ansicht
get '/branding' => sub {
    
    if ($xBrand == 1) {
       $branding = $fotobox->brandingPhoto($fotosRef->[3], $secondLogo);
       $xBrand = 0;
    } 
    
    $timer = 0;
    
    set 'layout' => 'fotobox-main';
    template 'fotobox_foto',  {
            'foto_filename' => $branding,
            'redirect_uri' => "fotostrip",
            'timer' => $timer,
            'number' => 'blank'
    };
};

# Fake-Ansicht fŸr 4er Foto
get '/montage' => sub {
    
    set 'layout' => 'fotobox-main';
    template 'fotobox_montage',
    {
        'foto_filename1' => $fotosRef->[0],
        'foto_filename2' => $fotosRef->[1],
        'foto_filename3' => $fotosRef->[2],
        'foto_filename4' => $fotosRef->[3],
        'redirect_uri' => "fotostrip",
        'timer' => $timer
    };
    
};

# Ansicht des letzten Fotos

get '/fotostrip' => sub {
    my $photo;
    if ($OptionBranding == 1) {
        $photo = $branding;
    } else {
        $photo = $fotosRef->[3];
    }
    
    if ($skip eq 0){
        if ($collage == 1) {
            $fotoStrip = $fotobox->createFotoStrip($fotosRef);
            if ($OptionBranding == 1) {
                $fotoStrip = $fotobox->brandingPhoto($fotoStrip);
            }
            $skip = 1;      
        } if ($collage == 0) {
            $fotoStrip = $photo;                   
        } 
    }
    
    $upload=$fotoStrip;
   
    
    set 'layout' => 'fotobox-main';
    template 'fotobox_fotostrip',
    {
        'foto_filename' => $fotoStrip
    };
    
};




# Gallerie
get '/gallery' => sub {
    
    my $dir = $fotobox->getThumbnailPath();
    my $thDir = '/gallery/thumbs/';

    my @galleryFoto;
    my $gal;
    my $next;
    my $last;

    if ($xGal == 1) {
        
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
    
    $xGal = 0;
    }
        
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
    
    $xGal = 1;
    
    
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

get '/gif' => sub {
    
    my $foto = params->{foto};
    
    $foto =~ tr/\.jpg/\.gif/;
    
    set 'layout' => 'fotobox-main-gallery';
    template 'fotobox_fotostrip',
    {
        'foto_filename' => $foto, 
    };
    
}


get '/mail' => sub {
    undef $mail;
    $mail  = params->{foto};
#    my $p = Net::Ping->new();
#    if ($p->ping("www.fotobox-ka.de")) {
#       
#    } else {
#        redirect '/mail/offline/';
#    }
#    $p->close();
    
   
    set 'layout' => 'fotobox-main';
    template 'fotobox_mail',
    {
        'message' => 'E-Mail',
        'text' => 'Hier kannst du dein Foto per Mail versenden.',
        'foto_filename' => $mail,
        'code' => ''
    };
    
};

get '/mail/offline/' => sub {
    set 'layout' => 'fotobox-main';
    template 'fotobox_mail',
    {
        'message' => 'Sorry. E-Mail steht nicht zur Verf&uuml;gung.',
         'text' => 'Es besteht keine Verbindung zum Internet.',
        'foto_filename' => $mail,
        'code' => ''
    };
};

get '/mail/send/' => sub {
    
    my $to = params->{mail};
    $to =~ tr/[%40]/[@]/;
    my $subject = "Hier kommt dein Foto von fotobox-ka.de";
    my $message ="www.fotobox-ka.de<br /><br />www.facebook.com/fotobox.ka";
    my $foto = $mail;
    
    
    $fotobox->sendMail($to,$subject,$message,$foto);
    
    set 'layout' => 'fotobox-main';
    template 'fotobox_mail',
    {
        'message' => 'Viel Spa&szlig; mit deinem Foto!',
        'text' => 'E-Mail wurde an '.$to.' verschickt. ',
        'warning' =>'Bitte schaue auch in deinem SPAM-Ordner nach.',
        'foto_filename' => $mail,  
    };
};




get '/print' => sub {
    undef $print;
    $print = params->{foto};
    $print =~ /(?:\d*\.)?\d+/g;
    
    my $message = 'Willst du das Foto wirklich drucken?';
    my $text = 'Klicke auf den Drucker um das Foto auszudrucken.';
    my $code = '<a href="print/confirm?foto='.$print.'"><img src="images/print.png" class="h64 w64 margin-30-right" ></a>';


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

    $rc = $fotobox->printPhoto($print, $printer);
      
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
