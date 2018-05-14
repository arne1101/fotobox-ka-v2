package FotoboxApp;
use Dancer2;

my $print;

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

    $rc = printPhoto($print, $printer);
      
    set 'layout' => 'fotobox-main';
    template $template,
    {
         'message' => 'Dein Foto wird ausgedruckt',
         'text' => '',
         'foto_filename' => $print,
         'code' => ''
    }; 
};

sub printPhoto {
	
	# Durcken ueber Pi
	
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


true;