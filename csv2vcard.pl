#!/usr/bin/perl -w

# Convert a CSV file from FakeNameGenerator to a vcard
# Output will be UTF-8
#
# Written by Hubert Figuiere <hub@mozilla.com>
# (c) 2013 Mozilla Corporation
#
# This is used for testing FirefoxOS
#
# License is MPL 2.0

use strict;

use File::BOM qw( :all );
use Text::CSV;
use Text::vCard;
use Text::vCard::Addressbook;


my @rows;
my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                 || die "Cannot use CSV: ".Text::CSV->error_diag ();
my $ab = Text::vCard::Addressbook->new();
my $fh;

open_bom($fh, "test.csv", ":utf8")
    || open($fh, "<:encoding(utf8)", "test.csv")
    || die "test.csv: $!";

# Read the fields from the CSV
my $header = $csv->getline($fh);
$csv->column_names($header);

while ( my $row = $csv->getline_hr($fh)) {

    my $vcard = $ab->add_vcard;
### The fields in the CSV export
#
#   GivenName,MiddleInitial,Surname,
#   StreetAddress,City,State,ZipCode,CountryFull,
#   EmailAddress,TelephoneNumber,Birthday,Occupation,
#   Company

    my $node;

    $node = $vcard->add_node({ node_type => 'N' });
    $node->family($row->{'Surname'});
    $node->middle($row->{'MiddleInitial'});
    $node->given($row->{'GivenName'});

    $node = $vcard->add_node({ node_type => 'ORG' });
    $node->name($row->{'Company'});

    $node = $vcard->add_node({ node_type => 'ADR' });
    $node->street($row->{'StreetAddress'});
    $node->city($row->{'City'});
    $node->post_code($row->{'ZipCode'});
    $node->region($row->{'State'});
    $node->country($row->{'CountryFull'});

    $node = $vcard->add_node({ node_type => 'TEL' });
    $node->add_types('type=HOME');
    $node->value($row->{'TelephoneNumber'});

    if ( defined $row->{'Birthday'} ) {
        # birthday date is mm/dd/yyyy in the CSV - need conversion
        my ($m, $d, $y) = split('/', $row->{'Birthday'});
        $vcard->bday(sprintf("%04d%02d%02d", $y,$m,$d));
    }
    $vcard->email($row->{'EmailAddress'});
    $vcard->title($row->{'Occupation'});

}
$csv->eof || $csv->error_diag();
close $fh;

# Output the VCF in utf8
open my $out, ">:encoding(utf8)", "address.vcf"
    || die "Couldn't write address.vcf";;
print $out $ab->export;
close $out;

