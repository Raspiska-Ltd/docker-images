import jenkins.model.*
import hudson.security.*
import jenkins.install.*
import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import org.jenkinsci.plugins.plaincredentials.impl.*
import hudson.plugins.sshslaves.*
import hudson.model.Node.Mode
import hudson.slaves.*

// Skip setup wizard
def instance = Jenkins.getInstance()
instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)

// Set system message
instance.setSystemMessage('Raspiska Tech CI/CD Server')

// Set up admin user if not already set up
def adminUsername = System.getenv('JENKINS_ADMIN_ID') ?: 'admin'
def adminPassword = System.getenv('JENKINS_ADMIN_PASSWORD') ?: 'admin'

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
if (hudsonRealm.getAllUsers().find { it.id == adminUsername } == null) {
    hudsonRealm.createAccount(adminUsername, adminPassword)
    instance.setSecurityRealm(hudsonRealm)
    
    def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
    strategy.setAllowAnonymousRead(false)
    instance.setAuthorizationStrategy(strategy)
    
    instance.save()
    println "Admin user '${adminUsername}' created"
} else {
    println "Admin user '${adminUsername}' already exists"
}

// Set up agent
def agentName = "docker-agent"
def agentSecret = System.getenv('JENKINS_AGENT_SECRET') ?: 'secret'
def agentHome = "/home/jenkins/agent"

// Check if agent already exists
def agents = instance.getNodes()
def agentExists = agents.find { it.getNodeName() == agentName }

if (!agentExists) {
    println "Creating agent '${agentName}'"
    
    def launcher = new JNLPLauncher(true)
    def agentNode = new DumbSlave(
        agentName,
        agentHome,
        launcher
    )
    
    agentNode.setNumExecutors(2)
    agentNode.setMode(Mode.NORMAL)
    agentNode.setLabelString("docker linux")
    agentNode.setRetentionStrategy(new RetentionStrategy.Always())
    
    instance.addNode(agentNode)
    
    println "Agent '${agentName}' created"
} else {
    println "Agent '${agentName}' already exists"
}

// Save configuration
instance.save()
println "Jenkins initialized successfully"
