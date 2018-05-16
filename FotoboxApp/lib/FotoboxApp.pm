# Created by https://github.com/arne1101
$| = 1;

package FotoboxApp;
use Dancer2;
#use FotoboxApp::FotoboxMail;
#use FotoboxApp::FotoboxGallery;


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

    $photo = takePicture();
    $photos_ref->[$series_count]=$photo;

    if ($photos_ref->[$series_count] =~ m/error/) {
             redirect '/single?foto='.$photos_ref->[0];
    }

    redirect '/showphotoseries';
};

get '/showphotoseries' => sub {
    my $photo;

    $photo = takePicture();
    $photos_ref->[$series_count]=$photo;


    if ($photos_ref->[$series_count] =~ m/error/) {
             redirect '/single?foto='.$photos_ref->[0];
    }

    set 'layout' => 'fotobox-main';

    if ($series_count == 0) {
        template 'fotobox_foto',
            {
                'foto_filename' => $photos_ref->[$series_count],
                'redirect_uri' => "takephotoseries",
                'timer' => $timer,
                'number' => '1_4'
            };
    }
    elsif ($series_count == 1) {
        template 'fotobox_foto',
            {
                'foto_filename' => $photos_ref->[$series_count],
                'redirect_uri' => "takephotoseries",
                'timer' => $timer,
                'number' => '´2_4'
            };
    }
    elsif ($series_count == 2) {
        template 'fotobox_foto',
            {
                'foto_filename' => $photos_ref->[$series_count],
                'redirect_uri' => "takephotoseries",
                'timer' => $timer,
                'number' => '´3_4'
            };
    }
    elsif ($series_count == 3) {
        template 'fotobox_foto',
            {
                'foto_filename' => $photos_ref->[$series_count],
                'redirect_uri' => "montage",
                'timer' => $timer,
                'number' => '´4_4'
            };
    }

    $series_count++;

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
    my $photo;
    $photo = $single_photo;

    if ($collage == 1) {
        $photo_strip = createPhotoStrip($photos_ref);
    } else {
        $photo_strip = $photo;
    }

   redirect '/showphotostrip';

};

get '/showfotostrip' => sub {
    set 'layout' => 'fotobox-main';
    template 'fotobox_fotostrip',
    {
        'foto_filename' => $photo_strip
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
	my $thumbExec;

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

true;
