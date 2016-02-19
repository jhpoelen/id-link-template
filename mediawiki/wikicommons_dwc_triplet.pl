#!/usr/bin/perl -w

use v5.010;
use strict;
use warnings;

# CONFIGURATION
our $BASE_URL = 'http://commons.wikimedia.org/w/index.php';
our $API_URL = 'http://commons.wikimedia.org/w/api.php';
our $SETS_OF_50 = 10_000;

# Step 1. Identify keywords.
use Getopt::Long;
my $offset = 0;
GetOptions(
    'offset=i' => \$offset   
) or die("Error in command line arguments");

# Anything that's left must be keywords!
my $query = join(' ', @ARGV);

say STDERR "Searching $API_URL for '$query'";

# Step 2. Search the mediawiki instance we want.
use MediaWiki::API;
my $mw = MediaWiki::API->new({
    api_url => $API_URL,
    retries => $SETS_OF_50   
});

my $count_results = 0;
my $count_matches = 0;

$mw->list({
    action => 'query',
    list => 'search',
    srsearch => $query,
    srnamespace => '0|6',
    srwhat => 'text',
    srlimit => 50
}, {
    max => $SETS_OF_50, # Real max = max (200) * srlimit (50)   
    hook => sub {
        my ($results) = @_;
        my @results = @{$results};
        my $result_count = scalar @results;
            
        say STDERR "Extracted $count_matches matches from $count_results processed articles and files.";
        $count_results += $result_count;

        if($count_results < $offset) {
            return;
        }

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
            if(defined($content) and ($content ne '')) {
                my @matches = ($content =~ /\b([A-Z]{3,8}[\:\s](?:[A-Za-z]+[\:\s])?[0-9\.]+\.?)\b/);

                foreach my $match (@matches) {
                    say "$page_url,refers,$match";
                    $count_matches++;
                }
            }
        }
    }
}) or die $mw->{error}->{code} . ': ' . $mw->{error}->{details};

say STDERR "Extracted $count_matches matches from $count_results processed rows.";
