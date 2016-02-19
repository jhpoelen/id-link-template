#!/usr/bin/perl -w

use v5.010;
use strict;
use warnings;

# CONFIGURATION
our $BASE_URL = 'http://commons.wikimedia.org/w/index.php';
our $API_URL = 'http://commons.wikimedia.org/w/api.php';

# Step 1. Identify keywords.
use Getopt::Long;
GetOptions() or die("Error in command line arguments");

# Anything that's left must be keywords!
my $query = join(' ', @ARGV);

say STDERR "Searching $API_URL for '$query'";

# Step 2. Search the mediawiki instance we want.
use MediaWiki::API;
my $mw = MediaWiki::API->new();
$mw->{config}->{api_url} = $API_URL;

$mw->list({
    action => 'query',
    list => 'search',
    srsearch => $query,
    srnamespace => '0|6',
    srwhat => 'text',
    srlimit => 50
}, {
    max => 200, # Real max = max (200) * srlimit (50)   
    hook => sub {
        my ($results) = @_;
        my @results = @{$results};
            
        say STDERR "Retrieved $#results results.";

        foreach my $res (@results) {
            my $title = $res->{'title'};
            my $page = $mw->get_page({
                title => $title
            });

            my $page_id = $page->{'pageid'};
            my $rev_id = $page->{'revid'};
            my $page_title = $page->{'title'};
            my $content = $page->{'*'};

            use URI::URL;
            my $page_url = URI::URL->new($BASE_URL);
            $page_url->query_form({
                # title => $page_title,
                oldid => $rev_id
            });

            # TODO: Parse $content to plain text so templated can't interrupt DwC-triples.
            
            # DwC Triplet regex based on http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0114069
            my @matches = ($content =~ /([A-Z]{3,8}[\:\s](?:[A-Z][a-z]+[\:\s])?[0-9\.]+)/);

            foreach my $match (@matches) {

                say "$page_url,refers,$match";
            }
        }
    }
}) or die $mw->{error}->{code} . ': ' . $mw->{error}->{details};
