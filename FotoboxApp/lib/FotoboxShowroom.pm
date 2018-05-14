# Showroom fÅ¸r die zuletzt gemachten Fotos zum Verkauf
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
