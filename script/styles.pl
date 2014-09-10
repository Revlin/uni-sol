# This file defines routes for stylesheets (css templates)
use Mojo::Log;

get '/main.css' => sub {
	my $self = shift;
	$self->render( template => 'main', format => 'css', handler => 'ep' );
};

get '/width.css' => sub {
	my $self = shift;
	$self->render( template => 'width', format => 'css', handler => 'ep' );
};

1;
