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