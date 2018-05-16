# Created by https://github.com/arne1101
$| = 1;

package FotoboxApp;
use Dancer2;
#use FotoboxApp::FotoboxMail;
#use FotoboxApp::FotoboxGallery;


my $appPath = '/var/www/FotoboxApp/';
my $photoPath = '/var/www/FotoboxApp/public/gallery/';
my $thumbnailPath = $photoPath.'thumbs/';
my $externalDrive = '/media/usb/';
my $tempPath = '/var/tmp/';

# App routes

my $singlePhoto;
my @photos;
my $photosRef = \@photos;
my $timer = 5;
my $photoStrip;
my $collage = 0;
my $seriesCount = 0;
my $do_stuff_once = 1;

get '/' => sub {

    undef $singlePhoto;
    undef $collage;
    $collage = 0;
    undef @photos ;
    $photosRef = \@photos;
    undef $photoStrip;
    $seriesCount = 0;
    $do_stuff_once = 1;

    set 'layout' => 'fotobox-main';
    template 'fotobox_index';


};

get '/new' => sub {

    undef $singlePhoto;
    undef $collage;
    $collage = 0;
    undef @photos ;
    $photosRef = \@photos;
    undef $photoStrip;
    $seriesCount = 0;
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
      $singlePhoto=$photo;
      $do_stuff_once = 0;
    }

    redirect '/showsinglephoto';

};

get '/showsinglephoto' => sub {

    template 'fotobox_foto',
        {
            'foto_filename' => $singlePhoto,
            'redirect_uri' => "fotostrip",
            'timer' => $timer,
            'number' => 'blank'
        };

};

get '/takephotoseries' => sub {
    my $photo;

    $photo = takePicture();
    $photosRef->[$seriesCount]=$photo;

    if ($photosRef->[$seriesCount] =~ m/error/) {
             redirect '/single?foto='.$photosRef->[0];
    }

    redirect '/showphotoseries';
};

get '/showphotoseries' => sub {
    my $photo;

    $photo = takePicture();
    $photosRef->[$seriesCount]=$photo;


    if ($photosRef->[$seriesCount] =~ m/error/) {
             redirect '/single?foto='.$photosRef->[0];
    }

    set 'layout' => 'fotobox-main';

    if ($seriesCount == 0) {
        template 'fotobox_foto',
            {
                'foto_filename' => $photosRef->[$seriesCount],
                'redirect_uri' => "takephotoseries",
                'timer' => $timer,
                'number' => '1_4'
            };
    }
    elsif ($seriesCount == 1) {
        template 'fotobox_foto',
            {
                'foto_filename' => $photosRef->[$seriesCount],
                'redirect_uri' => "takephotoseries",
                'timer' => $timer,
                'number' => '´2_4'
            };
    }
    elsif ($seriesCount == 2) {
        template 'fotobox_foto',
            {
                'foto_filename' => $photosRef->[$seriesCount],
                'redirect_uri' => "takephotoseries",
                'timer' => $timer,
                'number' => '´3_4'
            };
    }
    elsif ($seriesCount == 3) {
        template 'fotobox_foto',
            {
                'foto_filename' => $photosRef->[$seriesCount],
                'redirect_uri' => "montage",
                'timer' => $timer,
                'number' => '´4_4'
            };
    }

    $seriesCount++;

};

# Fake-Ansicht fŸr 4er Foto
get '/montage' => sub {

    set 'layout' => 'fotobox-main';
    template 'fotobox_montage',
    {
        'foto_filename1' => $photosRef->[0],
        'foto_filename2' => $photosRef->[1],
        'foto_filename3' => $photosRef->[2],
        'foto_filename4' => $photosRef->[3],
        'redirect_uri' => "createphotostrip",
        'timer' => $timer
    };

};

# Ansicht des letzten Fotos

get '/createphotostrip' => sub {
    my $photo;
    $photo = $singlePhoto;

    if ($collage == 1) {
        $photoStrip = createPhotoStrip($photosRef);
    } else {
        $photoStrip = $photo;
    }

   redirect '/showphotostrip';

};

get '/showfotostrip' => sub {
    set 'layout' => 'fotobox-main';
    template 'fotobox_fotostrip',
    {
        'foto_filename' => $photoStrip
    };
};

#Subroutines

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
	}
	return $filename;
}

sub createThumbnail {
	    # Thumbnailbild erstellen
        my $filename = shift;
        # epeg befehl zum verkleinern
        my $cmd = 'sudo epeg --width=1072 --height=712 '."$photoPath"."$filename".' '."$thumbnailPath"."$filename";
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
	."$thumbnailPath$photos[0] $thumbnailPath$photos[1] $thumbnailPath$photos[2] $thumbnailPath$photos[3] $photoPath$newPhotoStrip";

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
    my $cmd = "sudo cp $photoPath$file $externalDrive";

	# run command
    my $rc = system($cmd);
    if ($rc != 0) {
		die "$cmd /n $rc";
	}

}

sub countPhoto {
	my $param = shift;
	my $counter;
	my $file = $appPath.'lib/counter';

	if (defined $param && $param eq "printer") {
		$file = $appPath.'lib/print_counter';
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
