# couchbase-moxi
Connecting to a local couchbase container via MOXI

# Background
- Couchbase is an open-source, distributed (shared-nothing architecture) multi-model NoSQL document-oriented database software package that is optimized for interactive applications. 
- These applications may serve many concurrent users by creating, storing, retrieving, aggregating, manipulating and presenting data. 
- Couchbase Server is designed to provide easy-to-scale key-value or JSON document access with low latency and high sustained throughput. It is designed to be clustered from a single machine to very large-scale deployments spanning many machines.
- Couchbase Server provided client protocol compatibility with memcached, but added disk persistence, data replication, live cluster reconfiguration, rebalancing and multitenancy with data partitioning. 

## Components
- Cluster manager: The cluster manager supervises the configuration and behavior of all the servers in a Couchbase cluster. It configures and supervises inter-node behavior like managing replication streams and re-balancing operations. It also provides metric aggregation and consensus functions for the cluster, and a RESTful cluster management interface. The cluster manager uses the Erlang programming language and the Open Telecom Platform.

- Replication and fail-over: Data replication within the nodes of a cluster can be controlled with several parameters.

- Data manager: The data manager stores and retrieves documents in response to data operations from applications. It asynchronously writes data to disk after acknowledging to the client, applications can optionally ensure data is written to more than one server or to disk before acknowledging a write to the client. Parameters define item ages that affect when data is persisted, and how max memory and migration from main-memory to disk is handled. It supports working sets greater than a memory quota per "node" or "bucket". External systems can subscribe to filtered data streams, supporting, for example, full text search indexing, data analytics or archiving.

- Data format: A document is the most basic unit of data manipulation in Couchbase Server. Documents are stored in JSON document format with no predefined schemas. Non-JSON documents can also be stored in Couchbase Server (binary, serialized values, XML, etc.)

- Object-managed caches: Couchbase Server includes a built-in multi-threaded object-managed cache that implements memcached compatible APIs such as get, set, delete, append, prepend etc.

- Storage engine: Couchbase Server has a tail-append storage design that is immune to data corruption, OOM killers or sudden loss of power. Data is written to the data file in an append-only manner, which enables Couchbase to do mostly sequential writes for update, and provide an optimized access patterns for disk I/O. 

## Quick couchbase setup:
```
docker run -d --name ce-6.5 -p 8091-8096:8091-8096 -p 11210-11211:11210-11211 couchbase:community-6.5.0
```
> Open the Couchbase WebUI by navigating your web browser to this address: http://localhost:8091
- Configure Couchbase as a minimal single node cluster
- Click the "Configure Disk, Memory, Services" button. Set all the memory quotas to the 256MB minimum
```
IP: 127.0.0.1
Disk: /opt/couchbase/var/lib/couchbase/data
Indexes: /opt/couchbase/var/lib/couchbase/data
Data: 256MB
Query: 256MB
Index: 256MB
Search: 256MB
```
- Click "Buckets" in the left-hand navigation bar, then click the "ADD BUCKET" link in the upper right corner. 
```
Name: default
Memory: 100MB
```
- Create Indexes
```
CREATE PRIMARY INDEX ON default; #make initial queries easy to execute
CREATE INDEX adaptive_default ON default(DISTINCT PAIRS(self)); #support faster filtered queries
```
- Play around with adding data


## Moxi and Couchbase

Information about Moxi can be found [here](https://github.com/couchbase/moxi)

To build the image
```
docker build --rm -t <image-name> -f Dockerfile .

docker build --rm -t moxi -f Dockerfile .
```
Set the IP addresses of the Couchbase servers to a space delimited string as below. To run the image
```
docker run --rm --privileged=true -p <local-port>:<container-port> -d \
-e COUCHBASE_USER=<couchbase_user> \
-e COUCHBASE_PASS=<couchbase_pass> \
-e COUCHBASE_HOSTS="<couchbase_host1 couchbase_host2 couchbase_host3>" \
-e COUCHBASE_BUCKET=<couchbase_bucket> <image-name>
```

Once the moxi container is running, execute the following command which should output statistics about your memcached/couchbase server:

```
echo 'stats proxy' | nc localhost 11211
```

## Testing
> Pre-req : You should have [dgoss](https://github.com/aelsabbahy/goss/tree/master/extras/dgoss) installed on your system to test this. You should also have your moxi-image pre-built.

- Build the Couchbase image
```
docker build -t couchbase -f couchbase-test/Dockerfile .
```

- Create a container
```
docker run -d -p 8091:8091 --name=cbase couchbase
```

- Fetch the IP of the container : cbase
```
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cbase
```

- Create a memcached bucket
```
docker exec -t --user root cbase couchbase-cli bucket-create -c localhost:8091 --bucket=test_moxi --bucket-type=memcached --bucket-password=pass --bucket-ramsize=200 --bucket-eviction-policy=valueOnly --enable-flush=1 -u sgune -p pass
```


- Run Unit Tests 
> (you need [dockerspec](https://github.com/zuazo/dockerspec) installed)
```
rspec unit_test.rb
```

- Run dgoss Test
```
dgoss run --privileged=true -p 11211:11211 -d --name=moxi_container -e COUCHBASE_USER=sgune -e COUCHBASE_PASS=pass -e COUCHBASE_HOSTS="<IP that you fetched>" -e COUCHBASE_BUCKET=test_moxi moxi
```
