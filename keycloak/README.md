# Keycloak Identity and Access Management for Raspiska Tech

This Docker setup provides a complete Keycloak identity and access management solution for Raspiska Tech services. Keycloak is an open-source identity and access management solution that provides single sign-on (SSO), identity federation, social login, and more.

## Features

- **Keycloak Server**: Complete identity and access management solution
- **PostgreSQL Database**: Persistent storage for Keycloak configuration and user data
- **Traefik Integration**: Automatic routing through Traefik reverse proxy
- **Kong Integration**: API Gateway integration for centralized authentication
- **Connectivity**: Pre-configured to connect with other Raspiska Tech services

## Quick Start

1. Run the setup script to start Keycloak:

   ```bash
   ./setup.sh
   ```

2. Add the following entries to your `/etc/hosts` file:

   ```text
   127.0.0.1 keycloak.raspiska.local
   ```

3. Access the Keycloak Admin Console at:
   - Direct link: [http://localhost:8180/auth/admin/master/console/](http://localhost:8180/auth/admin/master/console/)
   - Standard admin URL: [http://localhost:8180/auth/admin](http://localhost:8180/auth/admin)
   - Via Traefik: [http://keycloak.raspiska.local/auth/admin](http://keycloak.raspiska.local/auth/admin)
4. Log in with the admin credentials specified in the `.env` file (default: admin/secure_admin_password)

## Architecture

This Keycloak setup includes:

- **Keycloak Server**: The main identity server (internal port 8080, external port 8180)
- **PostgreSQL**: Database for storing Keycloak configuration and user data
- **Integration with Traefik**: For routing and load balancing
- **Integration with Kong**: For API Gateway authentication

## Managing Identity with Keycloak

### Creating a New Realm

1. Log in to the Keycloak Admin Console
2. Click on the dropdown in the top-left corner
3. Click "Create Realm"
4. Enter a name for your realm (e.g., "raspiska")
5. Click "Create"

### Creating a New Client

1. Select your realm from the dropdown
2. Go to "Clients" in the left sidebar
3. Click "Create client"
4. Enter a Client ID (e.g., "raspiska-app")
5. Select the client protocol (e.g., "openid-connect")
6. Click "Next" and configure the client settings
7. Click "Save"

### Creating Users

1. Select your realm
2. Go to "Users" in the left sidebar
3. Click "Add user"
4. Fill in the user details
5. Click "Create"
6. Go to the "Credentials" tab
7. Set a password for the user

## Integrating with Raspiska Tech Services

### Connecting to Kong API Gateway

Keycloak can be used with Kong for API authentication:

1. Configure Kong's OpenID Connect plugin:

   ```bash
   curl -X POST http://localhost:8001/services/your-service/plugins \
     --data "name=openid-connect" \
     --data "config.client_id=kong" \
     --data "config.client_secret=your-client-secret" \
     --data "config.discovery=http://keycloak.raspiska.local/auth/realms/raspiska/.well-known/openid-configuration"
   ```

2. Create a client in Keycloak for Kong:
   - Client ID: kong
   - Access Type: confidential
   - Valid Redirect URIs: `http://kong.raspiska.local/*`

### Using with Frontend Applications

For frontend applications, configure your client in Keycloak:

1. Set the appropriate redirect URIs
2. Enable "Standard Flow" (Authorization Code Flow)
3. Use the Keycloak JavaScript adapter in your application:

   ```html
   <script src="http://keycloak.raspiska.local/auth/js/keycloak.js"></script>
   <script>
     const keycloak = new Keycloak({
       url: 'http://keycloak.raspiska.local/auth',
       realm: 'raspiska',
       clientId: 'raspiska-app'
     });
     
     keycloak.init({ onLoad: 'login-required' }).then(authenticated => {
       if (authenticated) {
         console.log('User is authenticated');
       } else {
         console.log('User is not authenticated');
       }
     });
   </script>
   ```

### Using with Backend Services

For backend services, configure your client in Keycloak:

1. Set the Access Type to "confidential"
2. Enable "Service Accounts" flow
3. Use the client credentials to obtain tokens:

   ```bash
   curl -X POST \
     http://keycloak.raspiska.local/auth/realms/raspiska/protocol/openid-connect/token \
     -H 'Content-Type: application/x-www-form-urlencoded' \
     -d 'grant_type=client_credentials&client_id=your-client-id&client_secret=your-client-secret'
   ```

## Common Use Cases

### Single Sign-On (SSO)

Keycloak provides SSO capabilities across all your applications:

1. Configure multiple clients in the same realm
2. Users will be automatically logged in to all applications after logging in once

### Social Login

Enable social login providers:

1. Go to "Identity Providers" in the left sidebar
2. Click "Add provider" and select a social provider (e.g., Google, Facebook)
3. Configure the provider with the appropriate client ID and secret
4. Users can now log in using their social accounts

### Multi-Factor Authentication (MFA)

Enable MFA for your realm:

1. Go to "Authentication" in the left sidebar
2. Select the "Flows" tab
3. Copy the "Browser" flow
4. Add the "OTP Form" to the flow
5. Set the requirement to "Required"
6. Users will now need to set up and use OTP for authentication

## Monitoring and Logs

- **Keycloak Logs**: `docker logs raspiska_keycloak`
- **Database Logs**: `docker logs raspiska_keycloak_db`
- **Metrics**: Keycloak exposes metrics at `/auth/metrics` (when enabled)

## Security Considerations

- In production, secure Keycloak with HTTPS
- Use strong passwords for admin accounts
- Regularly update Keycloak to the latest version
- Configure proper CORS settings for your clients
- Use confidential clients for backend services
- Implement proper token validation in your applications

## Troubleshooting

### Keycloak Not Starting

1. Check database connectivity:

   ```bash
   docker logs raspiska_keycloak
   ```

2. Verify PostgreSQL is running:

   ```bash
   docker logs raspiska_keycloak_db
   ```

### Authentication Issues

1. Check the client configuration in Keycloak
2. Verify the redirect URIs are correctly set
3. Check the client roles and permissions
4. Examine the Keycloak logs for error messages

## Advanced Configuration

### Custom Themes

1. Create a custom theme directory
2. Mount it to the Keycloak container at `/opt/keycloak/themes/custom`
3. Select the custom theme in the realm settings

### LDAP Integration

1. Go to "User Federation" in the left sidebar
2. Select "ldap" from the dropdown
3. Configure the LDAP connection settings
4. Map LDAP attributes to Keycloak attributes

## Upgrading Keycloak

1. Update the version in `docker-compose.yml`
2. Back up your database
3. Run `docker-compose down && docker-compose up -d`
4. Verify the upgrade was successful
