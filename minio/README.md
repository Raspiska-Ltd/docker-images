# MinIO Object Storage for Raspiska Tech

This directory contains the configuration for MinIO, an S3-compatible object storage solution for the Raspiska Tech infrastructure.

## Features

- **S3-Compatible API**: Store and retrieve any amount of data using the same API as Amazon S3
- **High Performance**: Optimized for high-throughput workloads
- **Data Protection**: Built-in erasure coding and bit-rot protection
- **Security**: Encryption, access control, and audit logging
- **Integration**: Works with all Raspiska Tech services

## Architecture

The MinIO setup consists of:

1. **MinIO Server**: The main object storage service
2. **MinIO Client (mc)**: A command-line tool for interacting with MinIO
3. **Default Buckets**:
   - `backups`: For database and system backups
   - `logs`: For application and system logs
   - `artifacts`: For build artifacts and releases
   - `public`: For publicly accessible files

## Prerequisites

- Docker and Docker Compose
- Traefik reverse proxy (included in Raspiska Tech)
- Kong API Gateway (optional, for additional routing)

## Setup

Run the setup script to deploy MinIO:

```bash
./setup.sh
```

This script will:

1. Check prerequisites
2. Create necessary directories
3. Configure hosts file entries
4. Set up Traefik routing
5. Configure Kong API Gateway (if available)
6. Start the MinIO containers
7. Create default buckets and users

## Access

MinIO can be accessed through multiple endpoints:

### API Endpoints

- Direct: [http://localhost:9000](http://localhost:9000)
- Traefik: [http://minio.raspiska.local](http://minio.raspiska.local)
- Kong: [http://kong.raspiska.local/minio](http://kong.raspiska.local/minio)

### Console Endpoints

- Direct: [http://localhost:9001](http://localhost:9001)
- Traefik: [http://minio-console.raspiska.local](http://minio-console.raspiska.local)
- Kong: [http://kong.raspiska.local/minio-console](http://kong.raspiska.local/minio-console)

## Authentication

Two sets of credentials are configured:

1. **Root Credentials** (for administration):
   - Username: `admin`
   - Password: `secure_minio_password`

2. **Application Credentials** (for services):
   - Username: `app_user`
   - Password: `secure_app_password`

## Integration with Other Services

### PostgreSQL Backups

Add to your PostgreSQL backup script:

```bash
# Backup PostgreSQL database and upload to MinIO
pg_dump -U postgres your_database | gzip > backup.gz
mc cp backup.gz myminio/backups/postgres/$(date +%Y-%m-%d)/
```

### Jenkins Artifacts

In your Jenkinsfile:

```groovy
stage('Archive Artifacts') {
    steps {
        sh '''
        # Upload build artifacts to MinIO
        mc cp target/*.jar myminio/artifacts/${JOB_NAME}/${BUILD_NUMBER}/
        '''
    }
}
```

### Application File Storage

In your application code:

```java
// Java example using AWS SDK
AmazonS3 s3Client = AmazonS3ClientBuilder.standard()
    .withEndpointConfiguration(new AwsClientBuilder.EndpointConfiguration(
        "http://minio.raspiska.local", "us-east-1"))
    .withCredentials(new AWSStaticCredentialsProvider(
        new BasicAWSCredentials("app_user", "secure_app_password")))
    .withPathStyleAccessEnabled(true)
    .build();

// Upload a file
s3Client.putObject("public", "example.txt", new File("/path/to/example.txt"));

// Get a file
S3Object object = s3Client.getObject("public", "example.txt");
```

## Monitoring

MinIO exposes Prometheus-compatible metrics at:

```text
http://minio.raspiska.local/minio/v2/metrics/cluster
```

Add this endpoint to your Prometheus configuration to monitor MinIO.

## Backup and Restore

### Backup MinIO Configuration

```bash
# Backup MinIO configuration
tar -czf minio-config-backup.tar.gz ./config
```

### Restore MinIO Configuration

```bash
# Restore MinIO configuration
tar -xzf minio-config-backup.tar.gz -C /path/to/restore
```

## Troubleshooting

### Common Issues

1. **Cannot connect to MinIO**:
   - Check if containers are running: `docker ps | grep minio`
   - Verify network connectivity: `curl -v http://localhost:9000`

2. **Permission denied errors**:
   - Check user policies: `mc admin policy list myminio`
   - Verify user has appropriate permissions: `mc admin user info myminio app_user`

3. **Bucket not found**:
   - List buckets: `mc ls myminio`
   - Create missing bucket: `mc mb myminio/bucket-name`

### Logs

View MinIO logs:

```bash
docker logs raspiska_minio
```

## Advanced Configuration

For advanced configuration options, refer to the [MinIO Documentation](https://docs.min.io/).
