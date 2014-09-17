# This file defines routes for uni-sol (https://github.com/uni-sol/uni-sol)

get '/my-mojo' => sub {
	# Redirect to My Mojolicious blog
	my $self = shift;
	my ($getp, $geta) = (0, 0);
	$getp = $self->param('p') if( $self->param('p') );
	$geta = $self->param('p') if( $self->param('a') );
	myMojo($self, $getp, $geta);
};
	
sub myMojo {
	my ($self, $getp, $geta) = @_;
	my (@gotten, @rendered);
	my ($responce, $gotten);
	my $apppath = $self->req->url->base.'/my-mojo/';
	my $abspath = 'http://blogs.perl.org/users/revlin_john/';
	if( $getp ) {
		$gotten = $ua->get($abspath."?p=$getp")->res->dom;
	} elsif( $geta ) {
		$gotten = $ua->get($abspath."?author=$geta")->res->dom;
	} else {
		$gotten = $ua->get($abspath)->res->dom;
	}
	@gotten = split( "\n", $gotten );

	for my $fline (@gotten) {
		# Make sure that linked resources use absolute URIs
		if ( ($fline =~ /(<a)/) and ($fline =~ /(href=){1}(\'?)(\"?)((\w|\-|\_|\/|\.|\#)+)(\'?)(\"?)/) ) {
			my $resname = $4;
			print "<!--Resource $resname -->\n";
			unless( $fline =~ /(http\:|javascript\:|mailto\:|\/\/)/ ) {
				if( $resname ) {
					$fline =~ s/$resname/$apppath$resname/;
				} 
			} else {
				$fline =~ s/$abspath/$apppath/;
			}
			print $fline."\n";
			$responce = $fline;

		} elsif ( ($fline =~ /(<link)/) and ($fline =~ /stylesheet/) and ($fline =~ /(href=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ) {
			my $resname = $4;
			print "<!--Resource $resname -->\n";
			unless( $fline =~ /(http\:|javascript\:|mailto\:|\/\/)/ ) {
					$fline =~ s/$resname/$abspath$resname/;
					#print $fline."\n";
			} 
			$responce = $fline;

		} elsif ( ($fline =~ /(<script)/) and ($fline =~ /(src=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ) {
			my $resname = $4;
			print "<!--Resource $resname -->\n";
			unless( $fline =~ /(http\:|javascript\:|mailto\:|\/\/)/ ) {
				$fline =~ s/$resname/$abspath$resname/;
				#print $fline."\n";
			} 
			$responce = $fline;
    
		} elsif ( ($fline =~ /(<iframe)/) and ($fline =~ /(src=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ) {
			my $resname = $4;
			print "<!--Resource $resname -->\n";
			unless ($fline =~ /http\:/) {
				$fline =~ s/$resname/$abspath$resname/;
				#print $fline."\n";
			} 
			$responce = $fline;

		} elsif ( ($fline =~ /(<img)/s) and ($fline =~ /(src=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ){
			my $resname = $4;
			print "<!--Resource $resname -->\n";
			unless ($fline =~ /http\:/) {
				$fline =~ s/$resname/$abspath$resname/;
				#print $fline."\n";
			} 
			$responce = $fline;
 
		} elsif ( ($fline =~ /(<source)/s) and ($fline =~ /(src=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ){
			my $resname = $4;
			print "<!--Resource $resname -->\n";
			unless ($fline =~ /http\:/) {
				$fline =~ s/$resname/$abspath$resname/;
				#print $fline."\n";
			} 
			$responce = $fline;
      
		}  else {
			$responce = $fline;
		}
		@rendered = (@rendered, $responce);
	}
	$self->render( inline => ( join "\n", @rendered ) );
}

1;
