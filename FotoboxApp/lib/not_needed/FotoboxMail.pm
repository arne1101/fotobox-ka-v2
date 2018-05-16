package FotoboxApp;
use Dancer2;
use Mail::Sender;

my $mail;


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

get '/mail/send/' => sub {

    my $to = params->{mail};
    $to =~ tr/[%40]/[@]/;
    my $subject = "Hier kommt dein Foto von fotobox-ka.de";
    my $message ="www.fotobox-ka.de";
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




sub sendMail {
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

	$sender->Attach(
		{description => 'Foto',
		 ctype => 'image/jpeg',
		 encoding => 'Base64',
		 disposition => 'attachment; filename="'.$foto.'"; type="Image"',
		 file => $attachment
		});
	$sender->Close();
}




true;
