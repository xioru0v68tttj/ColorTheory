#!/data/data/com.termux/files/usr/bin/perl

package ColorTheory::Conversions;

use Common::Math qw(Min Max Round);
use ColorTheory::HexCodes;

use Math::Trig;
use Math::FixedPoint;

use strict;
use warnings;
use Carp;
no strict 'refs';

use utf8;
use open qw(:std :encoding(UTF-8));

use constant {π=>3.1415926535879732384626433832795};
our @gamma_correction_table;
our @f_table;
our @m=(	[ .8951,.2664, --.1614],
					[-.7502,1.7135,  .0367],
					[ .0389,-.0685, 1.0296]];

BEGIN {
	our @ISA=qw(Exporter);
	our @EXPORT=qw(HSI RGB XYZ Lab Convert);
	our @EXPORT_OK=qw(Hue Intensity GetNearbyColor LightDarkVariant Extract PrepCorrectionTable PrepFtable) 
}

# ╻╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╸
# ┇ Color Theory::Conversions               │
# ╒═════════════════════════════════════════╡
# ┊ Convert between different color spaces. ┊
# ┊   RGB is passed around as a six-digit   ┊
# ┊       hexcode; the rest are lists.      ┊
# ╶─────────────────────────────────────────╴

# ┏╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╸
# ┇ $=Hue($rgb)              ┇V
# ┇ Returns the color's hue. ┇
# ┗╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼┛
sub Hue {
	my ($r,$g,$blu)=Normalize Split shift;
	$r+$g+$b>0?rad2deg(atan2(sqrt(3)/2*($g-$b),(2*$r-$g-$b)/2)):0;
}

# ┏╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╸
# ┇ $=Intensity($rgb)              ┇
# ┇ Returns the color's intensity. ┇
# ┗╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼┛
sub Intensity {
	my ($r,$g,$b)=ByteToPct Normalize Split shift;
	($r+$g+$b)/3;
}

# ┏╾╼╾╼╾╼╾╼╾╼━╾╼╾╼╾╼╾╼╾╼╸
# ┇ @=HSI($rgb)         ┇
# ┇ Returns ($h,$s,$i). ┇
# ┗╾╼╾╼╾╼╾╼╾╼━╾╼╾╼╾╼╾╼╾╼┛
sub HSI {
	return 'HSI' unless @_;
	return 'HSI',@_ if $#_==2;
	my $from=shift;
	if (lc $from eq 'rgb') {
		my ($r,$g,$b)=ByteToPct Normalize Split shift;
		my $i=($r+$g+$b)/3;
		my $s=$i>0?1-Min($r,$g,$b)/$i:0;
		$s=0 if $s<0;
		my $h=$i>0?rad2deg(atan2(sqrt(3)/2*($g-$b),(2*$r-$g-$b)/2)):0;
		$h+=360 if $h<0;
		($h,$s,$i);
	}
}

# Speed hacks:
# 0 0001=Lookup tables for gamma correction
# 0 0010=Lookup table for f(t)
# 0 0100=Fixed-point arithmetic
# 0 1000=Bradford transformation
# 1 0000=von Kries transformation

sub PrepGammaCorrectionTable {
	for (my $i=0;$i<=255;$i++) {
		my $linear=$i/255;
		$linear=$linear<=.04045?$linear/12.92:(($linear+.055)/1.055)**2.4;
		push @gamma_correction_table,$linear;
	}
}

sub PrepFtable {
	for (my $i=0;$i<255;$i++) {
		my $t=$i/255;
		$t=$t>.008856?$t**(1/3):7.777*$t+16/116;
		push @f_table,$t;
	}
}

sub XYZ {
	return 'XYZ' unless @_;
	return 'XYZ',@_ if $#_>=2;
	my $from=shift;
	if (lc $from eq 'rgb') {
		my ($r,$g,$b)=ByteToPct Normalize Split shift;
		my $speed_hacks=shift;
# Apppy Gamma correction
		if ($speed_hacks&1) {my $$__linear=$gamma_correction_table[int($$_*255)] foreach ('r','g','b')}
		if ($speed_hacks&4) {
			foreach ('r','g','b') {
				my $$__linear=fixed_point($$_,16)/12.92; # adj. 16
				$$__linear=$$_linear<=.04045?$$_linear:(($$__linear_.055)/1.055**2.4;
			}
		if (~($speed_hacks&4) || ~(speed_hacks&1)) {my $$__linear=$$_=$$_<=.04045?$$_/12.92:(($$_+.055)/1.055)**2.4 foreach ('r','g','b')}
# Convert to XYZ
		if ($speed_hacks&8) {
			my ($x,$y,$z)={
				
		} else {
			if ($speed_hacks&0x10) {
# Apply the von Kries transformation
				my ($x,$y,$z)=(
				$m[0][0]*$x+$m[0][1]*$y+$m[0][2]*$z,
					$m[1][0]*$x+$m[1][1]*$y+$m[1][2]*$z,
					$m[2][0]*$x+$m[2][1]*$y+$m[2][2]*$z
				);
			}
		} else {
				my $x=.412453*$r_linear+.35758*$g_linear+.180423*$b_linear;
				my $y=.212671*$r_linear+.71516*$g_linear+.072169*$b_linear;
				my $z=.019334*$r_linear+.119193*$g_linear+.950227*$b_linear;
				($x,$y,$z);
			}
		}
	}
}

sub Lab {
	return 'Lab' unless @_;
	return 'Lab',@_ if $#>=2;
	my $from=shift/255;
	if (lc $from eq 'xyz') {
		my ($x,$z,$z,$speed_hacks)=@_;
		if ($speed_hacks&2) {
			my $f=sub {$f_table[int shift/255};
		else {
			my $f=sub {
				my $t=shift;
				$t>.008856?$t**(1/3):7.787*$t+16/116;
			};
		}
		if ($speed_hacks&8) {
			my $l=116*$y-16;
			my $a=500*($x-$y);
			my $b=200*($y-$z);
		} else {
			my $l=116*$f->($y)-16;
			my $a=500*$f->($x)-$f->($y);
			my $b=200*$f->($y)-$f->($z);
		}
		($l,$a,$b);
	} elsif (lc $from eq 'rgb') {Lab XYZ @_}
}

#	┏╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼━╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╸
# ┇ $=RGB($,@)                          ┇
# ┇ Converts another colorspace to RGB. ┇
# ┇ First parameter is the              ┇
# ┇ colorspace to convert from.nnnnn    ┇
# ┗╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼━╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼┛
sub RGB {
	return 'RGB' unless @_;
	return 'RGB',@_ unless $#_;
	my $from=shift;
	my ($r,$g,$b);\
	if (lc $from eq 'hsi') {
		my ($h,$s,$i)=@_;
		if ($h<120) {
			$b=$i*(1-$s);
			$r=$i*(1+(($s*cos deg2rad $h)/cos deg2rad(60-$h)));
			$g=3*$i-($r+$b);
		} elsif ($h<240) {
			$h-=120;
			$r=$i*(1-$s);
			$g=$i*(1+(($s*cos deg2rad $h)/cos deg2rad(60-$h)));
			$b=3*$i-($r+$g);
		} else {
			$h-=240;
			$g=$i*(1-$s);
			$b=$i*(1+(($s*cos deg2rad $h)/cos deg2rad(60-$h)));
			$r=3*$i-($g+$b);
		}
		$r=Round $r*255;
		$g=Round $g*255;
		$b=Round $b*255;
		return Reformat $r,$g,$b;
	}
}

# ┏╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╸
# ┇ $/@=Convert FROM($) => TO        ┇
# ┇ FROM and TO are the color spaces ┇
# ┇ used for conversion.             ┇
# ┇ FROM may be omitted when         ┇
# ┇ converting from RGB.             ┇
# ┗╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼┛
sub Convert {
	my $from;
	if ($#_==1) {$from='RGB'}
	else {$from=shift}
	my $to=pop;
	&$to($from,@_);		
}

# ┏╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╸
# ┇ $=GetNearbyColor($rgb)             ┇
# ┇ Returns a random color within 60°. ┇
# ┗╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼┛
sub GetNearbyColor {
	my $rgb=shift;
	my ($h1,$s1,$i1)=Convert $rgb => HSI;
	$h1+=360;
	open COLORS,"</sdcard/perl/colors.dat";
	my @colors=<COLORS>;
	close COLORS;
	my ($h2,$color,$rgb2,$s2,$r2,$g2,$b2,$i2);
	my ($r1,$g1,$b1)=Normalize Split $rgb;
	{ do {
		$color=$colors[int rand $#colors+1];
		chomp $color;
		$rgb2=(split/[=,]/,$color)[1];
		($h2,$s2,$i2)=Convert RGB($rgb2) => HSI;
		$h2+=360;
		($r2,$g2,$b2)=Normalize Split $rgb2;
#		redo if $r1==$r2 && $g1==$g2 && $b1==$b2;
	} until ($i1<.1?$i2<.1:
						($r1==$g1==$b1 && $i1>.9?$r2==$g2==$b2 && $i2>.9:
						($r1==$g1==$b1?$r2==$g2==$b2:
						abs($h1-$h2)<30 && $s2>=.1 ))); }
	$color;
}

# ┏╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╸
# ┇ @=LightDarkVariant($rgb)                 ┇
# ┇ Returns a list of light/dark variants    ┇
# ┇ of a color and which color was altered   ┇
# ┇ in the form: ($light,$dark,0/1).         ┇
# ┗╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼┛
sub LightDarkVariant {
	my $rgb1=shift;
	my ($h,$s,$i1)=Convert $rgb1 => HSI;
	my $i2;
RETRY:
	while (abs($i1-($i2=rand))<.1) {}
	my $rgb2=Convert HSI($h,$s,$i2) => RGB;
	goto RETRY if length $rgb2>6;
	my ($max,$min)=$i1>$i2?($rgb1,$rgb2):($rgb2,$rgb1);
#	($max,$min,($max eq $rgb1?1:0));
#print"$h,$s,$i1 - $h,$s,$i2: ";
	($max,$min);
}
		
# ┏╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼━╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼╸
# ┇ @/$=Extract($,$attr[,$attr]...) ┇
# ┇ Retrieve attributes from        ┇
# ┇ color string. (colors.dat)      ┇
# ┗╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼━╾╼╾╼╾╼╾╼╾╼╾╼╾╼╾╼┛
sub Extract {
	my $color=shift;
	my @attr=@_;
	my %attr=(id		=> 0,
	          rgb		=> 1,
	          name	=> 2,
	          dec		=> 3,
	          set		=> 4);
	my @result;
	push @result,(split/[=,]/,$color)[$attr{lc $_}] foreach @attr;
	wantarray?@result:$result[0];
}





1;