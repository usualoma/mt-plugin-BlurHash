package MT::Plugin::BlurHash;

use strict;
use warnings;
use utf8;

use File::Basename qw(basename dirname);
use BlurHash::PP qw(encode_blurhash);

sub component {
    __PACKAGE__ =~ m/::([^:]+)\z/;
}

sub plugin {
    MT->component( component() );
}

sub _get_image_data {
    my ( $img, $w, $h ) = @_;

    if ( $img->isa('MT::Image::ImageMagick') ) {
        my @pixels   = $img->{magick}->GetPixels( map => 'RGB', height => $h, width => $w );
        my $img_data = [];
        for ( my $i = 0; $i < $h; $i++ ) {
            my @line;
            for ( my $j = 0; $j < $w; $j++ ) {
                push @line, [ map { $_ / 256 } splice( @pixels, 0, 3 ) ];
            }
            push @$img_data, \@line;
        }
        return $img_data;
    }
    elsif ( $img->isa('MT::Image::Imager') ) {
        return [
            map {
                my $y      = $_;
                my @colors = $img->{imager}->getscanline( y => $y );
                [ map { [ ( $_->rgba )[ 0 .. 2 ] ] } @colors ];
            } ( 0 .. $img->{imager}->getheight - 1 )
        ];
    }
    else {
        die "This image driver is not supported: " . MT->config->ImageDriver;
    }
}

sub update_blur_hash {
    my ( $eh, $obj, $components_x, $components_y ) = @_;

    my $file_path  = $obj->file_path;
    my $fmgr       = $obj->blog ? $obj->blog->file_mgr : MT::FileMgr->new('Local');
    my $img_binary = $fmgr->get_data( $file_path, 'upload' );

    my $img = MT::Image->new( Data => $img_binary, Type => $obj->file_ext );

    return 1 unless $img;

    my ( $orig_w, $orig_h ) = $img->get_dimensions;
    my @res = $img->scale( ( ( $orig_w > $orig_h ) ? 'Width' : 'Height' ) => 100 )
        or return $eh->error( $img->errstr );
    my ( $w, $h ) = @res[ 1, 2 ];
    undef @res;

    my $img_data = _get_image_data( $img, $w, $h );

    my $hash = encode_blurhash( $img_data, $components_x, $components_y );

    $obj->meta( 'blur_hash', $hash );

    return 1;
}

sub asset_blur_hash {
    my ( $ctx, $args ) = @_;

    my $asset = $ctx->stash('asset')
        or return $ctx->_no_asset_error();
    return '' if $asset->class ne 'image';

    if ( !$asset->meta('blur_hash') ) {
        update_blur_hash(
            $ctx, $asset,
            $args->{components_x} || undef,
            $args->{components_y} || undef
        ) or return;
        $asset->save;
    }

    return $asset->meta('blur_hash') || '';
}

1;
