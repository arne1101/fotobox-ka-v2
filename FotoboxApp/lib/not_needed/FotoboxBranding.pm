package FotoboxApp;
use Dancer2;

my $branding;
my $brandingDir = '/var/www/FotoboxApp/public/branding/';


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

true;
