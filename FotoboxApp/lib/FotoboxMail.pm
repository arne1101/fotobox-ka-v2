get '/mail' => sub {
    undef $mail;
    $mail  = params->{foto};    
   
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