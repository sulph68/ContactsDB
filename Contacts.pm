package Palm::Contacts;
#
# ABSTRACT: Handler for Palm OS 5 Contacts  databases
#
#	Copyright (C) 2021, Benjamin Khoo.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.

# Inspired by module by Andrew Arensburger

use strict;
use Palm::Raw();
use Palm::StdAppInfo();

use vars qw( $VERSION @ISA
	$numFieldLabels $addrLabelLength @phoneLabels @countries @imLabels @addressLabels @displayLabels
	%fieldMapBits %fieldMapBits2);

# One liner, to allow MakeMaker to work.
$VERSION = '1.400';
# This file is part of Palm 1.400 (March 14, 2015)

@ISA = qw( Palm::StdAppInfo Palm::Raw );

# Contacts records were reversed engineered. There are fields which i have no
# idea what they do. 

#'

$addrLabelLength = 16;
# there the field labels are 40, there are actually 42 records
# the last 2 records are reminder and Photos.
# this module does not handle photos at this point
$numFieldLabels = 40; 

@phoneLabels = (
	"Work",
	"Home",
	"Mobile",
	"E-mail",
	"Main",
	"Pager",
	"Other",
	"Mobile"
	);

sub label2phone() {
	my ($l) = @_;
	return 0 if ($l eq $phoneLabels[0]);
	return 1 if ($l eq $phoneLabels[1]);
	return 2 if ($l eq $phoneLabels[2]);
	return 3 if ($l eq $phoneLabels[3]);
	return 4 if ($l eq $phoneLabels[4]);
	return 5 if ($l eq $phoneLabels[5]);
	return 6 if ($l eq $phoneLabels[6]);
	return 7 if ($l eq $phoneLabels[7]);
}

@imLabels = (
	"IM",
	"AIM",
	"MSN",
	"Yahoo",
	"AOL ICQ"
);

sub label2im() {
	my ($l) = @_;
	return 0 if ($l eq $imLabels[0]);
	return 1 if ($l eq $imLabels[1]);
	return 2 if ($l eq $imLabels[2]);
	return 3 if ($l eq $imLabels[3]);
	return 4 if ($l eq $imLabels[4]);
}

@addressLabels = (
	"Addr(W)",
	"Addr(H)",
	"Addr(O)"
);

sub label2address() {
	my ($l) = @_;
	return 0 if ($l eq $addressLabels[0]);
	return 1 if ($l eq $addressLabels[1]);
	return 2 if ($l eq $addressLabels[2]);
}

@displayLabels =(
	"Work",
	"Home",
	"Mobile",
	"E-mail",
	"Main",
	"Pager",
	"Other"
);

sub label2display() {
	my ($l) = @_;
	return 0 if ($l eq $displayLabels[0]);
	return 1 if ($l eq $displayLabels[1]);
	return 2 if ($l eq $displayLabels[2]);
	return 3 if ($l eq $displayLabels[3]);
	return 4 if ($l eq $displayLabels[4]);
	return 5 if ($l eq $displayLabels[5]);
	return 6 if ($l eq $displayLabels[6]);
}


@countries = (
	"Australia",
	"Austria",
	"Belgium",
	"Brazil",
	"Canada",
	"Denmark",
	"Finland",
	"France",
	"Germany",
	"Hong Kong",
	"Iceland",
	"Ireland",
	"Italy",
	"Japan",
	"Korea",
	"Luxembourg",
	"Malaysia",
	"Mexico",
	"Netherlands",
	"New Zealand",
	"Norway",
	"P.R.C",
	"Philippines",
	"Singapore",
	"Spain",
	"Sweden",
	"Switzerland",
	"Taiwan",
	"Thailand",
	"United Kingdom",
	"United States",
);

# fieldMapBits
# Each Address record contains a flag record ($fieldMap, in
# &PackRecord) that indicates which fields exist in the record. This
# hash defines these flags' values.
%fieldMapBits = (
	lastName	=> 0x00000001,
	firstName	=> 0x00000002,
	company		=> 0x00000004,
	title			=> 0x00000008,
	phone1		=> 0x00000010,
	phone2		=> 0x00000020,
	phone3		=> 0x00000040,
	phone4		=> 0x00000080,
	phone5		=> 0x00000100,
	phone6		=> 0x00000200,
	phone7		=> 0x00000400,
	im1				=> 0x00000800,
	im2				=> 0x00001000,
	website		=> 0x00002000,
	custom1		=> 0x00004000,
	custom2		=> 0x00008000,
	custom3		=> 0x00010000,
	custom4		=> 0x00020000,
	custom5		=> 0x00040000,
	custom6		=> 0x00080000,
	custom7		=> 0x00100000,
	custom8		=> 0x00200000,
	custom9		=> 0x00400000,
	address1	=> 0x00800000,
	city1			=> 0x01000000,
	state1		=> 0x02000000,
	zip1			=> 0x04000000,
	country1	=> 0x08000000,
);

# Contacts has more fields than the original AddressBookDB.
# I unpack them in 2 segments for simplicity

%fieldMapBits2 =(
	address2 	=> 0x00000001,
	city2		 	=> 0x00000002,
	state2	 	=> 0x00000004,
	zip2		 	=> 0x00000008,
	country2	=> 0x00000010,
	address3	=> 0x00000020,
	city3			=> 0x00000040,
	state3		=> 0x00000080,
	zip3			=> 0x00000100,
	country3	=> 0x00000200,
	note			=> 0x00000400,
	reminder	=> 0x00000800,
	birthday	=> 0x00001000,
);

sub import
{
	&Palm::PDB::RegisterPDBHandlers(__PACKAGE__,
		[ "PAdd", "DATA" ],
		);
}

#'

# new
# Create a new Palm::Contacts database, and return it
# not that new databases does not contain some potential features that can be
# defined in the actual PDB. 
sub new
{
	my $classname	= shift;
	my $self	= $classname->SUPER::new(@_);
			# Create a generic PDB. No need to rebless it,
			# though.

	$self->{name} = "ContactsDB-PAdd";	# Default
	$self->{creator} = "PAdd";
	$self->{type} = "DATA";
	$self->{attributes}{resource} = 0;

	# Initialize the AppInfo block
	$self->{appinfo} = {
		fieldLabels	=> {
			# Displayed labels for the various fields in
			# each address record.
			lastName	=> "Last Name",
			firstName	=> "First name",
			company		=> "Company",
			title			=> "Title",
			phone1		=> $phoneLabels[0],
			phone2		=> $phoneLabels[1],
			phone3		=> $phoneLabels[2],
			phone4		=> $phoneLabels[3],
			phone5		=> $phoneLabels[4],
			phone6		=> $phoneLabels[5],
			phone7		=> $phoneLabels[6],
			im1				=> $imLabels[0], # Chat1
			im2				=> $imLabels[1], # Chat2
			website		=> "Website",
			custom1		=> "Custom 1",
			custom2		=> "Custom 2",
			custom3		=> "Custom 3",
			custom4		=> "Custom 4",
			custom5		=> "Custom 5",
			custom6		=> "Custom 6",
			custom7		=> "Custom 7",
			custom8		=> "Custom 8",
			custom9		=> "Custom 9",
			address1	=> $addressLabels[0], # Addr(W)
			city1			=> "City",
			state1		=> "State",
			zip1			=> "ZipCode",
			country1	=> "Country",
			address2	=> $addressLabels[1], # Addr(H)
			city2			=> "City",
			state2		=> "State",
			zip2			=> "ZipCode",
			country2	=> "Country",
			address3	=> $addressLabels[2], # Addr(O)
			city3			=> "City",
			state3		=> "State",
			zip3			=> "ZipCode",
			country3	=> "Country",
			note			=> "Note",
			birthday	=> "Birthday",
		},
		misc		=> "01001001010011010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000010100100101001101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100110101010011010011100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001011001011000010110100001101111011011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000010100111101001100001000000100100101000011010100010000000000000000000000000000000000000000000000000000000000000000000000000101000001101001011000110111010001110101011100100110010100000000000000000000000000000000000000000000000000000000000000000000000001010000011010000110111101101110011001010010111101000101011011010110000101101001011011000000000000000000000000000000000000000000010010010100110100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000101100100011001000111001001100101011100110111001100000000000000000000000000000000000000000000000000000000000000000000000001000011011000010110110101100101011100100110000100000000000000000000000000000000000000000000000000000000000000000000000000000000010100000110100001101111011101000110111101110011000000000000000000000000000000000000000000000000000000000000000000000000000000000101001001100101011011010110111101110110011001010000000000000000000000000000000000000000000000000000000000000000000000000000000000011110000000000000000000000000",
		dirtyFields => "00000000000000000000111111111111111111111111111100000001111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111111111111111100000001111111111111111111111111",
	};

	# Add the standard AppInfo block stuff
	&Palm::StdAppInfo::seed_StdAppInfo($self->{appinfo});

	# Give the PDB a blank sort block
	$self->{sort} = undef;

	# Give the PDB an empty list of records
	$self->{records} = [];

	return $self;
}


# new_Record
# Create a new, initialized record.
sub new_Record
{
	my $classname = shift;
	my $retval = $classname->SUPER::new_Record(@_);

	# Initialize the fields. This isn't particularly enlightening,
	# but every Contact record has these.
	$retval->{fields} = {
		lastName	=> undef,
		firstName	=> undef,
		company		=> undef,
		title			=> undef,
		phone1		=> undef,
		phone2		=> undef,
		phone3		=> undef,
		phone4		=> undef,
		phone5		=> undef,
		phone6		=> undef,
		phone7		=> undef,
		im1				=> undef,
		im2				=> undef,
		website		=> undef,
		custom1		=> undef,
		custom2		=> undef,
		custom3		=> undef,
		custom4		=> undef,
		custom5		=> undef,
		custom6		=> undef,
		custom7		=> undef,
		custom8		=> undef,
		custom9		=> undef,
		address1	=> undef,
		city1			=> undef,
		state1		=> undef,
		zip1			=> undef,
		country1	=> undef,
		address2 	=> undef,
		city2		 	=> undef,
		state2	 	=> undef,
		zip2		 	=> undef,
		country2	=> undef,
		address3	=> undef,
		city3			=> undef,
		state3		=> undef,
		zip3			=> undef,
		country3	=> undef,
		note			=> undef,
		birthday	=> undef,
	};

	# Initialize the phone labels
	$retval->{phoneLabel} = {
		phone1	=> $phoneLabels[0],
		phone2	=> $phoneLabels[1],
		phone3	=> $phoneLabels[2],
		phone4	=> $phoneLabels[3],
		phone5	=> $phoneLabels[4],
		phone6	=> $phoneLabels[5],
		phone7	=> $phoneLabels[6],
		display	=> 2,		# Display Mobile by default 2
	};

	
	# Initialize the im labels
	$retval->{imLabel} = {
		im1	=> $imLabels[0],
		im2	=> $imLabels[1],
	};

	# Initialize the address labels
	$retval->{addressLabel} = {
		address1	=> $addressLabels[0],		# Work
		address2	=> $addressLabels[1],		# Home
		address3	=> $addressLabels[2],		# Other
	};

	return $retval;
}

# ParseAppInfoBlock
sub ParseAppInfoBlock
{
	my $self = shift;
	my $data = shift;
	my $dirtyFields;
	my @fieldLabels;
	my $phoneLabel7;
	my $misc;

	my $i;
	my $appinfo = {};
	my $std_len;

	# Get the standard parts of the AppInfo block
	$std_len = &Palm::StdAppInfo::parse_StdAppInfo($appinfo, $data);

	$data = $appinfo->{other};		# Look at the non-standard part

	# Get the rest of the AppInfo block
	my $unpackstr =		# Argument to unpack()
		"B224" .				# Some Flags. No idea what these are
		"a$addrLabelLength" x $numFieldLabels .  # Address labels
		"a16" .					# Phone custom label on position 7
		# "a16" x 5 .			# IM labels. 5 positions
		"B*";						# Misc Labels?
		# "B*";						# Misc Labels?

	# ($dirtyFields, @fieldLabels[0..($numFieldLabels-1)], $phoneLabels[7], @imLabels[0..4], $misc) = unpack($unpackstr, $data);
	($dirtyFields, @fieldLabels[0..($numFieldLabels-1)], $phoneLabels[7], $misc) = unpack($unpackstr, $data);
	
	# print $misc."=misc\n";

	for (@fieldLabels) {
		s/\0.*$//;	# Trim everything after the first NUL
				# (when renaming custom fields, might
				# have something like "Foo\0om 1"
	}

	$appinfo->{dirtyFields} = $dirtyFields;
	$appinfo->{fieldLabels} = {
		lastName	=> $fieldLabels[0],
		firstName	=> $fieldLabels[1],
		company		=> $fieldLabels[2],
		title			=> $fieldLabels[3],
		phone1		=> $fieldLabels[4],
		phone2		=> $fieldLabels[5],
		phone3		=> $fieldLabels[6],
		phone4		=> $fieldLabels[7],
		phone5		=> $fieldLabels[8],
		phone6		=> $fieldLabels[9],
		phone7		=> $fieldLabels[10],
		im1				=> $fieldLabels[11],
		im2				=> $fieldLabels[12],
		website		=> $fieldLabels[13],
		custom1		=> $fieldLabels[14],
		custom2		=> $fieldLabels[15],
		custom3		=> $fieldLabels[16],
		custom4		=> $fieldLabels[17],
		custom5		=> $fieldLabels[18],
		custom6		=> $fieldLabels[19],
		custom7		=> $fieldLabels[20],
		custom8		=> $fieldLabels[21],
		custom9		=> $fieldLabels[22],
		address1	=> $fieldLabels[23],
		city1			=> $fieldLabels[24],
		state1		=> $fieldLabels[25],
		zip1			=> $fieldLabels[26],
		country1	=> $fieldLabels[27],
		address2 	=> $fieldLabels[28],
		city2		 	=> $fieldLabels[29],
		state2	 	=> $fieldLabels[30],
		zip2		 	=> $fieldLabels[31],
		country2	=> $fieldLabels[32],
		address3	=> $fieldLabels[33],
		city3			=> $fieldLabels[34],
		state3		=> $fieldLabels[35],
		zip3			=> $fieldLabels[36],
		country3	=> $fieldLabels[37],
		note			=> $fieldLabels[38],
		birthday	=> $fieldLabels[39],
	};
	$appinfo->{misc} = $misc;	# Seems to be misc labels used in the app

	return $appinfo;
}

sub PackAppInfoBlock
{
	my $self = shift;
	my $retval;
	my $i;
	my $other;		# Non-standard AppInfo stuff

	# Pack the application-specific part of the AppInfo block
	$other = pack("B224", $self->{appinfo}{dirtyFields});
	$other .= pack("a$addrLabelLength" x $numFieldLabels,
		$self->{appinfo}{fieldLabels}{lastName},
		$self->{appinfo}{fieldLabels}{firstName},
		$self->{appinfo}{fieldLabels}{company},
		$self->{appinfo}{fieldLabels}{title},
		$self->{appinfo}{fieldLabels}{phone1},
		$self->{appinfo}{fieldLabels}{phone2},
		$self->{appinfo}{fieldLabels}{phone3},
		$self->{appinfo}{fieldLabels}{phone4},
		$self->{appinfo}{fieldLabels}{phone5},
		$self->{appinfo}{fieldLabels}{phone6},
		$self->{appinfo}{fieldLabels}{phone7},
		$self->{appinfo}{fieldLabels}{im1},
		$self->{appinfo}{fieldLabels}{im2},
		$self->{appinfo}{fieldLabels}{website},
		$self->{appinfo}{fieldLabels}{custom1},
		$self->{appinfo}{fieldLabels}{custom2},
		$self->{appinfo}{fieldLabels}{custom3},
		$self->{appinfo}{fieldLabels}{custom4},
		$self->{appinfo}{fieldLabels}{custom5},
		$self->{appinfo}{fieldLabels}{custom6},
		$self->{appinfo}{fieldLabels}{custom7},
		$self->{appinfo}{fieldLabels}{custom8},
		$self->{appinfo}{fieldLabels}{custom9},
		$self->{appinfo}{fieldLabels}{address1},
		$self->{appinfo}{fieldLabels}{city1},
		$self->{appinfo}{fieldLabels}{state1},
		$self->{appinfo}{fieldLabels}{zip1},
		$self->{appinfo}{fieldLabels}{country1},
		$self->{appinfo}{fieldLabels}{address2},
		$self->{appinfo}{fieldLabels}{city2},
		$self->{appinfo}{fieldLabels}{state2},
		$self->{appinfo}{fieldLabels}{zip2},
		$self->{appinfo}{fieldLabels}{country2},
		$self->{appinfo}{fieldLabels}{address3},
		$self->{appinfo}{fieldLabels}{city3},
		$self->{appinfo}{fieldLabels}{state3},
		$self->{appinfo}{fieldLabels}{zip3},
		$self->{appinfo}{fieldLabels}{country3},
		$self->{appinfo}{fieldLabels}{note},
		$self->{appinfo}{fieldLabels}{birthday});
	#$other .= pack("a".length($self->{appinfo}{misc}), $self->{appinfo}{misc});
	$other .= pack("a16", $phoneLabels[7]);
	# $other .= pack("a16" x 5, $imLabels[0..4]);
	$other .= pack("B".length($self->{appinfo}{misc}), $self->{appinfo}{misc});
	$self->{appinfo}{other} = $other;

	# Pack the standard part of the AppInfo block
	$retval = &Palm::StdAppInfo::pack_StdAppInfo($self->{appinfo});

	return $retval;
}

# ParseRecord
# Parse a Contact record.

# Address book records have the following overall structure:
#	1: phone labels im labels address labels
#	2: field map
#	3: fields

# The comments below are unchanged from AddressDB perl module
# the principal structure remains the same. But there are more 
# field map bits as there are more records

# Each record can contain a number of fields, such as "name",
# "address", "city", "company", and so forth. Each field has an
# internal name ("zipCode"), a printable name ("Zip Code"), and a
# value ("90210").
#
# For most fields, there is a hard mapping between internal and
# printed names: "name" always corresponds to "Last Name". The fields
# "phone1" through "phone5" are different: each of these can be mapped
# to one of several printed names: "Work", "Home", "Fax", "Other",
# "E-Mail", "Main", "Pager" or "Mobile". Multiple internal names can
# map to the same printed name (a person might have several e-mail
# addresses), and the mapping is part of the record (i.e., each record
# has its own mapping).
#
# Part (3) is simply a series of NUL-terminated strings, giving the
# values of the various fields in the record, in a certain order. If a
# record does not have a given field, there is no string corresponding
# to it in this part.
#
# Part (2) is a bit field that specifies which fields the record
# contains.
#
# Part (1) determines the phone mapping described above. This is
# implemented as an unsigned long, but what we're interested in are
# the six least-significant nybbles. They are:
#	disp	phone5	phone4	phone3	phone2	phone1
# ("phone1" is the least-significant nybble). Each nybble holds a
# value in the range 0-15 which in turn specifies the printed name for
# that particular internal name.

sub ParseRecord
{
	my $self = shift;
	my %record = @_;

	delete $record{offset};	# This is useless

	my $phoneFlags;
	my $imFlags;
	my @phoneTypes;
	my @imTypes;
	my @addressTypes;
	my $dispPhone;		# Which phone to display in the phone list

	my $fieldMap;
	my $fieldMap2;

	my $fields;
	my @fields;

	my $null; # unknown

	($phoneFlags, $imFlags, $fieldMap, $fieldMap2, $null, $fields) =
		unpack("N N N N B8 a*", $record{data});
	@fields = split /\0/, $fields;

	# Parse the phone flags
  $phoneTypes[0] =  $phoneFlags        & 0x0f; # Phone Label 1
  $phoneTypes[1] = ($phoneFlags >>  4) & 0x0f; # Phone Label 2
  $phoneTypes[2] = ($phoneFlags >>  8) & 0x0f; # Phone Label 3
  $phoneTypes[3] = ($phoneFlags >> 12) & 0x0f; # Phone Label 4
  $phoneTypes[4] = ($phoneFlags >> 16) & 0x0f; # Phone Label 5
  $phoneTypes[5] = ($phoneFlags >> 20) & 0x0f; # Phone Addition Label 1
  $phoneTypes[6] = ($phoneFlags >> 24) & 0x0f; # Phone Addition Label 2
  $dispPhone	   = ($phoneFlags >> 28) & 0x0f; # Phone Display - displays which phone item

	$record{phoneLabel}{phone1} = $phoneLabels[$phoneTypes[0]];
	$record{phoneLabel}{phone2} = $phoneLabels[$phoneTypes[1]];
	$record{phoneLabel}{phone3} = $phoneLabels[$phoneTypes[2]];
	$record{phoneLabel}{phone4} = $phoneLabels[$phoneTypes[3]];
	$record{phoneLabel}{phone5} = $phoneLabels[$phoneTypes[4]];
	$record{phoneLabel}{phone6} = $phoneLabels[$phoneTypes[5]];
	$record{phoneLabel}{phone7} = $phoneLabels[$phoneTypes[6]];
	$record{phoneLabel}{display} = $dispPhone;

	# Parse IM Flag
	$imTypes[0] =  $imFlags        & 0x0f; # IM Label 1
  $imTypes[1] = ($imFlags >>  4) & 0x0f; # IM Addition Label 2
	$record{reminder}	= ($imFlags >>  12) & 0x0f; # birthday reminder on 1st bit
  $addressTypes[0] = ($imFlags >>  16) & 0x0f; # Address type label
  $addressTypes[1] = ($imFlags >>  20) & 0x0f; # 
  $addressTypes[2] = ($imFlags >>  24) & 0x0f; # 

	$record{imLabel}{im1} = $imLabels[$imTypes[0]];
	$record{imLabel}{im2} = $imLabels[$imTypes[1]];
	$record{addressLabel}{address1} = $addressLabels[$addressTypes[0]];
	$record{addressLabel}{address2} = $addressLabels[$addressTypes[1]];
	$record{addressLabel}{address3} = $addressLabels[$addressTypes[2]];

	# Get the relevant fields
  $fieldMap & 0x00000001 and $record{fields}{lastName}  = shift @fields;
  $fieldMap & 0x00000002 and $record{fields}{firstName} = shift @fields;
  $fieldMap & 0x00000004 and $record{fields}{company}   = shift @fields;
  $fieldMap & 0x00000008 and $record{fields}{title}     = shift @fields;

  $fieldMap & 0x00000010 and $record{fields}{phone1} = shift @fields;
  $fieldMap & 0x00000020 and $record{fields}{phone2} = shift @fields;
  $fieldMap & 0x00000040 and $record{fields}{phone3} = shift @fields;
  $fieldMap & 0x00000080 and $record{fields}{phone4} = shift @fields;
  $fieldMap & 0x00000100 and $record{fields}{phone5} = shift @fields;
  $fieldMap & 0x00000200 and $record{fields}{phone6} = shift @fields;
  $fieldMap & 0x00000400 and $record{fields}{phone7} = shift @fields;

  $fieldMap & 0x00000800 and $record{fields}{im1} = shift @fields;
  $fieldMap & 0x00001000 and $record{fields}{im2} = shift @fields;

  $fieldMap & 0x00002000 and $record{fields}{website} = shift @fields;

  $fieldMap & 0x00004000 and $record{fields}{custom1} = shift @fields;
  $fieldMap & 0x00008000 and $record{fields}{custom2} = shift @fields;
  $fieldMap & 0x00010000 and $record{fields}{custom3} = shift @fields;
  $fieldMap & 0x00020000 and $record{fields}{custom4} = shift @fields;
  $fieldMap & 0x00040000 and $record{fields}{custom5} = shift @fields;
  $fieldMap & 0x00080000 and $record{fields}{custom6} = shift @fields;
  $fieldMap & 0x00100000 and $record{fields}{custom7} = shift @fields;
  $fieldMap & 0x00200000 and $record{fields}{custom8} = shift @fields;
  $fieldMap & 0x00400000 and $record{fields}{custom9} = shift @fields;

  $fieldMap & 0x00800000 and $record{fields}{address1} = shift @fields;
  $fieldMap & 0x01000000 and $record{fields}{city1}    = shift @fields;
  $fieldMap & 0x02000000 and $record{fields}{state1}   = shift @fields;
  $fieldMap & 0x04000000 and $record{fields}{zip1}     = shift @fields;
  $fieldMap & 0x08000000 and $record{fields}{country1} = shift @fields;
  $fieldMap2  & 0x00000001 and $record{fields}{address2} = shift @fields;
  $fieldMap2  & 0x00000002 and $record{fields}{city2}    = shift @fields;
  $fieldMap2  & 0x00000004 and $record{fields}{state2}   = shift @fields;
  $fieldMap2  & 0x00000008 and $record{fields}{zip2}     = shift @fields;
  $fieldMap2  & 0x00000010 and $record{fields}{country2} = shift @fields;
  $fieldMap2  & 0x00000020 and $record{fields}{address3} = shift @fields;
  $fieldMap2  & 0x00000040 and $record{fields}{city3}    = shift @fields;
  $fieldMap2  & 0x00000080 and $record{fields}{state3}   = shift @fields;
  $fieldMap2  & 0x00000100 and $record{fields}{zip3}     = shift @fields;
  $fieldMap2  & 0x00000200 and $record{fields}{country3} = shift @fields;

  $fieldMap2  & 0x00000400 and $record{fields}{note}  = shift @fields;
  $fieldMap2  & 0x00000800 and $record{fields}{birthday}  = shift @fields;
  $fieldMap2  & 0x00001000 and $record{fields}{reminder} = shift @fields;

	if ($record{fields}{birthday}) {
    my ($date) = unpack("n", $record{fields}{birthday});
    if ($date != 0xffff) {
      my %bd;
      $bd{day}   =  $date       & 0x001f; # 5 bits
      $bd{month} = ($date >> 5) & 0x000f; # 4 bits
      $bd{year}  = ($date >> 9) & 0x007f; # 7 bits (years since 1904)
      $bd{year} += 1904;
      $record{fields}{birthday} = \%bd;
    }
  }
  if ($record{fields}{reminder} && $record{fields}{birthday}) {
    my ($days) = unpack("n", $record{fields}{reminder});
    my %r;
    $r{days}   =  $days        & 0x00ff;  # 8 bits
    $r{reminder} =  ($days >> 8) & 0x00ff;  # 8 bits
    $record{fields}{reminder} =\%r;   
  }

	# The last field that exists and is unmapped is the photo data.
	# this is unsupported for now, but can be read in the future or if required
	# if (@fields == 1) {
  #   $record{fields}{photo} = shift @fields;
  # }

	delete $record{data};
	delete $record{reminder};

	return \%record;
}

sub PackRecord
{
	my $self = shift;
	my $record = shift;
	my $retval = 0;

	$retval = pack("N",
		(&label2phone($record->{phoneLabel}{phone1})    & 0x0f) |
		((&label2phone($record->{phoneLabel}{phone2})   & 0x0f) <<  4) |
		((&label2phone($record->{phoneLabel}{phone3})   & 0x0f) <<  8) |
		((&label2phone($record->{phoneLabel}{phone4})   & 0x0f) << 12) |
		((&label2phone($record->{phoneLabel}{phone5})   & 0x0f) << 16) |
		((&label2phone($record->{phoneLabel}{phone6})   & 0x0f) << 20) |
		((&label2phone($record->{phoneLabel}{phone7})   & 0x0f) << 24) |
		(($record->{phoneLabel}{display}  							& 0xff) << 28)); # display is the index of phoneX to display

	$retval .= pack("N",
		(&label2im($record->{imLabel}{im1})			& 0x0f) |
		((&label2im($record->{imLabel}{im2}) 		& 0x0f) << 4) |
		(($record->{fields}{reminder}{reminder} & 0x0f) << 12) |
		((&label2address($record->{addressLabel}{address1})	& 0x0f) << 16) |
		((&label2address($record->{addressLabel}{address2})	& 0x0f) << 20) |
		((&label2address($record->{addressLabel}{address3})	& 0x0f) << 24));

	# re-add reminder flag
	if ($record->{fields}{reminder}{reminder} == 1) {
		$record->{reminder} = 1;
	} else {
		$record->{reminder} = 0;
	}
	# Set the flag bits that indicate which fields exist in this
	# record.
	my $fieldMap = 0;

	foreach my $fieldname (qw(lastName firstName company title
			phone1 phone2 phone3 phone4 phone5 phone6 phone7
			im1 im2 website
			custom1 custom2 custom3 custom4 custom5 custom6 custom7 custom8 custom9
			address1 city1 state1 zip1 country1))
	{
		if (defined($record->{fields}{$fieldname}) && ($record->{fields}{$fieldname} ne "")) {
			$fieldMap |= $fieldMapBits{$fieldname};
		} else {
			$record->{fields}{$fieldname} = "";
		}
	}
	$retval .= pack("N", $fieldMap);

	my $rawDate = 0;
	# repack birthday 
	if (defined($record->{fields}{birthday}{day})) {
		$rawDate = ($record->{fields}{birthday}{day} & 0x001f) |
			(($record->{fields}{birthday}{month} & 0x000f) << 5) |
			((($record->{fields}{birthday}{year} - 1904) & 0x007f) << 9);
		$record->{fields}{birthday} = pack("n", $rawDate);
	} else {
		delete($record->{fields}{birthday});
	}
	# repack reminder info
	my $rawRemind = 0;
	if ($record->{reminder} == 1) {
		$rawRemind = ($record->{fields}{reminder}{days}	& 0x00ff) |
								(($record->{fields}{reminder}{reminder} & 0x00ff) << 8);
		$record->{fields}{reminder} = pack("n", $rawRemind);
	} else {
		delete($record->{fields}{reminder});
	}	

	my $fieldMap2 = 0;
	foreach my $fieldname (qw(address2 city2 state2 zip2 country2
			address3 city3 state3 zip3 country3
			note birthday reminder))
	{
		if (defined($record->{fields}{$fieldname}) && ($record->{fields}{$fieldname} ne "")) {
			$fieldMap2 |= $fieldMapBits2{$fieldname};
		} else {
			$record->{fields}{$fieldname} = "";
		}
	}
	$retval .= pack("N", $fieldMap2);

	# Repack an unknown Null value. I have no idea what this does
	$retval .= pack("B8", 0xff);

	my $fields = "";

	# Append each nonempty field in turn to $fields.
	foreach my $fieldname (qw(lastName firstName company title
			phone1 phone2 phone3 phone4 phone5 phone6 phone7
			im1 im2 website
			custom1 custom2 custom3 custom4 custom5 custom6 custom7 custom8 custom9
			address1 city1 state1 zip1 country1
			address2 city2 state2 zip2 country2
			address3 city3 state3 zip3 country3
			note birthday reminder))
	{
		# Skip empty fields (either blank or undefined).
		next if !defined($record->{fields}{$fieldname});
		next if $record->{fields}{$fieldname} eq "";

		# Append the field (with a terminating NUL)
		$fields .= $record->{fields}{$fieldname} . "\0";
	}

	$retval .= $fields;

	return $retval;
}

1;

__END__

=head1 NAME

Palm::Contacts - Handler for Palm OS 5 Contacts databases

=head1 VERSION

This document describes version 1.400 of
Palm::Contacts, released March 14, 2015
as part of Palm version 1.400.

=head1 SYNOPSIS

    use Palm::Contacts;

=head1 DESCRIPTION

The Address PDB handler is a helper class for the Palm::PDB package.
It parses AddressBook databases.

=head2 AppInfo block

The AppInfo block begins with standard category support. See
L<Palm::StdAppInfo> for details.

Other fields include:

    $pdb->{appinfo}{lastUniqueID}
    $pdb->{appinfo}{dirtyFields}

I don't know what these are.

		$self->{appinfo}{fieldLabels}{lastName}
		$self->{appinfo}{fieldLabels}{firstName}
		$self->{appinfo}{fieldLabels}{company}
		$self->{appinfo}{fieldLabels}{title}
		$self->{appinfo}{fieldLabels}{phone1}
		$self->{appinfo}{fieldLabels}{phone2}
		$self->{appinfo}{fieldLabels}{phone3}
		$self->{appinfo}{fieldLabels}{phone4}
		$self->{appinfo}{fieldLabels}{phone5}
		$self->{appinfo}{fieldLabels}{phone6}
		$self->{appinfo}{fieldLabels}{phone7}
		$self->{appinfo}{fieldLabels}{im1}
		$self->{appinfo}{fieldLabels}{im2}
		$self->{appinfo}{fieldLabels}{website}
		$self->{appinfo}{fieldLabels}{custom1}
		$self->{appinfo}{fieldLabels}{custom2}
		$self->{appinfo}{fieldLabels}{custom3}
		$self->{appinfo}{fieldLabels}{custom4}
		$self->{appinfo}{fieldLabels}{custom5}
		$self->{appinfo}{fieldLabels}{custom6}
		$self->{appinfo}{fieldLabels}{custom7}
		$self->{appinfo}{fieldLabels}{custom8}
		$self->{appinfo}{fieldLabels}{custom9}
		$self->{appinfo}{fieldLabels}{address1}
		$self->{appinfo}{fieldLabels}{city1}
		$self->{appinfo}{fieldLabels}{state1}
		$self->{appinfo}{fieldLabels}{zip1}
		$self->{appinfo}{fieldLabels}{country1}
		$self->{appinfo}{fieldLabels}{address2}
		$self->{appinfo}{fieldLabels}{city2}
		$self->{appinfo}{fieldLabels}{state2}
		$self->{appinfo}{fieldLabels}{zip2}
		$self->{appinfo}{fieldLabels}{country2}
		$self->{appinfo}{fieldLabels}{address3}
		$self->{appinfo}{fieldLabels}{city3}
		$self->{appinfo}{fieldLabels}{state3}
		$self->{appinfo}{fieldLabels}{zip3}
		$self->{appinfo}{fieldLabels}{country3}
		$self->{appinfo}{fieldLabels}{note}
		$self->{appinfo}{fieldLabels}{birthday}

These are the names of the various fields in the record.

    $pdb->{appinfo}{misc}

This is contains the remaining text labels after the standard contact labels.
These seems to be resource used for some default records

=head2 Sort block

    $pdb->{sort}

This is a scalar, the raw data of the sort block.

=head2 Records

    $record = $pdb->{records}[N];

All records are available in an array use Dumper() to investigate the record structure
		
		print Dumper(\$record);

Labels for phone, IM as well as address are automatically converted in the PDB.
The presented labels in $record is therefore the text label and not the actual integer that
is records in the PDB.

=head1 METHODS

=head2 new

  $pdb = new Palm::Contacts;

Create a new PDB, initialized with the various Palm::Address fields
and an empty record list.

Use this method if you're creating an Address PDB from scratch.

=head2 new_Record

  $record = $pdb->new_Record;

Creates a new Address record, with blank values for all of the fields.
The AppInfo block will contain only an "Unfiled" category, with ID 0.

C<new_Record> does B<not> add the new record to C<$pdb>. For that,
you want C<$pdb-E<gt>append_Record>.

=head1 SEE ALSO

L<Palm::PDB>

L<Palm::StdAppInfo>

=head1 CONFIGURATION AND ENVIRONMENT

Palm::Contacts requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Module doesn't support setting everything in the Contacts DB. It also doesn't handle Photos

=head1 AUTHORS

Andrew Arensburger C<< <arensb AT ooblick.com> >>

Currently maintained by Christopher J. Madsen C<< <perl AT cjmweb.net> >>

Contacts DB support contributed by Benjamin K.

You can follow or contribute to p5-Palm's development at
L<< https://github.com/madsen/p5-Palm >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Andrew Arensburger & Alessandro Zummo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
