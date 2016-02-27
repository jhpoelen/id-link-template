Notes related to Phoibos2 Identifier Workshop and identifier impact experiments.

# Context
At the Phoibos2 identifier workshop Feb 2016, we explored the feasibility of coming up with a method to identify well-used identifiers for purposes of studying how specific identifiers are used in the wild. The project was called the "counting" group.

In a group discussion, we decided to focus on specimen related identifiers and transcribed links between identifiers in a three column table format to describe an identifier link (start_id, end_id) and how they are related (link_rel). Then, we broke up into separate group to work through some examples manually and record the result in github repositories. Roughly three data garthering techniques were used (1) manual data entry of identifier links using websites and search engines (2) semi-automated retrieval of data through web apis using scripts and (3) extraction of identifiers from published file archives like idigbio darwin core archive and gbif occurrence archive. 

The results of the methods (1) and (2) were recorded in github reposities such as https://github.com/jhpoelen/id-link-template , https://github.com/rybesh/id-link-template , https://github.com/nsjuty/id-link-template , https://github.com/diatomsRcool/id-link-template, https://github.com/gaurav/id-link-template and https://github.com/KatjaSchulz/id-link-template .

These note a focused on method (3) and prototyping method to aggregate and rank massive amounts of identifiers using openly available software.

After some initial work at the workshop, some features to an existing repository at https://github.com/idigbio-hackathon/idigbio-spark that contains special computer programs called Spark Jobs. These jobs are using Apache Spark to process data using a programming interface that allows for distributed computing. The following features were introduced or improved (a) the ability to read Darwin Core archives by using the meta.xml to find data archives and link the column names to the appropriate terms (b) transform data archive into three column results that describe how a specific record id (```start_id```) points to (or refers to ```link_rel```) a specific "external" id or name (```end_id```) and (c) calculate the PageRank for each identifier and order them in decreasing page rank order.

## Technologies used
Scala 2.10, Apache Spark v1.6.0 (including Spark SQL and GraphX) running in a single node Apache Mesos v0.26.0 cluster hosted by iDigBio, specially developed Spark Jobs available at https://https://github.com/idigbio-api-hackathon/idigbio-spark. 

## Data Acquisition Methods
1. manually curated id_links.csv files as published in various github archives forked from https://github.com/jhpoelen/id-link-template 
2. data retrieved from wikidata/media using a publicly available api. See https://github.com/jhpoelen/id-link-template/tree/master/mediawiki for more information
3. iDigBio darwin core archive from June 2015, and parts of a 2015 GBIF archive including all records without any known geospatial issues.

## Results
Manual data extraction resulted in less than about a hundred links between ids as gathered over some hours in a group of about 10 people. Scripts were developed to retrieve relevant data from wikidata, resulting in over a thousand links between relevant specimen identifier in the course of the workshop. 
Handling the large (or huge) >>GB archives (data acquisition method 3) associated with the full data dumps / archives took some more time and resulted in new features being added to iDigBio Spark during and up to a week after the workshop. New features included: loading occurrence data and associated column terms using meta.xml, transformation of a wide table (darwin core occurrence table) into a three column identifier link table same to those used in the other data extraction methods.

Now that the identifier links datasets where obtained, a second Spark program was implemented to allow for calculating PageRank values for every linked identifier for a given link table. An existing implementation for PageRank in GraphX, a spark library, was used to do the heavy lifting, and some code was written to prepare the linked identifiers for usage by the existing PageRank algorithm. PageRank is one of the core algorithm used to order Google search results and has its roots in calculating citation index for scientists and their papers. See http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0134794 for a recent paper that discusses the benefits of using PageRank to calculate scientific impact.

So, the data processing workflow was: 

1. Discover identifiers links (manually/automatically)

2. Record identifier links in three column table (csv file)

3. Feed all the identifiers and their relationships in the the PageRank algorithm

4. Order identifiers by decreasing page rank and show the top 1000 identifiers

To try the PageRank algorithm and test the scalability of the chosen technologies (Apache Spark/GraphX), three datasets were compiled and processed. The results are shown in the following table.

dataset | #links | file size | processing time | top 1000 identifiers | description 
--- | --- | --- | --- | --- | ---
small | 2311 | ~200K | <1min | [id rank small](rank_ids_small.csv) | consisted of manually and semi-automatically constructed identifier links
medium | ~500k | ~50M | <1min | [id rank medium](rank_ids_medium.csv) | small dataset (see above) + first 100k lines from both idigbio and gbif occurrences
large | ~50M | 2.7G | ~90min | [id rank large](rank_ids_large.csv) | 15M idigbio occurrence records 

Note that for the automated extraction of links from the gbif and idigbio darwin core archives, the following terms were included: 

```
"http://purl.org/dc/terms/bibliographicCitation"
"http://rs.tdwg.org/dwc/terms/identificationReferences"
"http://rs.tdwg.org/dwc/terms/ownerInstitutionCode"
"http://rs.tdwg.org/dwc/terms/collectionCode"
"http://rs.tdwg.org/dwc/terms/occurrenceID"
"http://rs.tdwg.org/dwc/terms/associatedMedia"
"http://rs.tdwg.org/dwc/terms/catalogNumber"
"http://rs.tdwg.org/dwc/terms/identificationReferences"
"http://rs.tdwg.org/dwc/terms/associatedSequences"
"http://rs.tdwg.org/dwc/terms/associatedOccurrences"
"http://rs.tdwg.org/dwc/terms/scientificNameID"
"http://rs.tdwg.org/dwc/terms/namePublishedIn"
"http://rs.tdwg.org/dwc/terms/relatedResourceID"
```

top 10 
## small dataset (phoibos2 manual/semi-auto)
page rank | identifier
--- | ---
7.6 | PZSL 1848
6.7 | EOLID:11119143
5.5 | AMNH specimen 5116
5.3 | AMNH specimen 5027
3.3 | EOLID:39513
2.1 | EOLID:2312
1.9 | AMNH 460
1.9 | EOLID:15503955
1.9 | EOLID:4752261
1.8 | EOLID:25467


## medium dataset (phoibos2 manual/semi-auto + idigbio/gbif 100k)
page rank | identifier
--- | ---
292 | "Museum of Comparative Zoology, Harvard University"
258 | SEMC
140 | Invertebrate Zoology
108 | ANTWEB
97 | IZ
88 | KUH
78 | Harvard University
75 | Herps
73 | BOT
70 | HERP


## big dataset (idigbio full)
page rank | identifier 
--- | --- 
43755 | "Museum of Comparative Zoology, Harvard University"
38889 | SEMC
22989 | Invertebrate Zoology
16194 | ANTWEB
14481 | IZ
14193 | KUH
11960 | Harvard University
11892 | Herps
11363 | KANU
11089 | Birds

# Conclusion/discussion

These experiments seems to indicate that an easy to understand three column representation of identifier relationships can facilitate the access to manually and automatically acquired identifier link datasets. Also, the technology chosen (Apache Spark/GraphX) seems to be able to process large datasets without. Also, the technology is designed such that processing capacity can be increased by adding hardware without the need to rewrite the processing software (e.g. "spark jobs"). 

Not much time has been spent on analyzing the results, but at first glance, the small dataset brings PZCL 1848 (Proceedings for Zoological Society London 1848?) and two dinosaur specimen (AMNH specimen 5116, AMNH specimen 5027) in the spotlight. Unlike the three identifiers mentioned, the ids with prefix EOLID could not be found in free form Google searches. The larger datasets seem to favor institutions, which is unsuprising, because many specimen are contained in a collection and even more are associated with institutions.

More data experiments are needed using a more varied range of datasets (e.g. all of gbif, genbank) to come up with a suitable measure for capturing the impact of a specific identifier, but these results seems to suggest that the choice of technologies and data representation are suitable for this kind of data-heavy exercize. 






