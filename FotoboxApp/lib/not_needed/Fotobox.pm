#!/usr/bin/perl

# Module file fotobox-ka-v2

package Fotobox;
use Mail::Sender;


# config
my $appPath = '/var/www/FotoboxApp/';
my $photoPath = '/var/www/FotoboxApp/public/gallery/';
my $thumbnailPath = $photoPath.'thumbs/';
my $externalDrive = '/media/usb/';
my $tempPath = '/var/tmp/';
my $brandingDir = '/var/www/FotoboxApp/public/branding/';

sub new {
	my $Objekt = shift;
	my $Referenz = {};
	bless($Referenz,$Objekt);
	return($Referenz);
}

sub getPhotoPath {
	my $Objekt = shift;
	# Path for photos
	return $photoPath;

	}

sub getThumbnailPath {
	my $Objekt = shift;
	# Path for Thumbnails
	return $thumbnailPath;
}

sub takePicture {

	my $Objekt = shift;
	my $rc;
	my $return;
	#my $lockfile = "/var/www/FotoboxApp/lib/lock";
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
				$thumbExec = createThumbnail("Fotobox", $filename);

               			# Save photo to an external Deive
               			# This might slow down the time from capture to viewing the picture, maybe I should make this async
               			# Copy photo to external Drive
               			copyToExternalDrive("Fotobox", $filename);
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

	my $Objekt = shift;
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

	my $Objekt = shift;
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
	my $rc3 = createThumbnail("Fotobox", 'branding_'.$foto);

	if ($rc1 eq 0 && $rc2 eq 0 && $rc3 eq 0) {
		# If not error
        # Copy photot to exteral drive
        # maybe this works...
        copyToExternalDrive("Fotobox", 'branding_'.$foto);
        # return branded photo
        return 'branding_'.$foto;
	} else {
		#Fehler zurueck geben
		return "no-photo-error.png";
	}
}

sub createFotoStrip {

	# 4er Fotostreifen erstellen

	my $Objekt = shift;
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
		createThumbnail("Fotobox", $fotoStrip);
	        # copy the strip to external drive
	        copyToExternalDrive("Fotobox", $fotoStrip);
		# return strip
        	return $fotoStrip;
	} else {
        # if error, return error
		return "general-error.png";
	}


}

sub copyToExternalDrive {
	my $Objekt = shift;
	my $file = shift;

    	# command to copy the given file to the external Drive
    	my $cmd = "sudo cp $photoPath$file $externalDrive";

	# run command
    	my $rc = system($cmd);
	if ($rc != 0) {
		die "$cmd /n $rc";
	}

}


sub sendMail {
	my $Objekt = shift;
	my $to = shift;
	my $subject = shift;
	my $message = shift;
	my $foto = shift;

	my $attachment = $photoPath.$foto;

	my $sender = new Mail::Sender {
                smtp => 'fotobox.local',
				port => '25',
                from => 'info@fotobox-ka.de',
                auth => 'LOGIN',
                authid => '...',
                authpwd => '...',
                on_errors => 'die',
        }  or die "Can't create the Mail::Sender object: $Mail::Sender::Error\n";


	 $sender->OpenMultipart({
		  to => "$to",
                  subject  => "$subject",
                  ctype    => "text/html; charset=iso-8859-1",
                  encoding => "quoted-printable"
		}) or die $Mail::Sender::Error,"\n";

	#$sender->Body($message);
	$sender->Attach(
		{description => 'Foto',
		 ctype => 'image/jpeg',
		 encoding => 'Base64',
		 disposition => 'attachment; filename="'.$foto.'"; type="Image"',
		 file => $attachment
		});
	$sender->Close();
}



sub printPhoto {

	# Durcken ueber Pi

	my $Objekt = shift;
	my $foto = shift;
	my $printer = shift;

	my $return;
	$return = `lpstat -p`;
	my $rc;

	if ($return =~ m/fotoboxdrucker/ or $return =~ m/Canon_Canon_CP910_ipp/) {
		$rc = system("lp -d $printer $photoPath$foto");
	} else {
		return 'no-printer-error';
	}

	if ($rc == 0) {
		return 'success';
	} else {
		return "error:$rc";
	}
}

sub copyToPrinter {

	# Drucken ueber Drucker auf anderem PC
	# Foto wird nur in bestimmten Ordner kopiert

	my $Objekt = shift;
	my $foto = shift;

	$foto =~ /(?:\d*\.)?\d+/g;

	my $prefix = "foto_";

	if ($foto =~ /strip/m) {
		$prefix = "strip_";
	} elsif ($foto =~ /branding/m){
		$prefix = "branding_";
	}

	my $filename = $prefix.$&.'_druck_'.countPhoto("Fotobox","printer").'.jpg';
	my $printPath = $appPath."public/print/";

	my $cmd = "cp $photoPath$foto $printPath$filename";

	system($cmd);

	return 0;
}

sub countPhoto {
	my $Objekt = shift;
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

1;
