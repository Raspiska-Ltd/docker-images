# Jenkins CI/CD for Raspiska Tech

This Docker setup provides a complete CI/CD solution for Raspiska Tech infrastructure using Jenkins.

## Features

- **Jenkins LTS**: Latest Long-Term Support version with JDK 17
- **Jenkins Agent**: Dedicated agent for running build jobs
- **Configuration as Code**: Automated setup using Jenkins Configuration as Code (JCasC)
- **Pipeline as Code**: Infrastructure as Code approach with Jenkinsfile
- **Docker Integration**: Full Docker support for building and testing containers
- **Traefik Integration**: Automatic routing through Traefik reverse proxy
- **Kong Integration**: API Gateway integration for centralized access
- **Security**: Pre-configured security settings and credentials management

## Quick Start

1. Run the setup script to start Jenkins:

   ```bash
   ./setup.sh
   ```

2. Add the following entry to your `/etc/hosts` file:

   ```bash
   sudo sh -c 'echo "127.0.0.1 jenkins.raspiska.local" >> /etc/hosts'
   ```

3. Access Jenkins at:
   - Direct: [http://localhost:8181/jenkins](http://localhost:8181/jenkins)
   - Traefik: [http://jenkins.raspiska.local/jenkins](http://jenkins.raspiska.local/jenkins)
   - Kong: [http://kong.raspiska.local/jenkins](http://kong.raspiska.local/jenkins)

4. Log in with the credentials specified in the `.env` file:
   - Username: admin
   - Password: secure_jenkins_password

## Architecture

This Jenkins setup includes:

- **Jenkins Master**: Main Jenkins server (port 8080)
- **Jenkins Agent**: Worker node for executing jobs
- **Configuration as Code**: Automated setup using JCasC
- **Pipeline as Code**: Sample Jenkinsfile for CI/CD pipelines

## CI/CD Pipelines

The setup includes sample CI/CD pipelines for Raspiska Tech infrastructure:

1. **Infrastructure Pipeline**: Builds and deploys all infrastructure components
2. **Deploy All**: One-click deployment of the entire infrastructure

## Customizing Pipelines

To customize the CI/CD pipelines:

1. Edit the `Jenkinsfile` in this directory
2. Update the Jenkins Configuration as Code file in `casc/jenkins.yaml`
3. Add or modify initialization scripts in `init.groovy.d/`

## Adding New Pipelines

To add a new pipeline:

1. Create a new Jenkinsfile in your repository
2. Add a new pipeline job in Jenkins:
   - Go to Jenkins > New Item
   - Select "Pipeline"
   - Configure the pipeline to use your Jenkinsfile

## Integrating with GitHub

To integrate with GitHub:

1. Update the GitHub credentials in the Jenkins Configuration as Code file
2. Configure webhooks in your GitHub repository to trigger builds:
   - Payload URL: [http://jenkins.raspiska.local/jenkins/github-webhook/](http://jenkins.raspiska.local/jenkins/github-webhook/)
   - Content type: application/json
   - Events: Push, Pull Request, etc.

## Security Considerations

- In production, secure Jenkins with HTTPS
- Use strong passwords for admin accounts
- Implement proper authentication and authorization
- Regularly update Jenkins and plugins to the latest versions
- Use credential binding for sensitive information

## Troubleshooting

### Jenkins Not Starting

1. Check the container logs:

   ```bash
   docker logs raspiska_jenkins
   ```

2. Verify the container is running:

   ```bash
   docker ps | grep jenkins
   ```

3. Check if port 8080 is already in use:

   ```bash
   lsof -i :8080
   ```

### Agent Not Connecting

1. Check the agent logs:

   ```bash
   docker logs raspiska_jenkins_agent
   ```

2. Verify the agent secret in the `.env` file
3. Restart the agent container:

   ```bash
   docker restart raspiska_jenkins_agent
   ```

### Pipeline Failures

1. Check the pipeline logs in Jenkins
2. Verify that the Jenkinsfile is valid
3. Ensure that the agent has the necessary permissions
4. Check if the required tools are installed on the agent

## Upgrading

1. Update the images in `docker-compose.yml`
2. Back up your Jenkins configuration
3. Run `docker-compose down && docker-compose up -d`
4. Verify the upgrade was successful
