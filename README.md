# couchbase-moxi
Connecting to a local couchbase container via MOXI

# Usage

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
