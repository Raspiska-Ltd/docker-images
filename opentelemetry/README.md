# OpenTelemetry for Raspiska Tech

This directory contains the configuration for OpenTelemetry, a distributed tracing and observability framework.

## Features

- **Distributed Tracing**: End-to-end visibility across services
- **Multiple Backends**: Jaeger, Zipkin, and Tempo support
- **Metrics Collection**: Integration with Prometheus
- **Centralized Collection**: OpenTelemetry Collector for data processing
- **Service Graphs**: Visualize service dependencies and interactions

## Architecture

The OpenTelemetry setup consists of:

1. **OpenTelemetry Collector**: The central component that receives, processes, and exports telemetry data
2. **Jaeger**: Full-featured distributed tracing backend with a powerful UI
3. **Zipkin**: Alternative tracing backend with a simpler interface
4. **Tempo**: Grafana's high-scale, cost-effective tracing backend

## Prerequisites

- Docker and Docker Compose
- Traefik reverse proxy (included in Raspiska Tech)
- Prometheus for metrics (included in Raspiska Tech monitoring stack)
- Kong API Gateway (optional, for additional routing)

## Setup

Run the setup script to deploy OpenTelemetry:

```bash
./setup.sh
```

This script will:

1. Check prerequisites
2. Create necessary configurations
3. Configure hosts file entries
4. Set up Traefik routing
5. Configure Kong API Gateway (if available)
6. Update Prometheus configuration (if available)
7. Start the OpenTelemetry containers

## Access

The OpenTelemetry components can be accessed through multiple endpoints:

### Jaeger UI

- Direct: [http://localhost:16686](http://localhost:16686)
- Traefik: [http://jaeger.raspiska.local](http://jaeger.raspiska.local)
- Kong: [http://kong.raspiska.local/jaeger](http://kong.raspiska.local/jaeger)

### Zipkin UI

- Direct: [http://localhost:9412](http://localhost:9412)
- Traefik: [http://zipkin.raspiska.local](http://zipkin.raspiska.local)
- Kong: [http://kong.raspiska.local/zipkin](http://kong.raspiska.local/zipkin)

### Tempo

- Direct: [http://localhost:3200](http://localhost:3200)
- Traefik: [http://tempo.raspiska.local](http://tempo.raspiska.local)
- Kong: [http://kong.raspiska.local/tempo](http://kong.raspiska.local/tempo)

### OpenTelemetry Collector

- Direct: [http://localhost:8888](http://localhost:8888)
- Traefik: [http://otel-collector.raspiska.local](http://otel-collector.raspiska.local)
- Kong: [http://kong.raspiska.local/otel-collector](http://kong.raspiska.local/otel-collector)

## OTLP Endpoints

Applications should send telemetry data to these endpoints:

- gRPC: `localhost:4317`
- HTTP: `localhost:4318`

## Integration with Applications

### Java Application Example

```java
// Add these dependencies to your build file
// implementation 'io.opentelemetry:opentelemetry-api:1.24.0'
// implementation 'io.opentelemetry:opentelemetry-sdk:1.24.0'
// implementation 'io.opentelemetry:opentelemetry-exporter-otlp:1.24.0'
// implementation 'io.opentelemetry:opentelemetry-semconv:1.24.0'

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.exporter.otlp.trace.OtlpGrpcSpanExporter;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor;

public class TracingExample {
    private static OpenTelemetry initOpenTelemetry() {
        OtlpGrpcSpanExporter spanExporter = OtlpGrpcSpanExporter.builder()
            .setEndpoint("http://localhost:4317")
            .build();

        SdkTracerProvider tracerProvider = SdkTracerProvider.builder()
            .addSpanProcessor(BatchSpanProcessor.builder(spanExporter).build())
            .build();

        return OpenTelemetrySdk.builder()
            .setTracerProvider(tracerProvider)
            .buildAndRegisterGlobal();
    }

    public static void main(String[] args) {
        OpenTelemetry openTelemetry = initOpenTelemetry();
        Tracer tracer = openTelemetry.getTracer("com.example.TracingExample");

        Span span = tracer.spanBuilder("Start Example").startSpan();
        try {
            // Your business logic here
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            span.recordException(e);
        } finally {
            span.end();
        }
    }
}
```

### Python Application Example

```python
# pip install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Configure the tracer
resource = Resource(attributes={
    SERVICE_NAME: "python-service"
})

tracer_provider = TracerProvider(resource=resource)
otlp_exporter = OTLPSpanExporter(endpoint="localhost:4317", insecure=True)
span_processor = BatchSpanProcessor(otlp_exporter)
tracer_provider.add_span_processor(span_processor)
trace.set_tracer_provider(tracer_provider)

tracer = trace.get_tracer(__name__)

# Create a span
with tracer.start_as_current_span("example-operation"):
    # Your business logic here
    print("Hello, OpenTelemetry!")
```

### Node.js Application Example

```javascript
// npm install @opentelemetry/api @opentelemetry/sdk-node @opentelemetry/exporter-trace-otlp-proto

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-proto');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const { trace } = require('@opentelemetry/api');

// Configure the SDK
const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'node-service',
  }),
  traceExporter: new OTLPTraceExporter({
    url: 'http://localhost:4317',
  }),
});

// Initialize the SDK
sdk.start();

// Get a tracer
const tracer = trace.getTracer('example-tracer');

// Create a span
const span = tracer.startSpan('example-operation');
// Your business logic here
console.log('Hello, OpenTelemetry!');
span.end();

// Gracefully shut down the SDK
process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('SDK shut down successfully'))
    .catch((error) => console.log('Error shutting down SDK', error))
    .finally(() => process.exit(0));
});
```

## Integration with Existing Infrastructure

### Grafana Dashboard

To view traces in Grafana:

1. Add Tempo as a data source in Grafana:
   - URL: `http://tempo:3200`
   - Type: Tempo

2. Create a new dashboard with trace panels.

### Prometheus Integration

The OpenTelemetry Collector exports metrics to Prometheus at:

```text
http://raspiska_otel_collector:8889/metrics
```

This endpoint is already configured in the Prometheus setup.

## Troubleshooting

### Common Issues

1. **No traces appearing in Jaeger/Zipkin**:
   - Check if your application is correctly configured to send traces
   - Verify the collector is running: `docker ps | grep otel`
   - Check collector logs: `docker logs raspiska_otel_collector`

2. **Connection refused errors**:
   - Ensure the correct ports are exposed and not blocked by firewalls
   - Check if the services are running: `docker ps | grep jaeger`

3. **High latency or dropped spans**:
   - Check the collector's resource usage
   - Adjust batch settings in the collector configuration

### Logs

View logs for troubleshooting:

```bash
# OpenTelemetry Collector logs
docker logs raspiska_otel_collector

# Jaeger logs
docker logs raspiska_jaeger

# Zipkin logs
docker logs raspiska_zipkin

# Tempo logs
docker logs raspiska_tempo
```

## Advanced Configuration

For advanced configuration options, refer to:

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
- [Zipkin Documentation](https://zipkin.io/pages/documentation.html)
- [Tempo Documentation](https://grafana.com/docs/tempo/latest/)
