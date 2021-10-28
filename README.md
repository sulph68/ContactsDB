# ContactsDB
Support for PalmOS5 ContactsDB-PAdd.pdb

# Usage
Copy the pm file into the Palm module.
This should be in `/usr/local/share/perl/5.30.0/Palm` or something similar

# POD documentation from the module

## NAME

Palm::Contacts - Handler for Palm OS 5 Contacts databases

## VERSION

This document describes version 1.400 of
Palm::Contacts, released March 14, 2015
as part of Palm version 1.400.

## SYNOPSIS

    use Palm::Contacts;

## DESCRIPTION

The Address PDB handler is a helper class for the Palm::PDB package.
It parses AddressBook databases.

## AppInfo block

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

## Sort block

    $pdb->{sort}

This is a scalar, the raw data of the sort block.

## Records

$record = $pdb->{records}[N];

All records are available in an array use `Dumper()` to investigate the record structure
		
print Dumper(\$record);

Labels for phone, IM as well as address are automatically converted in the PDB.
The presented labels in $record is therefore the text label and not the actual integer that
is records in the PDB.

## METHODS

### new

`$pdb = new Palm::Contacts;`

Create a new PDB, initialized with the various Palm::Address fields
and an empty record list.

Use this method if you're creating an Address PDB from scratch.

### new_Record

`$record = $pdb->new_Record;`

Creates a new Address record, with blank values for all of the fields.
The AppInfo block will contain only an "Unfiled" category, with ID 0.

`new_Record` does **not** add the new record to `$pdb`. For that,
you want `append_Record`.

## SEE ALSO

`Palm::PDB`

`Palm::StdAppInfo`

## CONFIGURATION AND ENVIRONMENT

Palm::Address requires no configuration files or environment variables.

## INCOMPATIBILITIES

None reported.

## BUGS AND LIMITATIONS

Module doesn't support setting everything in the Contacts DB. It also doesn't handle Photos

## AUTHORS

Andrew Arensburger arensb AT ooblick.com

Currently maintained by Christopher J. Madsen perl AT cjmweb.net

Contacts DB support contributed by Ben K.

You can follow or contribute to p5-Palm's development at
[https://github.com/madsen/p5-Palm].

## COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Andrew Arensburger & Alessandro Zummo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

## DISCLAIMER OF WARRANTY

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
