# id-link-template

Fork of the template repo for phoibos2 workshop: this one contains several
records that participants found and recorded in our Google Doc.

fork this repo and edit the `id_links.csv` file and add your links.

This repository takes an inaturalist observations of a Sea otter (_Enhydra lutris_) and how it is used in GBIF, GloBI and GBIF and GloBI link this to taxon "ids" and other linked resources.

## counting 

To calculate the relative importance or connectiveness of an id, we create a list of id relationships in the form of:

sourceId,rel,destinationId

where the sourceId and destinationId are the vertices and the row itself respresents the a single directed vertex from sourceId to destinationId. The relationship of a source to the destination that of a paper and a citation. 

In order to study the impact of an id, we start with two metrics: the sum of the length of incoming vertices and all paths related to each and every vertex with incoming edges. 

## Data acquisition
### manual 
11 experts gathered and constructed vertices and edges related to specimen collections and their usage. The result was a three table columns with the source id, destination id and the type of relationship. 

### automated
Using Apache Spark, GBIF (~400M) and iDigBio (~4M) occurrence archives acquired. Edges between coreIds (GBIF/iDigBio records ids) source vertices and destination vertices (occurrenceID, catalog number, associatedSequences, references, institution code) were constructed and collected in a three table column with a source id (core id), destination id and type of relationship.

## Analysis
Using Apache's GraphX, the three columns table was ingested using:

```
import org.apache.spark._
import org.apache.spark.graphx._
// To make some of the examples work we will also need RDD
import org.apache.spark.rdd.RDD

// combine the source/destination ids and make a list of unique ids

// assign an id to each id to create an vertex list

// map id to source/destination ids to create a edge list

val ids: RDD[(VertexId, String)] =
  sc.parallelize(Array((1L, "YU.051351"),(3L, "idigbio:123"), (5L, "gbif:4432"), (7L, "genbank:123"), (8L, "eol:333")))

// Create an RDD for edges
val links: RDD[Edge[String]] =
  sc.parallelize(Array(Edge(3L, 7L, "relatesTo")
  , Edge(5L, 7L, "relatesTo"), Edge(3L,1L, "relatesTo"), Edge(5L, 1L, "relatesTo"), Edge(8L,3L,"relatesTo"), Edge(8L,5L, "relatesTo")))

val defaultLink = "no:link"

val graph = Graph(ids, links, defaultLink)

// filter vertices
graph.vertices.filter { case (id, idString) => idString.startsWith("idigbio") }.count



val idLinks: RDD[String] = graph.triplets.map(triplet => triplet.srcAttr + " is the " + triplet.attr + " of " + triplet.dstAttr)
idLinks.collect.foreach(println(_))

val countedLinks: VertexRDD[(String, Int)] = graph.aggregateMessages[(String, Int)](
  triplet => { triplet.sendToDest(triplet.srcAttr, 1) }, (a, b) => (List(a._1, b._1).mkString(" | "), a._2 + b._2)) 

// prints all ids and incoming counts
  countedLinks.collect().foreach(println(_))

graph.aggregateMessages[Int] 



graph.vertices.foreach(println(_))

val graph = GraphLoader.edgeListFile(sc, "/home/int/data/ids/*link_ids.txt")
// for each vertex, count the connected edges, recursively.

```



