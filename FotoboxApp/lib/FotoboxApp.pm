# Created by https://github.com/arne1101
$| = 1;

package FotoboxApp;
use Dancer2;
use List::MoreUtils 'first_index'; 

my $app_path = '/var/www/FotoboxApp/';
my $photo_path = '/var/www/FotoboxApp/public/gallery/';
my $thumbnail_path = $photo_path.'thumbs/';
my $external_drive = '/media/usb/';
my $temp_path = '/var/tmp/';

# App routes

my $single_photo;
my @photos;
my $photos_ref = \@photos;
my $timer = 5;
my $photo_strip;
my $collage = 0;
my $series_count = 0;
my $do_stuff_once = 1;

get '/' => sub {

    undef $single_photo;
    undef $collage;
    $collage = 0;
    undef @photos ;
    $photos_ref = \@photos;
    undef $photo_strip;
    $series_count = 0;
    $do_stuff_once = 1;

    set 'layout' => 'fotobox-main';
    template 'fotobox_index';


};

get '/new' => sub {

    undef $single_photo;
    undef $collage;
    $collage = 0;
    undef @photos ;
    $photos_ref = \@photos;
    undef $photo_strip;
    $series_count = 0;
    $do_stuff_once = 1;


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
        'redirect_uri' => "takesinglephoto",
    };
};

get '/strip' => sub {
    $collage = 1;
    set 'layout' => 'fotobox-main';
        template 'fotobox_start',
    {
        'redirect_uri' => "takephotoseries",
    };
};


get '/takesinglephoto' => sub {

    my $photo;

    if ($do_stuff_once == 1) {
      $photo = takePicture();
      $single_photo=$photo;
      $do_stuff_once = 0;
    }

    redirect '/showsinglephoto';

};

get '/showsinglephoto' => sub {

    $do_stuff_once = 1;
    set 'layout' => 'fotobox-main';
    template 'fotobox_fotostrip',
        {
            'foto_filename' => $single_photo,
            'redirect_uri' => "fotostrip",
            'timer' => $timer,
            'number' => 'blank'
        };

};

get '/takephotoseries' => sub {
    my $photo;

    if ($do_stuff_once == 1) {
      $photo = takePicture();
      $photos_ref->[$series_count]=$photo;
      $do_stuff_once = 0;
    }

    if ($photos_ref->[$series_count] =~ m/error/) {
             redirect '/single?foto='.$photos_ref->[$series_count];
    }

    redirect '/showphotoseries';
};

get '/showphotoseries' => sub {
    my $photo;
    $series_count++;
    $do_stuff_once = 1;

    if ($photos_ref->[$series_count] =~ m/error/) {
             redirect '/single?foto='.$photos_ref->[$series_count];
    }

    my $redirect_uri = "takephotoseries";
    if ($series_count == 4) {
      $redirect_uri = "montage";
    }

    my $number = $series_count - 1;
    my $number_image_string = $series_count."_4";

    set 'layout' => 'fotobox-main';
    template 'fotobox_foto',
        {
            'foto_filename' => $photos_ref->[$number],
            'redirect_uri' => $redirect_uri,
            'timer' => $timer,
            'number' => $number_image_string
        };
};

# Fake-Ansicht fŸr 4er Foto
get '/montage' => sub {

    set 'layout' => 'fotobox-main';
    template 'fotobox_montage',
    {
        'foto_filename1' => $photos_ref->[0],
        'foto_filename2' => $photos_ref->[1],
        'foto_filename3' => $photos_ref->[2],
        'foto_filename4' => $photos_ref->[3],
        'redirect_uri' => "createphotostrip",
        'timer' => $timer
    };

};

# Ansicht des letzten Fotos

get '/createphotostrip' => sub {

  if ($do_stuff_once == 1) {
        $photo_strip = createPhotoStrip($photos_ref);
        $do_stuff_once = 0;
    }
   redirect '/showphotostrip';

};

get '/showphotostrip' => sub {

    $do_stuff_once = 1;

    set 'layout' => 'fotobox-main';
    template 'fotobox_fotostrip',
    {
        'foto_filename' => $photo_strip
    };
};

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
                if ($entry =~ m/foto_/ or $entry =~ m/strip_/) {
                   push (@gallery_foto, $entry);
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

    my $dir = $thumbnail_path;
    my $thumbnail_dir = '/gallery/thumbs/';

    my @gallery_foto;
    my $gallery_html;

    opendir DIR, $dir or die $!;
        while(my $entry = readdir DIR ){
                if ($entry =~ m/foto_/ or $entry =~ m/strip_/) {
                   push (@gallery_foto, $entry);
                }
        }
    closedir DIR;

    # Schwarzsche Transformation zum sortieren nach Zeit
    # name -> [mdate,name] -> sort() -> name
    @gallery_foto=map{$_->[1]}sort{$a->[0] <=> $b->[0]}map{[-M "$dir/$_",$_]}@gallery_foto;

    # Suche Foto und gib index zurueck
    my $i = first_index { /$foto/ } @gallery_foto;

    # Pruefe ob naechstes Foto (=index +1) vorhanden
    if (defined $gallery_foto[$i+1]) {
        # true = setze $next auf naechstes Foto
        $next = $gallery_foto[$i+1];
    } else {
        # false - $next = aktuelles foto
        $next = $foto;
    }

    #gleiches mit vorherigem foto
    if ($i == 0) {
        #wenn 1. Foto, dann kein Vorgaenger
        $last = $foto;
    } elsif (defined $gallery_foto[$i-1]) {
        $last = $gallery_foto[$i-1];
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
    
    my $gif = params->{foto};
    
    $gif =~ tr/\.jpg/\.gif/;
    
    set 'layout' => 'fotobox-main-gallery';
    template 'fotobox_fotostrip',
    {
        'foto_filename' => $gif, 
    };
    
};



#Subroutines

sub getPhotoPath {
	# Path for photos
	return $photo_path;

	}

sub getThumbnailPath {
	# Path for Thumbnails
	return $thumbnail_path;
}

sub takePicture {

	my $rc;
	my $return;
	my $counter;
	my $filename;
	my $thumb_execution_return;

	# Pruefe ob Kamera angeschlossen. Return muss "usb:" im Text haben
	$return =  `gphoto2 --auto-detect`;



      #pruefe ob kamera angeschlossen (return enhaelt USB)
      if ($return =~ m/usb:/) {

			# Bildernummer holen / erstellen
			$counter = countPhoto();
			# Dateiname bestimmen
			$filename = "foto_$counter.jpg";

			# Foto aufnehmen und herunterladen
			my $return = `gphoto2 --capture-image-and-download --filename=$photo_path$filename`;

			# Pruefe ob Foto erfolgreich gespeichert wurde
			if (!-e $photo_path.$filename) {
				# wenn kein Foto gespeichert, dann Fehlerbild zurueck geben
				return "no-photo-error.png";
			}
			else {
				    # Thumbnail erstellen wenn Foto erfolgreich aufgenommen wurde
				    $thumb_execution_return = createThumbnail($filename);
            # Save photo to an external Deive
            # This might slow down the time from capture to viewing the picture, maybe I should make this async
            # Copy photo to external Drive
            copyToExternalDrive($filename);
		        ### ERGEBNIS WIRD HIER NICHT GEFRUEFT
			}
        } else {
            # wenn keine Kamera gefunden, Fehlerbild zurueck geben
            #die "Kamera nicht gefunden: Detect: $return";
            return "no-cam-error.png";
	}
	return $filename;
}

sub createThumbnail {
	    # Thumbnailbild erstellen
        my $filename = shift;
        # epeg befehl zum verkleinern
        my $cmd = 'sudo epeg --width=1072 --height=712 '."$photo_path"."$filename".' '."$thumbnail_path"."$filename";
        # befehl ausfuehren und ergebnis zurueck liefern, ergebnis wird derzeit nicht ueberprueft
        my $rc = system($cmd);
        return $rc;
}


sub createPhotoStrip {
	# 4er Fotostreifen erstellen
	my(@photos) = @{(shift)};
	my $counter = countPhoto();
	my $newPhotoStrip = "strip_$counter.jpg";

	my $rc;
	my $cmd;

	$cmd =
	"montage -size 1024x680 -geometry 1024x680 -tile 2x -border 2 -bordercolor white "
	."$thumbnail_path$photos[0] $thumbnail_path$photos[1] $thumbnail_path$photos[2] $thumbnail_path$photos[3] $photo_path$newPhotoStrip";

	$rc = system($cmd);

	if ($rc eq 0) {
        	# if not error
        	# create thumbail
            createThumbnail($newPhotoStrip);
	        # copy the strip to external drive
	        copyToExternalDrive($newPhotoStrip);
            # create GIF
            createGif($counter, $photos[0], $photos[1], $photos[2], $photos[3]);
            # return strip
        	return $newPhotoStrip;
	} else {
        # if error, return error image
		return "general-error.png";
	}


}

sub copyToExternalDrive {
	my $file = shift;

    # command to copy the given file to the external Drive
    my $cmd = "sudo cp $photo_path$file $external_drive";

	# run command
    my $rc = system($cmd);
    if ($rc != 0) {
		die "$cmd /n $rc";
	}

}

sub countPhoto {
	my $param = shift;
	my $counter;
	my $file = $app_path.'lib/counter';

	if (defined $param && $param eq "printer") {
		$file = $app_path.'lib/print_counter';
	}

	#Pruefe ob Counter Datei vorhanden
	if (!-e $file) {
		#wenn datei nicht vorhanden, anlegen mit Inhalt "0"
		open COUNT, "> $file" or die "Cannot write file $file";
		print COUNT "0";
		close COUNT;
	}

	# Zaehlerdatei zum Lesen oeffnen
	open COUNT, "< $file" or die "Counter file $file not found";
	$counter = <COUNT>; # Zaehlerstand lesen
	close COUNT; # Datei schliessen

	$counter++;

	# Zaehlerdatei zum Schreiben oeffnen
	open COUNT, "> $file" or die "Cannot write file $file";
	print COUNT $counter; # aktuellen Zaehlerstand in Datei schreiben
	close COUNT;

	return $counter;
}

sub createGif {

	my $counter = shift;
    my $photo1 = shift;
    my $photo2 = shift;
    my $photo3 = shift;
    my $photo4 = shift;
	
    my $gif  = "strip_$counter.gif";
    
    my $rc;
    my $cmd = "convert -delay 100 -loop 0 $photoPath$photo1 $photoPath$photo2 $photoPath$photo3 $photoPath$photo4 $photoPath$gif";
    
    $rc = system($cmd);
    
    if ($rc == 0) {
        	# if not error
	        # copy the strip to external drive
	        copyToExternalDrive($gif);
            # return strip
        	return $gif;
	} else {
            # if error, return error
            return "general-error.png";
	}
    
    

}

1;
