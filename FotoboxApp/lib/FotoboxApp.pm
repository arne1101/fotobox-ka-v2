package FotoboxApp;
use Dancer2;
use List::MoreUtils 'first_index'; 

# Enable Branding Option
# 1 = Branding enabled
# 0 = Branding disabled
my $OptionBranding = 0;

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
        $foto = takePicture();
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
        $foto = takePicture();
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
        $foto = takePicture();
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
         $foto = takePicture();
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
       $branding = brandingPhoto($fotosRef->[3], $secondLogo);
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
            $fotoStrip = createFotoStrip($fotosRef);
            if ($OptionBranding == 1) {
                $fotoStrip = brandingPhoto($fotoStrip);
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




# config
my $appPath = '/var/www/FotoboxApp/';
my $photoPath = '/var/www/FotoboxApp/public/gallery/';
my $thumbnailPath = $photoPath.'thumbs/';
my $externalDrive = '/media/usb/';
my $tempPath = '/var/tmp/';
my $brandingDir = '/var/www/FotoboxApp/public/branding/';

sub getPhotoPath {
	# Path for photos
	return $photoPath;
	
	}

sub getThumbnailPath {
	# Path for Thumbnails
	return $thumbnailPath;	
}

sub takePicture {

	my $rc;
	my $return;
	undef $return;
	
	# Pruefe ob Kamera angeschlossen. Return muss "usb:" im Text haben
	$return =  `gphoto2 --auto-detect`;
        # Testrun
	#$return = 'usb:';
	
	my $counter;
	my $filename;
	my $thumbExec;
	my $branding;
	
        #pruefe ob kamera angeschlossen (return enhaelt USB)
        if ($return =~ m/usb:/) {
			
			# Bildernummer holen / erstellen
			$counter = countPhoto("Fotobox");
			# Dateiname bestimmen
			$filename = "foto_$counter.jpg";
			
			# Foto aufnehmen und herunterladen
			my $return = `gphoto2 --capture-image-and-download --filename=$photoPath$filename`;
			
			# Pruefe ob Foto erfolgreich gespeichert wurde
			if (!-e $photoPath.$filename) {
				# wenn kein Foto gespeichert, dann Fehlerbild zurueck geben 
				return "no-photo-error.png";
			}
			else {
				# Thumbnail erstellen wenn Foto erfolgreich aufgenommen wurde
				$thumbExec = createThumbnail($filename);
				
               			# Save photo to an external Deive
               			# This might slow down the time from capture to viewing the picture, maybe I should make this async
               			# Copy photo to external Drive
               			copyToExternalDrive($filename);
				### ERGEBNIS WIRD HIER NICHT GEFRUEFT
			}

		
        } else {
		# wenn keine Kamera gefunden, Fehlerbild zurueck geben
		die "Kamera nicht gefunden: Detect: $return";
		#return "no-cam-error.png";
	}
	
	
	return $filename;
}

sub createThumbnail {
	
	    # Thumbnailbild erstellen
	
        my $filename = shift;
        
        my $result = 1;
        
        # epeg befehl zum verkleinern
        my $cmd = 'sudo epeg --width=1072 --height=712 '."$photoPath"."$filename".' '."$thumbnailPath"."$filename";
        
        # befehl ausfuehren und ergebnis zurueck liefern, ergebnis wird derzeit nicht ueberprueft
        my $rc = system($cmd);       
        
        return $rc;
}

sub brandingPhoto {
	
	# Wenn Branding, dann wird das Foto gebranded	
	my $foto = shift;
	# Hauptlogo
	my $brandingLogo = $brandingDir.'logo.png';
	# Zweites Logo
	my $x = shift;
	my $logo = $brandingDir.$x.".png";

	# Datei fuer Hintergrundbild
	#my $hg = $brandingDir.'HG.jpg';
	
	# Original Foto
	$orig = $photoPath.$foto;
	
	# Temporaere Bilddatei fuer Foto
	my $tmp = $brandingDir.'tmp.png';
	# Fertiges Foto
	my $branding = $photoPath.'branding_'.$foto;
	
	# Foto (Thumbnail) rotieren (-2 Grad) und in tmp Datei schreiben
	#my $cmd1 = "convert -background none -rotate -2 $thumbnailPath$foto $tmp";
	# rotiertes Foto auf Hintergrund positionieren
	#my $cmd2 = "composite -geometry +98+110 $tmp $hg $branding";
	
	# Hauptlogo platzieren und in Tempdatei schreiben
	my $cmd1 = "composite -geometry +1060+1195 $brandingLogo $orig $tmp";
	# Zweites Logo platzieren platzieren und in finales Bild schreiben
	my $cmd2 = "composite -geometry +70+60 $logo $tmp $branding";
	
	my $rc1 = system($cmd1);
	my $rc2 = system($cmd2);
	
	# Thumbnail vom fertigen Branding Foto erstellen
	my $rc3 = createThumbnail('branding_'.$foto);
	
	if ($rc1 eq 0 && $rc2 eq 0 && $rc3 eq 0) {
		# If not error
        # Copy photot to exteral drive
        # maybe this works...
        copyToExternalDrive('branding_'.$foto);
        # return branded photo
        return 'branding_'.$foto;    
	} else {
		#Fehler zurueck geben
		return "no-photo-error.png";
	}	
}

sub createFotoStrip {
	
	# 4er Fotostreifen erstellen
	
	my(@fotos) = @{(shift)};
	my $counter = countPhoto("Fotobox");
	my $fotoStrip = "strip_$counter.jpg";
	
	my $rc;
	my $cmd;

	$cmd =
	"montage -size 1024x680 -geometry 1024x680 -tile 2x -border 2 -bordercolor white "
	."$thumbnailPath$fotos[0] $thumbnailPath$fotos[1] $thumbnailPath$fotos[2] $thumbnailPath$fotos[3] $photoPath$fotoStrip";
	
	$rc = system($cmd);
	
	if ($rc eq 0) {
        	# if not error
        	# create thumbail 
		createThumbnail($fotoStrip);
	        # copy the strip to external drive
	        copyToExternalDrive($fotoStrip);
		# return strip
        	return $fotoStrip;
	} else {
        # if error, return error
		return "general-error.png";
	}
	
	
}

sub copyToExternalDrive {
	my $file = shift;
    
    	# command to copy the given file to the external Drive
    	my $cmd = "sudo cp $photoPath$file $externalDrive";
    
	# run command
    	my $rc = system($cmd);     
	if ($rc != 0) {
		die "$cmd /n $rc";
	}

}






true;
